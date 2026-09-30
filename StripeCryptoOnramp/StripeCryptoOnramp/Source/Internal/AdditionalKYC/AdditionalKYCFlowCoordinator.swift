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

        /// The customer must submit a proof-of-address document using the supplied configuration.
        case proofOfAddress(AdditionalKYCRequirement, DocumentCollectionConfiguration)
    }

    private enum RequirementKey: String {
        case proofOfAddress = "proof_of_address"
        case sourceOfFunds = "source_of_funds"
    }

    private let apiClient: STPAPIClient
    private let linkAccountInfo: PaymentSheetLinkAccountInfoProtocol
    private let appearance: LinkAppearance
    private var navigationController: UINavigationController?
    private var continuation: CheckedContinuation<FulfillAdditionalKYCRequirementResult, Error>?
    private var didSubmit = false
    private var isSubmitting = false
    private var fulfillmentTask: Task<Void, Error>?

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
        if let requirement = requirements[RequirementKey.proofOfAddress.rawValue], requirement.awaitingActionFrom == .user {
            guard let document = requirement.document else {
                throw DocumentCollectionError.unsupportedRequirement
            }

            return .proofOfAddress(requirement, try DocumentCollectionConfiguration(proofOfAddress: document))
        } else if requirements[RequirementKey.sourceOfFunds.rawValue]?.awaitingActionFrom == .user {
            throw DocumentCollectionError.unsupportedRequirement
        } else if requirements.values.allSatisfy({ $0.awaitingActionFrom == .partner || $0.awaitingActionFrom == .stripe }) {
            return .pendingVerification
        } else {
            throw DocumentCollectionError.unsupportedRequirement
        }
    }

    /// Retrieves fresh requirements and presents document collection when needed.
    /// - Parameter presentingViewController: The visible view controller that presents the flow.
    /// - Returns: Whether the requirement was submitted, is pending review, was canceled, or is no longer required.
    /// Throws if requirements cannot be loaded, the requirement is unsupported, or collection cannot be presented.
    func present(from presentingViewController: UIViewController) async throws -> FulfillAdditionalKYCRequirementResult {
        let response = try await apiClient.retrieveKYCRequirements(linkAccountInfo: linkAccountInfo)
        try Task.checkCancellation()

        switch try route(response) {
        case .notRequired:
            return .notRequired
        case .pendingVerification:
            return .pendingVerification
        case let .proofOfAddress(requirement, configuration):
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

                    presentProofOfAddress(
                        configuration: configuration,
                        requirement: requirement,
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

    private func presentProofOfAddress(
        configuration: DocumentCollectionConfiguration,
        requirement: AdditionalKYCRequirement,
        linkSessionKey: String,
        from presentingViewController: UIViewController
    ) {
        let navigationController = UINavigationController()
        navigationController.modalPresentationStyle = .pageSheet
        navigationController.sheetPresentationController?.prefersGrabberVisible = true
        navigationController.presentationController?.delegate = self
        appearance.applyInterfaceStyle(to: navigationController)

        let hostingController = UIHostingController(rootView: MessageView(
            configuration: .proofOfAddress,
            appearance: appearance,
            onPrimaryAction: { [weak self, weak navigationController] in
                guard let self, let navigationController else { return }

                let collectionViewController = ProofOfAddressViewController(
                    configuration: configuration,
                    appearance: self.appearance,
                    uploader: KYCDocumentUploader(apiClient: self.apiClient, linkSessionKey: linkSessionKey),
                    initialErrorMessage: self.message(for: requirement.errors),
                    onSubmit: { [weak self] submission in
                        guard let self else { throw CancellationError() }
                        try await self.submit(submission, requirement: requirement, in: navigationController)
                    },
                    onClose: { [weak self] in
                        self?.close()
                    }
                )
                navigationController.pushViewController(collectionViewController, animated: true)
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

    private func submit(_ submission: ProofOfAddressView.Submission, requirement: AdditionalKYCRequirement, in navigationController: UINavigationController) async throws {
        guard !isSubmitting, !didSubmit, continuation != nil else { throw CancellationError() }

        isSubmitting = true
        navigationController.isModalInPresentation = true

        defer {
            isSubmitting = false
            navigationController.isModalInPresentation = false
        }

        let request = FulfillKYCRequirementsRequest(requirements: [
            RequirementKey.proofOfAddress.rawValue: .init(
                requestedBy: requirement.requestedBy,
                documents: [.init(documentSubtype: submission.subtypeID, fileIds: [submission.fileID])],
                additionalRequirements: nil
            ),
        ])
        let task = Task { [apiClient, linkAccountInfo] in
            _ = try await apiClient.fulfillKYCRequirements(request, linkAccountInfo: linkAccountInfo)
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
            configuration: .documentUploaded,
            appearance: appearance,
            onPrimaryAction: { [weak self] in
                self?.close()
            },
            onClose: { [weak self] in
                self?.close()
            }
        ))

        navigationController.pushViewController(hostingController, animated: true)
    }

    private func close() {
        guard !isSubmitting || didSubmit else { return }
        finish(.success(didSubmit ? .submitted : .canceled))
    }

    private func message(for errors: [AdditionalKYCRequirement.RequirementError]) -> String? {
        guard !errors.isEmpty else { return nil }
        return .Localized.previousDocumentIssue
    }

    private func finish(_ result: Result<FulfillAdditionalKYCRequirementResult, Error>) {
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
