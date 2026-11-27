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
/// the first time the element is on screen, and entered in the card or, when the card or the merchant's layout can't handle it,
/// in the Link dialog.
@MainActor
final class EmbeddedLinkInlineAuthController {
    enum ConfirmVerificationResult: Equatable {
        case verified
        case canceled
        /// The dialog can't be shown, so paying with Link verifies the usual way.
        case unavailable
    }

    /// Where the code goes when the customer taps the card's code field.
    enum CodeEntry: Equatable {
        case inline
        case dialog(DialogReason)
    }

    enum DialogReason: Equatable {
        case forcedByServer
        case voiceOver
        /// The card only takes the first SMS code. Email codes and second factors use the dialog.
        case unsupportedStep
        /// The merchant's layout can't keep the code field visible above the keyboard.
        case layout(EmbeddedKeyboardAvoider.DialogReason)
        /// The keyboard still covered the code field after the layout adjusted.
        case obscured

        var analyticsValue: String {
            switch self {
            case .forcedByServer: return "forced_by_server"
            case .voiceOver: return "voice_over"
            case .unsupportedStep: return "unsupported_step"
            case .layout(let reason): return reason.rawValue
            case .obscured: return "obscured"
            }
        }
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
    /// A server switch that sends every code entry to the dialog.
    var forcesDialog: Bool

    private let experiment: EmbeddedLinkInlineVerificationExperiment?
    private let configuration: EmbeddedPaymentElement.Configuration
    private let linkBrand: LinkBrand
    private let experimentAnalyticsHelper: ExperimentAnalyticsHelper
    private let linkAnalyticsHelper: LinkAnalyticsHelper
    private weak var cardView: EmbeddedLinkInlineVerificationView?
    private var dialog: LinkVerificationController?
    private var resendTimer: Timer?
    private var didBecomeVisible = false
    /// Set once a code challenge has started, to tell a failed first send apart from later errors.
    private var didStartCodeChallenge = false
    private var confirmVerificationContinuation: CheckedContinuation<ConfirmVerificationResult, Never>?
    private var keyboardAvoider: EmbeddedKeyboardAvoider?
    /// Digits typed so far, carried into a rebuilt card while the field hasn't been cleared since.
    private var enteredCode: (code: String, inputRevision: Int, invalidCodeRevision: Int)?
    private var renderedErrorMessage: String?

    init(
        eligible: EmbeddedLinkInlineVerificationEligibility.Eligible,
        experiment: EmbeddedLinkInlineVerificationExperiment?,
        configuration: EmbeddedPaymentElement.Configuration,
        linkBrand: LinkBrand,
        forcesDialog: Bool = false,
        experimentAnalyticsHelper: ExperimentAnalyticsHelper,
        linkAnalyticsHelper: LinkAnalyticsHelper
    ) {
        self.linkAccount = eligible.linkAccount
        self.forcesDialog = forcesDialog
        self.coordinator = eligible.coordinator
        self.experiment = experiment
        self.configuration = configuration
        self.linkBrand = linkBrand
        self.experimentAnalyticsHelper = experimentAnalyticsHelper
        self.linkAnalyticsHelper = linkAnalyticsHelper
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
            if !presentDialog(reason: "confirm") {
                resumeConfirmVerification(.unavailable)
            }
        }
    }

    /// A new card for a rebuilt list, or nil when the card isn't showing.
    func makeCardView(appearance: PaymentSheet.Appearance) -> EmbeddedLinkInlineVerificationView? {
        guard isShowingCard else { return nil }
        // The previous card is going away.
        endInlineEntry()
        let cardView = EmbeddedLinkInlineVerificationView(appearance: appearance, linkBrand: linkBrand)
        cardView.onTapCode = { [weak self] in self?.codeTapped() }
        cardView.onClose = { [weak self] in self?.dismiss() }
        cardView.onSwitchAccount = { [weak self] in self?.coordinator.cancel(switchAccount: true) }
        cardView.onAction = { [weak self] action in self?.perform(action) }
        cardView.onCodeChanged = { [weak self] code in self?.codeDidChange(code) }
        cardView.onCodeEntered = { [weak self] code in self?.coordinator.confirm(code: code) }
        cardView.onCodeEditingEnded = { [weak self, weak cardView] in
            guard let self, cardView === self.cardView else { return }
            self.keyboardAvoider?.deactivate()
        }
        self.cardView = cardView
        let keyboardAvoider = EmbeddedKeyboardAvoider(targetView: cardView.focusRegion, accessoryHeight: cardView.keyboardAccessoryHeight)
        keyboardAvoider.onTargetObscured = { [weak self] in self?.fallBackToDialog() }
        self.keyboardAvoider = keyboardAvoider
        render()
        if let enteredCode, enteredCode.inputRevision == coordinator.inputRevision, enteredCode.invalidCodeRevision == coordinator.invalidCodeRevision {
            cardView.restoreCode(enteredCode.code)
        }
        return cardView
    }

