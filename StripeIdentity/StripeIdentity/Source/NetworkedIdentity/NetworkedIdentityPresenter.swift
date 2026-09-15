//
//  NetworkedIdentityPresenter.swift
//  StripeIdentity
//

@_spi(STP) import StripeCore
import UIKit

@MainActor
final class NetworkedIdentityPresenter: NetworkedIdentityCoordinatorDelegate {
    var entry: NetworkedIdentityEntry { coordinator.entry }
    var onEntryChange: (() -> Void)?
    let coordinator: NetworkedIdentityCoordinator
    let includesSelfie: Bool
    private var sheet: NetworkedIdentityFlowViewController?
    private weak var presentingViewController: UIViewController?
    private var onOutcome: ((NetworkedIdentityOutcome) -> Void)?

    var hasPreparedSave: Bool { coordinator.hasPreparedSave }
    private var presentsSheet = true
    private var entryLookup: Task<Void, Never>?

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
        let config = NetworkedIdentityConfig.from(
            page: verificationPage,
            overrides: NetworkedIdentityDebugOverrides(options: options)
        )
        let merchantPublishableKey = config.merchantPublishableKey ?? ""
        guard config.route != .none, !merchantPublishableKey.isEmpty else { return nil }
        let actions = IdentityAPIClientNetworkedIdentityActions(apiClient: identityAPIClient)
        let networkedIdentityAPIClient = NetworkedIdentityAPIClientImpl(
            apiClient: STPAPIClient(publishableKey: merchantPublishableKey),
            merchantPublishableKey: merchantPublishableKey
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

    /// Checks whether the provided email has a Link account, without starting anything.
    func refreshEntry() {
        guard entryLookup == nil else { return }
        entryLookup = Task { [weak self, coordinator] in
            _ = await coordinator.lookUpProvidedAccountEmail()
            guard !Task.isCancelled else { return }
            self?.entryLookup = nil
            self?.onEntryChange?()
        }
    }

    func end() {
        entryLookup?.cancel()
        entryLookup = nil
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
        // With Link's own screens, Identity's sheet only appears once the user is authenticated.
        let hiddenForLinkUI = coordinator.usesLinkUI && state == .preparing
        guard state.presentsIdentitySheet, !hiddenForLinkUI else {
            dismissSheet()
            return
        }
        if let sheet {
            sheet.render(state)
            return
        }
        let sheet = NetworkedIdentityFlowViewController(coordinator: coordinator, includesSelfie: includesSelfie)
        self.sheet = sheet
        let navigationController = UINavigationController(rootViewController: sheet)
        presentingViewController?.present(navigationController, animated: true)
    }

    func networkedIdentityCoordinator(
        _ coordinator: NetworkedIdentityCoordinator,
        didFinishWith outcome: NetworkedIdentityOutcome
    ) {
        dismissSheet()
        onEntryChange?()
        let onOutcome = onOutcome
        self.onOutcome = nil
        onOutcome?(outcome)
    }

    private func begin(from viewController: UIViewController, onOutcome: @escaping (NetworkedIdentityOutcome) -> Void) {
        presentsSheet = true
        presentingViewController = viewController
        coordinator.linkUIHost = viewController
        self.onOutcome = onOutcome
    }

    private func dismissSheet() {
        guard let sheet else {
            return
        }
        self.sheet = nil
        if sheet.navigationController?.presentingViewController != nil {
            sheet.navigationController?.dismiss(animated: true)
        }
    }
}
