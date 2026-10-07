//
//  AdditionalKYCFlowCoordinator.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/28/26.
//

@_spi(STP) import StripeCore
@_spi(STP) @_spi(CryptoOnrampAlpha) import StripePaymentSheet
import SwiftUI
import UIKit

/// Routes additional KYC requirements and presents supported document collection flows.
@MainActor
final class AdditionalKYCFlowCoordinator: NSObject, UIAdaptivePresentationControllerDelegate {

    /// The collection action selected from the latest requirements response.
    private enum Route {

        /// The customer has no outstanding additional KYC requirements.
        case notRequired

        /// Existing requirements are awaiting Stripe or partner review.
        case pendingVerification

        /// The customer must supply documents and any accompanying questionnaire answers.
        case collect(Collection)
    }

    private enum RequirementKey: String {
        case proofOfAddress = "proof_of_address"
        case sourceOfFunds = "source_of_funds"
    }

    private struct Collection {
        let key: RequirementKey
        let requirement: AdditionalKYCRequirement
        let configuration: DocumentCollectionConfiguration
        let questionnaire: AdditionalKYCQuestionnaireModel?

        var introduction: MessageView.Configuration {
            switch key {
            case .proofOfAddress:
                return .proofOfAddress
            case .sourceOfFunds:
                return .sourceOfFunds
            }
        }

        var confirmation: MessageView.Configuration {
            switch key {
            case .proofOfAddress:
                return .documentUploaded
            case .sourceOfFunds:
                return .submitted
            }
        }
    }

    private let apiClient: STPAPIClient
    private let linkAccountInfo: PaymentSheetLinkAccountInfoProtocol
    private let appearance: LinkAppearance
    private var navigationController: UINavigationController?
    private var continuation: CheckedContinuation<FulfillKYCRequirementResult, Error>?
    private var didSubmit = false
    private var isSubmitting = false
    private var fulfillmentTask: Task<Void, Error>?
    private var sourceOfFundsModel: SourceOfFundsModel?

    /// Creates a flow using the Link account and appearance supplied by the coordinator.
    /// - Parameters:
    ///   - apiClient: The client used to retrieve and fulfill requirements.
    ///   - linkAccountInfo: The authenticated Link account used for requests and document uploads.
    ///   - appearance: The styling applied to the presented collection flow.
    init(apiClient: STPAPIClient, linkAccountInfo: PaymentSheetLinkAccountInfoProtocol, appearance: LinkAppearance) {
        self.apiClient = apiClient
        self.linkAccountInfo = linkAccountInfo
        self.appearance = appearance
    }

    /// Selects a supported action from the latest additional KYC requirements.
    /// - Parameter response: The requirements returned by the backend.
    /// - Returns: The collection action to perform.
    /// Throws when a user-actionable requirement cannot be collected by this flow.
    private func route(_ response: RetrieveKYCRequirementsResponse) throws -> Route {
        let requirements = response.requirements
        guard !requirements.isEmpty else { return .notRequired }

        for key in [RequirementKey.proofOfAddress, .sourceOfFunds] {
            guard let requirement = requirements[key.rawValue], requirement.awaitingActionFrom == .user else {
                continue
            }

            guard let document = requirement.document else {
                throw DocumentCollectionError.unsupportedRequirement
            }

            let configuration: DocumentCollectionConfiguration
            switch key {
            case .proofOfAddress:
                configuration = try .init(proofOfAddress: document)
            case .sourceOfFunds:
                configuration = try .init(document: document)
            }

            let questionnaire = try requirement.additionalRequirements?.questionnaire.map {
                try AdditionalKYCQuestionnaireModel(questionnaire: $0)
            }

            return .collect(.init(key: key, requirement: requirement, configuration: configuration, questionnaire: questionnaire))
        }

        if requirements.values.allSatisfy({ $0.awaitingActionFrom == .partner || $0.awaitingActionFrom == .stripe }) {
            return .pendingVerification
        } else {
            throw DocumentCollectionError.unsupportedRequirement
        }
    }

