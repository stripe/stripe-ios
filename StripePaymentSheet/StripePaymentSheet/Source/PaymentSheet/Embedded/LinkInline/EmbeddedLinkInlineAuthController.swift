//
//  EmbeddedLinkInlineAuthController.swift
//  StripePaymentSheet
//

@_spi(InternalOnlyAPI) import StripeCore
import UIKit

@MainActor
protocol EmbeddedLinkInlineAuthControllerHost: AnyObject {
    /// A view controller that can present right now, or nil if something is already presented.
    func linkInlineAuthPresentingViewController() -> UIViewController?
    func linkInlineAuthWillPresent()
    /// The card should be replaced by the regular Link row.
    func linkInlineAuthDidCollapse()
    /// The customer verified their Link account. `fromCard` is false when they verified after the card closed, e.g. before paying with Link.
    func linkInlineAuthDidVerify(fromCard: Bool)
}

/// Owns a returning Link customer's inline verification in the Embedded Payment Element.
///
/// It outlives the list view, which `update` rebuilds, and gives each new list a card that shows the same attempt. The code is sent
/// the first time the element is on screen, and entered in the card or, when the card can't handle a step, in the Link dialog.
@MainActor
final class EmbeddedLinkInlineAuthController {
    enum ConfirmVerificationResult: Equatable {
        case verified
        case canceled
        /// The dialog can't be shown, so paying with Link verifies the usual way.
        case unavailable
    }

    enum Phase: Equatable {
        /// The card is showing, or would be outside the experiment's control groups.
        case expanded
        /// The customer closed the card. The attempt stays alive so a later Link checkout can reuse the code.
        case collapsed
        /// The attempt ended: verified, switched accounts, failed, or invalidated.
        case finished
    }

    let linkAccount: PaymentSheetLinkAccount
    let coordinator: LinkAuthFlowCoordinator
    /// False in the experiment's control groups, which keep the regular Link row but still log exposure.
    let showsCard: Bool
    private(set) var phase: Phase = .expanded
    weak var host: EmbeddedLinkInlineAuthControllerHost?

    private let experiment: EmbeddedLinkInlineVerificationExperiment?
    private let configuration: EmbeddedPaymentElement.Configuration
    private let linkBrand: LinkBrand
    private let experimentAnalyticsHelper: ExperimentAnalyticsHelper
    private weak var cardView: EmbeddedLinkInlineVerificationView?
    private var dialog: LinkVerificationController?
    private var resendTimer: Timer?
    private var didBecomeVisible = false
    /// Set once a code challenge has started, to tell a failed first send apart from later errors.
    private var didStartCodeChallenge = false
    private var confirmVerificationContinuation: CheckedContinuation<ConfirmVerificationResult, Never>?

    init(
        eligible: EmbeddedLinkInlineVerificationEligibility.Eligible,
        experiment: EmbeddedLinkInlineVerificationExperiment?,
        configuration: EmbeddedPaymentElement.Configuration,
        linkBrand: LinkBrand,
        experimentAnalyticsHelper: ExperimentAnalyticsHelper
    ) {
        self.linkAccount = eligible.linkAccount
        self.coordinator = eligible.coordinator
        self.experiment = experiment
        self.configuration = configuration
        self.linkBrand = linkBrand
        self.experimentAnalyticsHelper = experimentAnalyticsHelper
        self.showsCard = EmbeddedLinkInlineVerificationExperiment.showsInlineVerification(for: experiment)
        coordinator.onUpdate = { [weak self] in self?.coordinatorDidUpdate() }
        coordinator.onFinish = { [weak self] result in self?.coordinatorDidFinish(result) }
        coordinator.onWebHandoff = { [weak self] url in self?.coordinatorDidRequestWebHandoff(url) }
        if showsCard {
            EmbeddedLinkInlineAuthRegistry.claim(self)
        }
    }

    deinit {
        resendTimer?.invalidate()
    }

    var isShowingCard: Bool {
        showsCard && phase == .expanded
    }

    var isPresentingUI: Bool {
        dialog != nil
    }

