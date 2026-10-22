//
//  NetworkedIdentityPresenter.swift
//  StripeIdentity
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePaymentSheet
import UIKit

@MainActor
final class NetworkedIdentityPresenter: NetworkedIdentityCoordinatorDelegate {
    var entry: NetworkedIdentityEntry { coordinator.entry }
    var onEntryChange: (() -> Void)?
    let coordinator: NetworkedIdentityCoordinator
    let includesSelfie: Bool
    private var sheet: NetworkedIdentityFlowViewController?
    private var linkSheet: LinkHostedSheet?
    private weak var presentingViewController: UIViewController?
    private var onOutcome: ((NetworkedIdentityOutcome) -> Void)?
    private var presentsSheet = true

    init(coordinator: NetworkedIdentityCoordinator, includesSelfie: Bool) {
        self.coordinator = coordinator
        self.includesSelfie = includesSelfie
        coordinator.delegate = self
    }

    convenience init?(
        options: IdentityVerificationSheet.Configuration.NetworkedIdentityOptions,
        verificationPage: StripeAPI.VerificationPage,
        identityAPIClient: IdentityAPIClient
    ) {
        let config = NetworkedIdentityConfig.from(page: verificationPage, options: options)
        let merchantPublishableKey = config.merchantPublishableKey ?? ""
        guard config.route != .none, !merchantPublishableKey.isEmpty else { return nil }
        let actions = IdentityAPIClientNetworkedIdentityActions(apiClient: identityAPIClient)
        let networkedIdentityAPIClient = NetworkedIdentityAPIClientImpl(
            apiClient: STPAPIClient(publishableKey: merchantPublishableKey)
        )
        let handoff = options.linkSessionHandoff
        self.init(
            coordinator: NetworkedIdentityCoordinator(
                linkSession: LinkControllerNetworkedIdentityLinkSession(),
                apiClient: config.seedSavedDocuments
                    ? SeededDocumentsNetworkedIdentityAPIClient(delegate: networkedIdentityAPIClient)
                    : networkedIdentityAPIClient,
                actions: actions,
                documentRequirements: NetworkedIdentityDocumentRequirements(verificationPage: verificationPage),
                config: config,
                handoff: handoff
            ),
            includesSelfie: verificationPage.selfie != nil
        )
    }

    /// Records the declined save; the caller submits afterwards either way.
    func declineSave() async {
        await coordinator.declineSave()
    }

    func end() {
        coordinator.abandon()
        onOutcome = nil
        onEntryChange = nil
        dismissSheet()
    }

    func chooseManualCapture(from viewController: UIViewController, onOutcome: @escaping (NetworkedIdentityOutcome) -> Void) {
        begin(from: viewController, onOutcome: onOutcome)
        presentsSheet = false
        coordinator.chooseManualCapture()
    }

    func startReuse(from viewController: UIViewController, onOutcome: @escaping (NetworkedIdentityOutcome) -> Void) {
        begin(from: viewController, onOutcome: onOutcome)
        coordinator.startReuse()
    }

    func startSave(from viewController: UIViewController, onOutcome: @escaping (NetworkedIdentityOutcome) -> Void) {
        begin(from: viewController, onOutcome: onOutcome)
        coordinator.startSave()
    }

    func networkedIdentityCoordinator(
        _ coordinator: NetworkedIdentityCoordinator,
        didTransitionTo state: NetworkedIdentityState
    ) {
        onEntryChange?()
        guard presentsSheet else { return }
        guard state.presentsIdentitySheet else {
            dismissSheet()
            return
        }
        if let sheet {
            sheet.render(state)
            return
        }
        let sheet = NetworkedIdentityFlowViewController(coordinator: coordinator, includesSelfie: includesSelfie)
        self.sheet = sheet
        let linkSheet = LinkHostedSheet(content: sheet, onClose: { [coordinator] in coordinator.cancel() })
        self.linkSheet = linkSheet
        if let presentingViewController {
            linkSheet.present(from: presentingViewController)
        }
    }

    func networkedIdentityCoordinatorDidFinish(with outcome: NetworkedIdentityOutcome) {
        dismissSheet()
        onEntryChange?()
        let onOutcome = onOutcome
        self.onOutcome = nil
        onOutcome?(outcome)
    }

    func networkedIdentityCoordinatorDidChangeRoute() {
        onEntryChange?()
    }

    private func begin(from viewController: UIViewController, onOutcome: @escaping (NetworkedIdentityOutcome) -> Void) {
        presentsSheet = true
        presentingViewController = viewController
        coordinator.linkUIHost = viewController
        self.onOutcome = onOutcome
    }

    private func dismissSheet() {
        sheet = nil
        linkSheet?.dismiss()
        linkSheet = nil
    }
}
