// Copyright © 2026 Stripe, Inc. All rights reserved.

@testable @_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripeCoreTestUtils
@testable @_spi(InternalOnlyAPI) @_spi(CheckoutSessionPreview) import StripePaymentSheet
import XCTest

@MainActor
final class LinkAuthFlowCoordinatorTests: XCTestCase {
    func testStartsSMSOnceAndOnlyCompletesWhenSatisfied() async {
        let account = LinkAuthAccountStub()
        let flow = makeFlow(account)
        var completions = 0
        flow.onFinish = { if case .completed = $0 { completions += 1 } }

        // Given screen preparation must not start verification or allow an early resend.
        flow.prepare()
        flow.prepare()
        XCTAssertEqual(flow.screen, .otp)
        XCTAssertEqual(flow.challenge?.type, .sms)
        XCTAssertTrue(flow.isLoadingOTP)
        XCTAssertFalse(flow.canResend)
        XCTAssertFalse(flow.canSubmitCode)
        flow.resend()
        flow.sendToEmail()
        XCTAssertTrue(account.starts.isEmpty)

        // When presentation starts authentication, exactly one SMS challenge is sent.
        flow.start()
        flow.start()
        XCTAssertTrue(flow.isLoadingOTP)
        await settle()
        XCTAssertEqual(account.starts.map(\.type), [.sms])
        XCTAssertFalse(flow.isLoadingOTP)
        XCTAssertEqual(completions, 0)
        let challengeID = flow.challenge?.verificationSessionID
        flow.prepare()
        XCTAssertEqual(flow.challenge?.verificationSessionID, challengeID)

        account.confirmResult = .success(.init(consumerSession: LinkAuthStubs.session(current: .oneFactorAuth)))
        flow.confirm(code: "123456")
        await settle()
        XCTAssertEqual(completions, 1)
        flow.cancel()
        XCTAssertEqual(completions, 1)
    }

    func testSMSAdvancesToEmailWhenMinimumRises() async {
        let account = LinkAuthAccountStub()
        let flow = makeFlow(account)
        var completed = false
        flow.onFinish = { if case .completed = $0 { completed = true } }
        flow.start()
        await settle()

        account.confirmResult = .success(.init(consumerSession: LinkAuthStubs.session(current: .oneFactorAuth, minimum: .twoFactorAuth, factors: [LinkAuthStubs.sms(advances: false), LinkAuthStubs.email()])))
        flow.confirm(code: "123456")
        await settle()

        XCTAssertFalse(completed)
        XCTAssertEqual(flow.step, 2)
        XCTAssertEqual(flow.challenge?.type, .email)
        XCTAssertEqual(flow.actions, [.resend])
        XCTAssertFalse(flow.canGoBack)
        XCTAssertEqual(account.starts.map(\.type), [.sms, .email])

        account.confirmResult = .success(.init(consumerSession: LinkAuthStubs.session(current: .twoFactorAuth, minimum: .twoFactorAuth)))
        flow.confirm(code: "654321")
        await settle()
        XCTAssertTrue(completed)
        XCTAssertEqual(account.confirms, [.sms, .email])
    }

    func testEmailAdvancesToSMS() async {
        let account = LinkAuthAccountStub(session: LinkAuthStubs.session(minimum: .twoFactorAuth, factors: [LinkAuthStubs.email()]))
        let flow = makeFlow(account)
        flow.start()
        await settle()
        XCTAssertEqual(flow.challenge?.type, .email)

        account.confirmResult = .success(.init(consumerSession: LinkAuthStubs.session(current: .oneFactorAuth, minimum: .twoFactorAuth, factors: [LinkAuthStubs.sms(), LinkAuthStubs.email(advances: false)])))
        flow.confirm(code: "123456")
        await settle()
        XCTAssertEqual(account.starts.map(\.type), [.email, .sms])
        XCTAssertEqual(flow.actions, [.resend])
    }

    func testDefaultCapabilitiesAuthenticateEmailOnlyAccount() async {
        let account = LinkAuthAccountStub(session: LinkAuthStubs.session(factors: [LinkAuthStubs.email()]))
        let flow = LinkAuthFlowCoordinator(account: account, analyticsHelper: .init())
        flow.start()
        await settle()
        XCTAssertEqual(account.starts.map(\.type), [.email])
        XCTAssertTrue(flow.canSubmitCode)
    }