    /// Retrieves fresh requirements and presents document collection when needed.
    /// - Parameter presentingViewController: The visible view controller that presents the flow.
    /// - Returns: Whether the requirement was submitted, is pending review, was canceled, or is no longer required.
    /// Throws if requirements cannot be loaded, the requirement is unsupported, or collection cannot be presented.
    func present(from presentingViewController: UIViewController) async throws -> FulfillKYCRequirementResult {
        let response = try await apiClient.retrieveKYCRequirements(linkAccountInfo: linkAccountInfo)
        try Task.checkCancellation()

        switch try route(response) {
        case .notRequired:
            return .notRequired
        case .pendingVerification:
            return .pendingVerification
        case .collect(let collection):
            guard presentingViewController.viewIfLoaded?.window != nil,
                  presentingViewController.presentedViewController == nil else {
                throw DocumentCollectionError.invalidPresenter
            }

            guard let key = linkAccountInfo.linkSessionKey, !key.isEmpty else {
                throw DocumentCollectionError.missingLinkSessionKey
            }

            return try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { continuation in
                    self.continuation = continuation

                    if Task.isCancelled {
                        finish(.failure(CancellationError()))
                        return
                    }

                    presentCollection(
                        collection,
                        linkSessionKey: key,
                        from: presentingViewController
                    )
                }
            } onCancel: {
                Task { @MainActor in
                    self.finish(self.didSubmit ? .success(.submitted) : .failure(CancellationError()))
                }
            }
        }
    }

    private func presentCollection(
        _ collection: Collection,
        linkSessionKey: String,
        from presentingViewController: UIViewController
    ) {
        let navigationController = UINavigationController()
        navigationController.modalPresentationStyle = .pageSheet
        navigationController.sheetPresentationController?.prefersGrabberVisible = true
        navigationController.presentationController?.delegate = self
        appearance.applyInterfaceStyle(to: navigationController)

        let hostingController = UIHostingController(rootView: MessageView(
            configuration: collection.introduction,
            appearance: appearance,
            onPrimaryAction: { [weak self, weak navigationController] in
                guard let self, let navigationController else { return }

                if let questionnaire = collection.questionnaire, !questionnaire.questions.isEmpty {
                    let questionnaireView = AdditionalKYCQuestionnaireView(
                        heading: collection.introduction.heading,
                        appearance: self.appearance,
                        model: questionnaire,
                        onContinue: { [weak self, weak navigationController] in
                            guard let self, let navigationController, questionnaire.canContinue else { return }
                            self.showDocuments(for: collection, linkSessionKey: linkSessionKey, in: navigationController)
                        },
                        onClose: { [weak self] in
                            self?.close()
                        }
                    )
                    navigationController.pushViewController(DocumentCollectionViewController(rootView: questionnaireView, appearance: self.appearance), animated: true)
                } else {
                    self.showDocuments(for: collection, linkSessionKey: linkSessionKey, in: navigationController)
                }
            },
            onClose: { [weak self] in
                self?.close()
            }
        ))

        navigationController.setViewControllers([hostingController], animated: false)
        self.navigationController = navigationController
        presentingViewController.present(navigationController, animated: true)
        navigationController.presentationController?.delegate = self
    }

    private func showDocuments(for collection: Collection, linkSessionKey: String, in navigationController: UINavigationController) {
        let uploader = KYCDocumentUploader(apiClient: apiClient, linkSessionKey: linkSessionKey)
        let onSubmit: ([FulfillKYCRequirementsRequest.Document]) async throws -> Void = { [weak self, weak navigationController] documents in
            guard let self, let navigationController else { throw CancellationError() }
            try await self.submit(documents, collection: collection, in: navigationController)
        }

        let onClose: () -> Void = { [weak self] in
            self?.close()
        }

        switch collection.key {
        case .proofOfAddress:
            let controller = ProofOfAddressViewController(
                configuration: collection.configuration,
                appearance: appearance,
                uploader: uploader,
                initialErrorMessage: message(for: collection.requirement.errors),
                onSubmit: { submission in
                    try await onSubmit([.init(documentSubtype: submission.subtypeID, fileIds: [submission.fileID])])
                },
                onClose: onClose
            )
            navigationController.pushViewController(controller, animated: true)
        case .sourceOfFunds:
            let model = sourceOfFundsModel ?? SourceOfFundsModel(configuration: collection.configuration)
            sourceOfFundsModel = model
            let view = SourceOfFundsView(
                appearance: appearance,
                model: model,
                initialErrorMessage: message(for: collection.requirement.errors),
                onEdit: { [weak self, weak navigationController] source in
                    guard let self, let navigationController else { return }
                    self.editSource(source, model: model, uploader: uploader, in: navigationController)
                },
                onSubmit: onSubmit,
                onClose: onClose
            )
            navigationController.pushViewController(DocumentCollectionViewController(rootView: view, appearance: appearance), animated: true)
        }
    }

    private func editSource(_ source: SourceOfFundsModel.Source?, model: SourceOfFundsModel, uploader: DocumentUploading, in navigationController: UINavigationController) {
        guard source != nil || model.canAddSource else { return }
        let uploads = DocumentCollectionModel(
            uploader: uploader,
            uploadedFiles: source?.files ?? [],
            maximumFileCount: model.configuration.maximumFilesPerDocumentType
        )
        let view = SourceOfFundsDocumentView(
            configuration: model.configuration,
            subtypes: model.availableSubtypes(editing: source?.id),
            appearance: appearance,
            collection: uploads,
            selectedSubtype: source?.subtype,
            onSave: { [weak navigationController] subtype, files in
                model.save(subtype: subtype, files: files, replacing: source?.id)
                navigationController?.popViewController(animated: true)
            },
            onClose: { [weak self] in
                self?.close()
            }
        )

        let controller = DocumentCollectionViewController(rootView: view, appearance: appearance, onLeave: {
            uploads.cancel()
        })

        navigationController.pushViewController(controller, animated: true)
    }

    private func submit(_ documents: [FulfillKYCRequirementsRequest.Document], collection: Collection, in navigationController: UINavigationController) async throws {
        guard !isSubmitting, !didSubmit, continuation != nil else { throw CancellationError() }
        guard collection.questionnaire?.canContinue != false else {
            throw DocumentCollectionError.unsupportedRequirement
        }

        isSubmitting = true
        navigationController.isModalInPresentation = true

        defer {
            isSubmitting = false
            navigationController.isModalInPresentation = false
        }

        let requirements: [String: FulfillKYCRequirementsRequest.Requirement] = [
            collection.key.rawValue: .init(
                requestedBy: collection.requirement.requestedBy,
                documents: documents,
                additionalRequirements: collection.questionnaire.map {
                    .init(questionnaire: $0.fulfillment)
                }
            ),
        ]
        let task = Task { [apiClient, linkAccountInfo] in
            _ = try await apiClient.fulfillKYCRequirements(requirements: requirements, linkAccountInfo: linkAccountInfo)
        }
        fulfillmentTask = task
        defer {
            fulfillmentTask = nil
        }
        try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }

        try Task.checkCancellation()

        guard continuation != nil else { throw CancellationError() }

        didSubmit = true

        let hostingController = UIHostingController(rootView: MessageView(
            configuration: collection.confirmation,
            appearance: appearance,
            onPrimaryAction: { [weak self] in
                self?.close()
            },
            onClose: { [weak self] in
                self?.close()
            }
        ))

        // Submission is complete, prevent returning to document collection.
        navigationController.setViewControllers([hostingController], animated: true)
    }

    private func close() {
        guard !isSubmitting || didSubmit else { return }
        finish(.success(didSubmit ? .submitted : .canceled))
    }

    private func message(for errors: [AdditionalKYCRequirement.RequirementError]) -> String? {
        guard !errors.isEmpty else { return nil }
        return .Localized.previousDocumentIssue
    }

    private func finish(_ result: Result<FulfillKYCRequirementResult, Error>) {
        guard let continuation else { return }
        self.continuation = nil
        fulfillmentTask?.cancel()
        let presentedNavigationController = navigationController
        navigationController = nil

        if let presentedNavigationController, presentedNavigationController.presentingViewController != nil {
            presentedNavigationController.dismiss(animated: true) {
                continuation.resume(with: result)
            }
        } else {
            continuation.resume(with: result)
        }
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        close()
    }
}