    /// The account to keep across `update` instead of looking it up again, which would invalidate a code that was sent.
    var accountToPreserveOnUpdate: PaymentSheetLinkAccount? {
        phase == .finished ? nil : linkAccount
    }

    /// Paying with Link after closing the card verifies in the dialog first, reusing any code the card sent.
    var verifiesBeforeConfirming: Bool {
        phase == .collapsed && dialog == nil && linkAccount.sessionState == .requiresVerification
    }

    /// Verifies in the Link dialog before paying with Link.
    func verifyBeforeConfirming() async -> ConfirmVerificationResult {
        guard verifiesBeforeConfirming, confirmVerificationContinuation == nil else { return .unavailable }
        return await withCheckedContinuation { continuation in
            confirmVerificationContinuation = continuation
            if !presentDialog() {
                resumeConfirmVerification(.unavailable)
            }
        }
    }

    /// A new card for a rebuilt list, or nil when the card isn't showing.
    func makeCardView(appearance: PaymentSheet.Appearance) -> EmbeddedLinkInlineVerificationView? {
        guard isShowingCard else { return nil }
        let cardView = EmbeddedLinkInlineVerificationView(appearance: appearance, linkBrand: linkBrand)
        cardView.onTapCode = { [weak self] in self?.presentDialog() }
        cardView.onClose = { [weak self] in self?.dismiss() }
        cardView.onSwitchAccount = { [weak self] in self?.coordinator.cancel(switchAccount: true) }
        cardView.onAction = { [weak self] action in self?.perform(action) }
        cardView.onCodeChanged = { [weak self] in self?.coordinator.codeDidChange() }
        cardView.onCodeEntered = { [weak self] code in self?.coordinator.confirm(code: code) }
        self.cardView = cardView
        render()
        return cardView
    }

    /// Call the first time the element is on screen. Logs the experiment exposure and, unless this is a control group, sends the code.
    func elementBecameVisible() {
        guard !didBecomeVisible, phase != .finished else { return }
        didBecomeVisible = true
        if let experiment {
            experimentAnalyticsHelper.logExposure(experiment: experiment)
        }
        guard isShowingCard else { return }
        Task { await sendFirstCode() }
    }

    /// Ends the attempt without logging a cancellation, e.g. when the Link account changes or Link is no longer shown.
    func invalidate() {
        guard phase != .finished else { return }
        let wasShowingCard = isShowingCard
        finish()
        coordinator.invalidate()
        if let dialog {
            self.dialog = nil
            dialog.detach { _ in }
        }
        resumeConfirmVerification(.canceled)
        if wasShowingCard {
            host?.linkInlineAuthDidCollapse()
        }
    }

    /// Call when `LinkAccountContext` changes. Another surface replacing or logging out the account ends this attempt.
    func linkAccountDidChange(_ account: PaymentSheetLinkAccount?) {
        guard phase != .finished, account !== linkAccount else { return }
        invalidate()
    }

    // MARK: - Customer actions

    private func sendFirstCode() async {
        let apiClient = configuration.apiClient
        if !apiClient.isTestmode {
            // Native Link needs an attested app; without one, verification would fall back to the web.
            guard await apiClient.stripeAttest.prepareAttestation() else {
                invalidate()
                return
            }
        }
        guard isShowingCard, !coordinator.hasStarted else { return }
        EmbeddedLinkInlineAuthRegistry.recordAutoSend(email: linkAccount.email)
        coordinator.analyticsSurface = .embeddedInline
        coordinator.start()
    }

    private func perform(_ action: LinkAuthFlowCoordinator.Action) {
        switch action {
        case .resend:
            coordinator.resend()
        case .email:
            // Email codes can need a phone number match first, which only the dialog shows.
            coordinator.sendToEmail()
            presentDialog()
        }
    }

    private func dismiss() {
        guard isShowingCard else { return }
        EmbeddedLinkInlineAuthRegistry.recordDismissal(email: linkAccount.email)
        phase = .collapsed
        stopResendTimer()
        cardView = nil
        EmbeddedLinkInlineAuthRegistry.release(self)
        host?.linkInlineAuthDidCollapse()
    }