    func testPreparingEmailPhoneMatchWaitsForPhoneSubmission() async {
        // Given email is the only native factor and phone matching is required.
        let account = LinkAuthAccountStub(session: LinkAuthStubs.session(factors: [LinkAuthStubs.email()]))
        account.authLookupSettings = .init(emailOtpRequiresAdditionalInfo: true)
        let flow = makeFlow(account)

        // When preparing and then starting the flow.
        flow.prepare()
        XCTAssertEqual(flow.screen, .phoneMatch)
        XCTAssertEqual(flow.challenge?.type, .email)
        XCTAssertTrue(account.starts.isEmpty)
        flow.start()
        XCTAssertEqual(flow.screen, .phoneMatch)
        XCTAssertTrue(account.starts.isEmpty)

        // Then only phone submission requests the email OTP.
        flow.submitPhoneNumber("+14155550123")
        await settle()
        XCTAssertEqual(account.starts.map(\.type), [.email])
        XCTAssertEqual(account.starts.first?.phone, "+14155550123")
        XCTAssertEqual(flow.screen, .otp)
    }

    func testPreparingVerifiedSessionDefersCompletionUntilStart() {
        // Given a session already satisfies the required authentication level.
        let account = LinkAuthAccountStub(session: LinkAuthStubs.session(current: .oneFactorAuth))
        let flow = makeFlow(account)
        var completions = 0
        flow.onFinish = { if case .completed = $0 { completions += 1 } }

        // When preparing before the modal is presented.
        flow.prepare()

        // Then completion waits until presentation, without showing an OTP screen or sending a code.
        XCTAssertEqual(flow.screen, .loading)
        XCTAssertEqual(completions, 0)
        XCTAssertTrue(account.starts.isEmpty)
        flow.start()
        XCTAssertEqual(completions, 1)
        XCTAssertTrue(account.starts.isEmpty)
    }

    func testPhoneMatchDefersEmailStartAndReusesPhoneForResend() async {
        let account = LinkAuthAccountStub()
        account.authLookupSettings = .init(emailOtpRequiresAdditionalInfo: true)
        let flow = makeFlow(account)
        flow.start()
        await settle()
        flow.sendToEmail()
        XCTAssertEqual(flow.screen, .phoneMatch)
        XCTAssertEqual(account.starts.count, 1)

        flow.submitPhoneNumber("+14155550123")
        await settle()
        XCTAssertEqual(flow.screen, .otp)
        XCTAssertEqual(account.starts.last?.phone, "+14155550123")
        XCTAssertEqual(account.starts.last?.type, .email)
        flow.resend()
        await settle()
        XCTAssertEqual(account.starts.last?.phone, "+14155550123")
        XCTAssertEqual(account.starts.last?.type, .email)
        XCTAssertTrue(account.starts.last?.resend == true)
    }

    func testBackRestoresChallengeWithoutSendingAndPreservesCooldown() async {
        let account = LinkAuthAccountStub()
        let flow = makeFlow(account)
        flow.start()
        await settle()
        flow.resend()
        await settle()
        let deadline = flow.challenge?.resendDeadline
        flow.sendToEmail()
        await settle()
        let sends = account.starts.count
        flow.goBack()
        XCTAssertEqual(flow.challenge?.type, .sms)
        XCTAssertEqual(account.starts.count, sends)
        XCTAssertEqual(flow.challenge?.resendDeadline, deadline)
        XCTAssertFalse(flow.canResend)
    }

    func testDisabledAndUnknownFactorsAreNeverSelected() async {
        let unknown = ConsumerSession.VerificationFactor(type: .unparsable, providesFurtherVerification: true, temporarilyDisabled: false, id: "unknown")
        let account = LinkAuthAccountStub(session: LinkAuthStubs.session(factors: [LinkAuthStubs.sms(disabled: true), unknown, LinkAuthStubs.email()]))
        let flow = makeFlow(account)
        flow.start()
        await settle()
        XCTAssertEqual(account.starts.map(\.type), [.email])
        XCTAssertEqual(flow.actions, [.resend])
    }