    /// Where the code goes if the customer taps the card's code field now.
    func codeEntry() -> CodeEntry {
        if forcesDialog {
            return .dialog(.forcedByServer)
        }
        if UIAccessibility.isVoiceOverRunning {
            return .dialog(.voiceOver)
        }
        guard coordinator.screen == .otp, coordinator.challenge != nil, coordinator.step == 1 else {
            return .dialog(.unsupportedStep)
        }
        switch keyboardAvoider?.decide() ?? .dialog(.notInWindow) {
        case .inline:
            return .inline
        case .dialog(let reason):
            return .dialog(.layout(reason))
        }
    }

    /// Stops typing in the card, e.g. when the customer picks another payment method or the list is about to change.
    func endInlineEntry() {
        if cardView?.isCodeFocused == true {
            cardView?.resignCode()
        }
        keyboardAvoider?.deactivate()
    }

    /// Call the first time the element is on screen. Logs the experiment exposure and, unless this is a control group, sends the code.
    func elementBecameVisible() {
        guard !didBecomeVisible, phase != .finished else { return }
        didBecomeVisible = true
        if let experiment {
            experimentAnalyticsHelper.logExposure(experiment: experiment)
        }
        guard isShowingCard else { return }
        linkAnalyticsHelper.logEmbeddedInlineAuthShown()
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
                fallBack(reason: "attestation_failed")
                return
            }
        }
        guard isShowingCard, !coordinator.hasStarted else { return }
        EmbeddedLinkInlineAuthRegistry.recordAutoSend(email: linkAccount.email)
        coordinator.analyticsSurface = .embeddedInline
        coordinator.start()
    }

    private func codeTapped() {
        guard isShowingCard, dialog == nil, let cardView else { return }
        switch codeEntry() {
        case .inline:
            linkAnalyticsHelper.logEmbeddedInlineAuthFocused()
            keyboardAvoider?.activate()
            cardView.focusCode()
        case .dialog(let reason):
            presentDialog(reason: reason.analyticsValue)
        }
    }

    private func codeDidChange(_ code: String) {
        enteredCode = (code, coordinator.inputRevision, coordinator.invalidCodeRevision)
        coordinator.codeDidChange()
    }

    /// The keyboard covered the code field after all, so the code is entered in the dialog instead.
    private func fallBackToDialog() {
        guard cardView?.isCodeFocused == true else { return }
        presentDialog(reason: DialogReason.obscured.analyticsValue)
    }

    private func perform(_ action: LinkAuthFlowCoordinator.Action) {
        switch action {
        case .resend:
            coordinator.resend()
        case .email:
            // If the email code needs a phone number match first, `coordinatorDidUpdate` moves it to the dialog.
            coordinator.sendToEmail()
        }
    }

    private func dismiss() {
        guard isShowingCard else { return }
        endInlineEntry()
        linkAnalyticsHelper.logEmbeddedInlineAuthDismissed()
        EmbeddedLinkInlineAuthRegistry.recordDismissal(email: linkAccount.email)
        phase = .collapsed
        stopResendTimer()
        cardView = nil
        EmbeddedLinkInlineAuthRegistry.release(self)
        host?.linkInlineAuthDidCollapse()
    }

    // MARK: - Dialog

    /// - Parameter reason: Why the dialog is shown instead of the card, for analytics.
    @discardableResult
    private func presentDialog(reason: String) -> Bool {
        guard dialog == nil, phase != .finished, let presenter = host?.linkInlineAuthPresentingViewController() else { return false }
        endInlineEntry()
        linkAnalyticsHelper.logEmbeddedInlineAuthDialogShown(reason: reason)
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

    /// Ends the attempt because the card can't continue it, showing the regular Link row instead.
    private func fallBack(reason: String) {
        if isShowingCard {
            linkAnalyticsHelper.logEmbeddedInlineAuthFellBack(reason: reason)
        }
        invalidate()
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
                fallBack(reason: "send_failed")
            }
        case .phoneMatch:
            presentDialog(reason: "phone_match")
        case .blocked:
            fallBack(reason: "blocked")
        case .webHandoff:
            fallBack(reason: "web_handoff")
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
            fallBack(reason: "web_handoff")
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
        endInlineEntry()
        phase = .finished
        stopResendTimer()
        cardView = nil
        EmbeddedLinkInlineAuthRegistry.release(self)
    }

    // MARK: - Rendering

    private func render() {
        guard isShowingCard, let cardView else { return }
        let state = EmbeddedLinkInlineVerificationView.State(coordinator: coordinator, email: linkAccount.email)
        cardView.render(state)
        if state.errorMessage != renderedErrorMessage {
            renderedErrorMessage = state.errorMessage
            if cardView.isCodeFocused {
                // Keep the field and the message visible once the list lays out at its new height.
                DispatchQueue.main.async { [weak self] in
                    self?.keyboardAvoider?.targetDidChangeSize()
                }
            }
        }
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