    // MARK: - Dialog

    @discardableResult
    private func presentDialog() -> Bool {
        guard dialog == nil, phase != .finished, let presenter = host?.linkInlineAuthPresentingViewController() else { return false }
        let dialog = LinkVerificationController(
            mode: .inlineLogin,
            sharedCoordinator: coordinator,
            linkAccount: linkAccount,
            brand: linkBrand,
            configuration: configuration
        )
        self.dialog = dialog
        coordinator.analyticsSurface = .embeddedDialog
        host?.linkInlineAuthWillPresent()
        dialog.presentAttached(from: presenter) { [weak self] outcome in
            guard let self, self.dialog === dialog else { return }
            self.dialog = nil
            self.coordinator.analyticsSurface = .embeddedInline
            switch outcome {
            case .finished(let result):
                self.handleFinish(result)
            case .detached:
                self.render()
                self.resumeConfirmVerification(.canceled)
                // The card only shows code challenges, so steps like a phone match continue in the dialog next time.
                if self.isShowingCard, self.coordinator.screen != .otp {
                    self.dismiss()
                }
            }
        }
        return true
    }

    private func resumeConfirmVerification(_ result: ConfirmVerificationResult) {
        let continuation = confirmVerificationContinuation
        confirmVerificationContinuation = nil
        continuation?.resume(returning: result)
    }

    // MARK: - Coordinator events

    private func coordinatorDidUpdate() {
        dialog?.coordinatorDidUpdate()
        if coordinator.challenge?.isStarted == true {
            didStartCodeChallenge = true
        }
        render()
        guard isShowingCard, dialog == nil, coordinator.hasStarted, !coordinator.isLoading else { return }
        switch coordinator.screen {
        case .otp:
            if !didStartCodeChallenge {
                // The first code couldn't be sent, e.g. because of rate limits. Fall back to the regular Link row.
                invalidate()
            }
        case .phoneMatch:
            presentDialog()
        case .blocked, .webHandoff:
            invalidate()
        case .loading:
            break
        }
    }

    private func coordinatorDidFinish(_ result: LinkVerificationResult) {
        if let dialog {
            // The dialog dismisses first, then reports the result.
            dialog.coordinatorDidFinish(result)
        } else {
            handleFinish(result)
        }
    }

    private func coordinatorDidRequestWebHandoff(_ url: URL) {
        if let dialog {
            dialog.coordinatorDidRequestWebHandoff(url)
        } else {
            invalidate()
        }
    }

    private func handleFinish(_ result: LinkVerificationResult) {
        guard phase != .finished else { return }
        let wasShowingCard = isShowingCard
        finish()
        switch result {
        case .completed:
            if wasShowingCard {
                host?.linkInlineAuthDidCollapse()
            }
            host?.linkInlineAuthDidVerify(fromCard: wasShowingCard)
            resumeConfirmVerification(.verified)
        case .switchAccount:
            if wasShowingCard {
                host?.linkInlineAuthDidCollapse()
            }
            resumeConfirmVerification(.canceled)
            linkAccount.logout()
        case .canceled, .failed:
            if wasShowingCard {
                host?.linkInlineAuthDidCollapse()
            }
            resumeConfirmVerification(.canceled)
        }
    }

    private func finish() {
        phase = .finished
        stopResendTimer()
        cardView = nil
        EmbeddedLinkInlineAuthRegistry.release(self)
    }

    // MARK: - Rendering

    private func render() {
        guard isShowingCard, let cardView else { return }
        cardView.render(.init(coordinator: coordinator, email: linkAccount.email))
        updateResendTimer()
    }

    /// Ticks the card once a second while a resend cooldown counts down.
    private func updateResendTimer() {
        guard isShowingCard, coordinator.resendSecondsRemaining > 0 else {
            stopResendTimer()
            return
        }
        guard resendTimer == nil else { return }
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.render()
            }
        }
    }

    private func stopResendTimer() {
        resendTimer?.invalidate()
        resendTimer = nil
    }
}