    func testRepeatedFactorSwitchingReusesAnExistingChallenge() async {
        let account = LinkAuthAccountStub()
        let flow = makeFlow(account)
        flow.start()
        await settle()
        flow.sendToEmail()
        await settle()
        let verificationID = flow.challenge?.verificationSessionID
        flow.goBack()
        flow.sendToEmail()
        XCTAssertEqual(account.starts.count, 2)
        XCTAssertEqual(flow.challenge?.verificationSessionID, verificationID)
    }

    func testNoUsableFactorBlocksWithoutSending() {
        let account = LinkAuthAccountStub(session: LinkAuthStubs.session(factors: [LinkAuthStubs.sms(disabled: true), LinkAuthStubs.email(advances: false)]))
        let flow = makeFlow(account)
        flow.start()
        XCTAssertEqual(flow.screen, .blocked)
        XCTAssertNotNil(flow.errorMessage)
        XCTAssertTrue(account.starts.isEmpty)
    }

    func testSMSOnlyCapabilitiesBlockEmailOnlyAccount() async {
        // Given an email-only account while the MFA auth flow is disabled
        let account = LinkAuthAccountStub(session: LinkAuthStubs.session(factors: [LinkAuthStubs.email()]))
        account.supportedVerificationTypes = SupportedVerificationType.nativeCapabilities(mfaAuthFlowEnabled: false)
        let flow = LinkAuthFlowCoordinator(account: account, analyticsHelper: .init())

        // When the flow starts
        flow.start()
        await settle()

        // Then no email code is sent and the flow is blocked
        XCTAssertTrue(account.starts.isEmpty)
        XCTAssertEqual(flow.screen, .blocked)
    }

    func testCapabilitiesControlSelectionAndActions() async {
        let account = LinkAuthAccountStub()
        account.supportedVerificationTypes = [.sms]
        let flow = LinkAuthFlowCoordinator(account: account, analyticsHelper: .init())
        flow.start()
        await settle()
        XCTAssertEqual(flow.actions, [.resend])
        flow.sendToEmail()
        XCTAssertEqual(account.starts.count, 1)
    }

    func testResendCooldownOnlyStartsOnSuccess() async {
        let account = LinkAuthAccountStub()
        var date = Date(timeIntervalSince1970: 100)
        let flow = LinkAuthFlowCoordinator(account: account, analyticsHelper: .init(), now: { date })
        flow.start()
        await settle()
        account.nextStartResult = .failure(LinkAuthStubs.error("rate_limit_exceeded"))
        flow.resend()
        await settle()
        XCTAssertTrue(flow.canResend)
        flow.resend()
        await settle()
        XCTAssertEqual(flow.resendSecondsRemaining, 10)
        let count = account.starts.count
        flow.resend()
        XCTAssertEqual(account.starts.count, count)
        date.addTimeInterval(10)
        XCTAssertTrue(flow.canResend)
    }

    func testPhoneMissingOverridesLookupHintAndMismatchStaysInline() async {
        let account = LinkAuthAccountStub()
        let flow = makeFlow(account)
        flow.start()
        await settle()
        account.nextStartResult = .failure(LinkAuthStubs.error("phone_number_missing"))
        flow.sendToEmail()
        await settle()
        XCTAssertEqual(flow.screen, .phoneMatch)
        account.nextStartResult = .failure(LinkAuthStubs.error("phone_number_mismatch"))
        flow.submitPhoneNumber("+14155550123")
        await settle()
        XCTAssertEqual(flow.screen, .phoneMatch)
        XCTAssertNotNil(flow.errorMessage)
        XCTAssertFalse(flow.isLoading)
    }

    func testWrongCodeSignalsInvalidCodeAndMaxAttemptsDisablesConfirmation() async {
        let account = LinkAuthAccountStub()
        let flow = makeFlow(account)
        flow.start()
        await settle()
        let inputRevision = flow.inputRevision
        let invalidCodeRevision = flow.invalidCodeRevision
        account.confirmResult = .failure(LinkAuthStubs.error("consumer_verification_code_invalid"))
        flow.confirm(code: "000000")
        await settle()
        // The field is cleared by the invalid-code animation rather than an input reset.
        XCTAssertEqual(flow.inputRevision, inputRevision)
        XCTAssertGreaterThan(flow.invalidCodeRevision, invalidCodeRevision)
        XCTAssertNotNil(flow.errorMessage)
        XCTAssertTrue(flow.canSubmitCode)
        flow.codeDidChange()
        XCTAssertNil(flow.errorMessage)
        account.confirmResult = .failure(LinkAuthStubs.error("consumer_verification_max_attempts_exceeded"))
        flow.confirm(code: "000000")
        await settle()
        XCTAssertFalse(flow.canSubmitCode)
        XCTAssertTrue(flow.canResend)
    }

