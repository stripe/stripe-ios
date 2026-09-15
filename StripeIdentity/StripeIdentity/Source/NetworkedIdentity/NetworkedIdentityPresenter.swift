//
//  NetworkedIdentityPresenter.swift
//  StripeIdentity
//

@_spi(STP) import StripeCore
import UIKit

/// What an Identity screen needs to offer Networked Identity. Plain data, so the non-isolated
/// flow controller can build it; screens turn it into a `NetworkedIdentityPresenter`.
struct NetworkedIdentityContext {
    let options: IdentityVerificationSheet.Configuration.NetworkedIdentityOptions
    let verificationPage: StripeAPI.VerificationPage
    /// Makes the Networked Identity actions on this verification session.
    let identityAPIClient: IdentityAPIClient
    /// Whether a saved ID was shared earlier in this verification, so the success screen doesn't offer saving it.
    let hasSharedDocument: Bool
    /// Called when the user shared a saved ID, so document capture can be skipped.
    let didShareDocument: () -> Void
}

/// Runs one Networked Identity attempt at a time from an Identity screen, presenting the Link sheet
/// while the attempt needs it.
@MainActor
final class NetworkedIdentityPresenter: NetworkedIdentityCoordinatorDelegate {
    private(set) var entry: NetworkedIdentityEntry {
        didSet {
            if entry != oldValue {
                onEntryChange?()
            }
        }
    }
    /// Called when `entry` changes, e.g. once the provided email's lookup returns.
    var onEntryChange: (() -> Void)?
    let coordinator: NetworkedIdentityCoordinator
    private let includesSelfie: Bool
    private var sheet: NetworkedIdentityFlowViewController?
    private weak var presentingViewController: UIViewController?
    private var onOutcome: ((NetworkedIdentityOutcome) -> Void)?

    var hasSaved: Bool {
        coordinator.hasSaved
    }

    init(entry: NetworkedIdentityEntry, coordinator: NetworkedIdentityCoordinator, includesSelfie: Bool) {
        self.entry = entry
        self.coordinator = coordinator
        self.includesSelfie = includesSelfie
        coordinator.delegate = self
    }

    convenience init(context: NetworkedIdentityContext) {
        let config = NetworkedIdentityConfig.from(
            page: context.verificationPage,
            overrides: NetworkedIdentityDebugOverrides(options: context.options)
        )
        let actions = IdentityAPIClientNetworkedIdentityActions(apiClient: context.identityAPIClient)
        let merchantPublishableKey = config.merchantPublishableKey ?? ""
        let networkedIdentityAPIClient = NetworkedIdentityAPIClientImpl(
            apiClient: STPAPIClient(publishableKey: merchantPublishableKey),
            merchantPublishableKey: merchantPublishableKey
        )
        let handoff = context.options.linkSessionHandoff
        self.init(
            entry: NetworkedIdentityEntry(config: config, handoff: handoff),
            coordinator: NetworkedIdentityCoordinator(
                linkSession: LinkControllerNetworkedIdentityLinkSession(),
                apiClient: config.seedSavedDocuments
                    ? SeededDocumentsNetworkedIdentityAPIClient(delegate: networkedIdentityAPIClient)
                    : networkedIdentityAPIClient,
                actions: config.seedSavedDocuments
                    ? SeededDocumentsNetworkedIdentityActions(delegate: actions)
                    : actions,
                documentRequirements: NetworkedIdentityDocumentRequirements(verificationPage: context.verificationPage),
                config: config,
                handoff: handoff
            ),
            includesSelfie: context.verificationPage.selfie != nil
        )
    }

    /// Checks whether the provided email has a Link account, without starting anything.
    func refreshEntry() {
        Task { [weak self, coordinator] in
            let found = await coordinator.lookUpProvidedAccountEmail()
            if let found {
                self?.entry.accountEmail = found
            }
        }
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
        guard state.isSheetVisible else {
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
        if outcome == .saved {
            entry.accountEmail = coordinator.accountEmail ?? entry.accountEmail
        }
        let onOutcome = onOutcome
        self.onOutcome = nil
        onOutcome?(outcome)
    }

    private func begin(from viewController: UIViewController, onOutcome: @escaping (NetworkedIdentityOutcome) -> Void) {
        presentingViewController = viewController
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