    func testExpiredOrMissingVerificationRestartsOnceAndDoesNotLoopOnStartFailure() async {
        for errorCode in [
            LinkUtils.ConsumerErrorCode.consumerVerificationExpired,
            .consumerVerificationNotFound,
        ] {
            let account = LinkAuthAccountStub()
            let flow = makeFlow(account)
            flow.start()
            await settle()
            account.confirmResult = .failure(LinkAuthStubs.error(errorCode.rawValue))
            account.nextStartResult = .failure(LinkAuthStubs.error("rate_limit_exceeded"))
            flow.confirm(code: "000000")
            await settle()
            XCTAssertEqual(account.starts.count, 2)
            XCTAssertFalse(flow.canSubmitCode)
            XCTAssertNotNil(flow.errorMessage)
        }
    }

    func testCredentialsRefreshOnceThenReplayOriginalRequest() async {
        let account = LinkAuthAccountStub()
        account.nextStartResult = .failure(LinkAuthStubs.error("consumer_session_expired"))
        account.refreshResult = .success(.init(consumerSession: LinkAuthStubs.session(secret: "new_secret"), settings: .init(emailOtpRequiresAdditionalInfo: true)))
        let flow = makeFlow(account)
        flow.start()
        await settle()
        XCTAssertEqual(account.refreshes, [true])
        XCTAssertEqual(account.starts.count, 2)
        XCTAssertEqual(account.currentSession?.clientSecret, "new_secret")
        XCTAssertTrue(flow.canSubmitCode)
        XCTAssertEqual(account.authLookupSettings?.emailOtpRequiresAdditionalInfo, true)
    }

    func testRefreshFailureReturnsOriginalError() async {
        let account = LinkAuthAccountStub()
        account.nextStartResult = .failure(LinkAuthStubs.error("consumer_session_credentials_invalid"))
        let flow = makeFlow(account)
        var errorCode: String?
        flow.onFinish = { if case .failed(let error) = $0 { errorCode = error._stp_error_code } }
        flow.start()
        await settle()
        XCTAssertEqual(errorCode, "consumer_session_credentials_invalid")
        XCTAssertEqual(account.refreshes, [true])
    }

    func testCancelIgnoresLateResponseAndCompletesOnce() async {
        let account = LinkAuthAccountStub()
        account.deferStart = true
        let flow = makeFlow(account)
        var results = 0
        flow.onFinish = { _ in results += 1 }
        flow.start()
        let initialSession = account.currentSession
        flow.cancel()
        flow.cancel()
        account.pendingStart?(.success(.init(consumerSession: LinkAuthStubs.session(current: .twoFactorAuth))))
        await settle()
        XCTAssertEqual(results, 1)
        XCTAssertTrue(account.currentSession === initialSession)
    }

    func testWebCompletionRefreshesAndRequiresSatisfiedSession() async {
        let url = URL(string: "https://checkout.link.com/#test")!
        let account = LinkAuthAccountStub(session: LinkAuthStubs.session(fallback: LinkAuthStubs.fallbackParams(url)))
        let flow = makeFlow(account)
        var urls: [URL] = []
        var completed = false
        flow.onWebHandoff = { urls.append($0) }
        flow.onFinish = { if case .completed = $0 { completed = true } }
        flow.prepare()
        XCTAssertEqual(flow.screen, .webHandoff)
        XCTAssertTrue(urls.isEmpty)
        XCTAssertTrue(account.visitedFallbackURLs.isEmpty)
        XCTAssertTrue(account.refreshes.isEmpty)
        flow.start()
        XCTAssertEqual(urls, [url])
        XCTAssertEqual(account.visitedFallbackURLs, [url])
        XCTAssertTrue(account.starts.isEmpty)
        account.refreshResult = .success(.init(consumerSession: LinkAuthStubs.session(factors: [])))
        flow.webHandoffFinished(.completed)
        await settle()
        XCTAssertFalse(completed)
        XCTAssertEqual(flow.screen, .blocked)
        XCTAssertEqual(account.refreshes, [false])
    }

    func testConsumedWebURLIsRefreshedBeforeOpening() async {
        let oldURL = URL(string: "https://checkout.link.com/#old")!
        let newURL = URL(string: "https://checkout.link.com/#new")!
        let account = LinkAuthAccountStub(session: LinkAuthStubs.session(fallback: LinkAuthStubs.fallbackParams(oldURL)))
        account.visitedFallbackURLs = [oldURL]
        account.refreshResult = .success(.init(consumerSession: LinkAuthStubs.session(fallback: LinkAuthStubs.fallbackParams(newURL))))
        let flow = makeFlow(account)
        var openedURL: URL?
        flow.onWebHandoff = { openedURL = $0 }
        flow.prepare()
        XCTAssertNil(openedURL)
        XCTAssertTrue(account.refreshes.isEmpty)
        flow.start()
        await settle()
        XCTAssertEqual(openedURL, newURL)
        XCTAssertEqual(account.refreshes, [false])
    }

    func testInvalidateEndsTheAttemptWithoutLoggingOrFinishing() async {
        // Given a started SMS challenge whose host listens for completion
        let analyticsClient = STPTestingAnalyticsClient()
        let account = LinkAuthAccountStub()
        let flow = LinkAuthFlowCoordinator(account: account, analyticsHelper: .init(analyticsClient: analyticsClient))
        var finishes = 0
        flow.onFinish = { _ in finishes += 1 }
        XCTAssertFalse(flow.hasStarted)
        flow.start()
        await settle()
        XCTAssertTrue(flow.hasStarted)

        // When the host invalidates the attempt
        flow.invalidate()

        // Then it ends quietly: no completion, no cancel event, and no further requests
        XCTAssertTrue(flow.isFinished)
        XCTAssertEqual(finishes, 0)
        XCTAssertFalse(analyticsClient._testLogHistory.contains { $0["event"] as? String == "link.2fa.cancel" })
        flow.confirm(code: "123456")
        flow.resend()
        flow.cancel()
        await settle()
        XCTAssertEqual(account.starts.count, 1)
        XCTAssertTrue(account.confirms.isEmpty)
        XCTAssertEqual(finishes, 0)
    }

    func testAnalyticsSurfaceIsAddedToVerificationEvents() async throws {
        // Given an attempt that starts inline
        let analyticsClient = STPTestingAnalyticsClient()
        let flow = LinkAuthFlowCoordinator(account: LinkAuthAccountStub(), analyticsHelper: .init(analyticsClient: analyticsClient))
        flow.analyticsSurface = .embeddedInline
        flow.prepare()
        flow.start()
        await settle()

        // When the same attempt moves to the dialog and is canceled there
        flow.analyticsSurface = .embeddedDialog
        flow.cancel()

        // Then each event carries the surface it happened on
        let events = analyticsClient._testLogHistory
        let start = try XCTUnwrap(events.first { $0["event"] as? String == "link.2fa.start" })
        XCTAssertEqual(start["link_auth_surface"] as? String, "embedded_inline")
        XCTAssertEqual(start["verification_type"] as? String, "SMS")
        let cancel = try XCTUnwrap(events.first { $0["event"] as? String == "link.2fa.cancel" })
        XCTAssertEqual(cancel["link_auth_surface"] as? String, "embedded_dialog")
    }

    func testVerificationEventsOmitSurfaceByDefault() async throws {
        let analyticsClient = STPTestingAnalyticsClient()
        let flow = LinkAuthFlowCoordinator(account: LinkAuthAccountStub(), analyticsHelper: .init(analyticsClient: analyticsClient))
        flow.start()
        await settle()

        let start = try XCTUnwrap(analyticsClient._testLogHistory.first { $0["event"] as? String == "link.2fa.start" })
        XCTAssertNil(start["link_auth_surface"])
    }

    private func makeFlow(_ account: LinkAuthAccountStub) -> LinkAuthFlowCoordinator {
        LinkAuthFlowCoordinator(account: account, analyticsHelper: .init())
    }

    /// Stub responses are synchronous; drain the main-queue callbacks including one recovery/replay.
    private func settle() async {
        for _ in 0..<4 {
            await withCheckedContinuation { continuation in DispatchQueue.main.async { continuation.resume() } }
        }
    }
}
