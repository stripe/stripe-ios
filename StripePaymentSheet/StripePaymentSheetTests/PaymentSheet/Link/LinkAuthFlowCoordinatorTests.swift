// Copyright © 2026 Stripe, Inc. All rights reserved.

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePaymentSheet
import XCTest

@MainActor
final class LinkAuthFlowCoordinatorTests: XCTestCase {
    func testStartsSMSOnceAndOnlyCompletesWhenSatisfied() async {
        let account = AuthAccountStub()
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

        account.confirmResult = .success(.init(consumerSession: authSession(current: .oneFactorAuth)))
        flow.confirm(code: "123456")
        await settle()
        XCTAssertEqual(completions, 1)
        flow.cancel()
        XCTAssertEqual(completions, 1)
    }

    func testSMSAdvancesToEmailWhenMinimumRises() async {
        let account = AuthAccountStub()
        let flow = makeFlow(account)
        var completed = false
        flow.onFinish = { if case .completed = $0 { completed = true } }
        flow.start()
        await settle()

        account.confirmResult = .success(.init(consumerSession: authSession(current: .oneFactorAuth, minimum: .twoFactorAuth, factors: [sms(advances: false), email()])))
        flow.confirm(code: "123456")
        await settle()

        XCTAssertFalse(completed)
        XCTAssertEqual(flow.step, 2)
        XCTAssertEqual(flow.challenge?.type, .email)
        XCTAssertEqual(flow.actions, [.resend])
        XCTAssertFalse(flow.canGoBack)
        XCTAssertEqual(account.starts.map(\.type), [.sms, .email])

        account.confirmResult = .success(.init(consumerSession: authSession(current: .twoFactorAuth, minimum: .twoFactorAuth)))
        flow.confirm(code: "654321")
        await settle()
        XCTAssertTrue(completed)
        XCTAssertEqual(account.confirms, [.sms, .email])
    }

    func testEmailAdvancesToSMS() async {
        let account = AuthAccountStub(session: authSession(minimum: .twoFactorAuth, factors: [email()]))
        let flow = makeFlow(account)
        flow.start()
        await settle()
        XCTAssertEqual(flow.challenge?.type, .email)

        account.confirmResult = .success(.init(consumerSession: authSession(current: .oneFactorAuth, minimum: .twoFactorAuth, factors: [sms(), email(advances: false)])))
        flow.confirm(code: "123456")
        await settle()
        XCTAssertEqual(account.starts.map(\.type), [.email, .sms])
        XCTAssertEqual(flow.actions, [.resend])
    }

    func testDefaultCapabilitiesAuthenticateEmailOnlyAccount() async {
        let account = AuthAccountStub(session: authSession(factors: [email()]))
        let flow = LinkAuthFlowCoordinator(account: account)
        flow.start()
        await settle()
        XCTAssertEqual(account.starts.map(\.type), [.email])
        XCTAssertTrue(flow.canSubmitCode)
    }

    func testPreparingEmailPhoneMatchWaitsForPhoneSubmission() async {
        // Given email is the only native factor and phone matching is required.
        let account = AuthAccountStub(session: authSession(factors: [email()]))
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
        let account = AuthAccountStub(session: authSession(current: .oneFactorAuth))
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
        let account = AuthAccountStub()
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
        let account = AuthAccountStub()
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
        let account = AuthAccountStub(session: authSession(factors: [sms(disabled: true), unknown, email()]))
        let flow = makeFlow(account)
        flow.start()
        await settle()
        XCTAssertEqual(account.starts.map(\.type), [.email])
        XCTAssertEqual(flow.actions, [.resend])
    }

    func testRepeatedFactorSwitchingReusesAnExistingChallenge() async {
        let account = AuthAccountStub()
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
        let account = AuthAccountStub(session: authSession(factors: [sms(disabled: true), email(advances: false)]))
        let flow = makeFlow(account)
        flow.start()
        XCTAssertEqual(flow.screen, .blocked)
        XCTAssertNotNil(flow.errorMessage)
        XCTAssertTrue(account.starts.isEmpty)
    }

    func testCapabilitiesControlSelectionAndActions() async {
        let account = AuthAccountStub()
        let flow = LinkAuthFlowCoordinator(account: account, capabilities: [.sms])
        flow.start()
        await settle()
        XCTAssertEqual(flow.actions, [.resend])
        flow.sendToEmail()
        XCTAssertEqual(account.starts.count, 1)
    }

    func testResendCooldownOnlyStartsOnSuccess() async {
        let account = AuthAccountStub()
        var date = Date(timeIntervalSince1970: 100)
        let flow = LinkAuthFlowCoordinator(account: account, capabilities: [.sms, .email], now: { date })
        flow.start()
        await settle()
        account.nextStartResult = .failure(authError("rate_limit_exceeded"))
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
        let account = AuthAccountStub()
        let flow = makeFlow(account)
        flow.start()
        await settle()
        account.nextStartResult = .failure(authError("phone_number_missing"))
        flow.sendToEmail()
        await settle()
        XCTAssertEqual(flow.screen, .phoneMatch)
        account.nextStartResult = .failure(authError("phone_number_mismatch"))
        flow.submitPhoneNumber("+14155550123")
        await settle()
        XCTAssertEqual(flow.screen, .phoneMatch)
        XCTAssertNotNil(flow.errorMessage)
        XCTAssertFalse(flow.isLoading)
    }

    func testWrongCodeClearsInputAndMaxAttemptsDisablesConfirmation() async {
        let account = AuthAccountStub()
        let flow = makeFlow(account)
        flow.start()
        await settle()
        let revision = flow.inputRevision
        account.confirmResult = .failure(authError("consumer_verification_code_invalid"))
        flow.confirm(code: "000000")
        await settle()
        XCTAssertGreaterThan(flow.inputRevision, revision)
        XCTAssertTrue(flow.canSubmitCode)
        account.confirmResult = .failure(authError("consumer_verification_max_attempts_exceeded"))
        flow.confirm(code: "000000")
        await settle()
        XCTAssertFalse(flow.canSubmitCode)
        XCTAssertTrue(flow.canResend)
    }

    func testExpiredCodeRestartsOnceAndDoesNotLoopOnStartFailure() async {
        let account = AuthAccountStub()
        let flow = makeFlow(account)
        flow.start()
        await settle()
        account.confirmResult = .failure(authError("consumer_verification_expired"))
        account.nextStartResult = .failure(authError("rate_limit_exceeded"))
        flow.confirm(code: "000000")
        await settle()
        XCTAssertEqual(account.starts.count, 2)
        XCTAssertFalse(flow.canSubmitCode)
        XCTAssertNotNil(flow.errorMessage)
    }

    func testCredentialsRefreshOnceThenReplayOriginalRequest() async {
        let account = AuthAccountStub()
        account.nextStartResult = .failure(authError("consumer_session_expired"))
        account.refreshResult = .success(.init(consumerSession: authSession(secret: "new_secret"), settings: .init(emailOtpRequiresAdditionalInfo: true)))
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
        let account = AuthAccountStub()
        account.nextStartResult = .failure(authError("consumer_session_credentials_invalid"))
        let flow = makeFlow(account)
        var errorCode: String?
        flow.onFinish = { if case .failed(let error) = $0 { errorCode = error._stp_error_code } }
        flow.start()
        await settle()
        XCTAssertEqual(errorCode, "consumer_session_credentials_invalid")
        XCTAssertEqual(account.refreshes, [true])
    }

    func testCancelIgnoresLateResponseAndCompletesOnce() async {
        let account = AuthAccountStub()
        account.deferStart = true
        let flow = makeFlow(account)
        var results = 0
        flow.onFinish = { _ in results += 1 }
        flow.start()
        let initialSession = account.currentSession
        flow.cancel()
        flow.cancel()
        account.pendingStart?(.success(.init(consumerSession: authSession(current: .twoFactorAuth))))
        await settle()
        XCTAssertEqual(results, 1)
        XCTAssertTrue(account.currentSession === initialSession)
    }

    func testWebCompletionRefreshesAndRequiresSatisfiedSession() async {
        let url = URL(string: "https://checkout.link.com/#test")!
        let account = AuthAccountStub(session: authSession(fallback: fallbackParams(url)))
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
        account.refreshResult = .success(.init(consumerSession: authSession(factors: [])))
        flow.webHandoffFinished(.completed)
        await settle()
        XCTAssertFalse(completed)
        XCTAssertEqual(flow.screen, .blocked)
        XCTAssertEqual(account.refreshes, [false])
    }

    func testConsumedWebURLIsRefreshedBeforeOpening() async {
        let oldURL = URL(string: "https://checkout.link.com/#old")!
        let newURL = URL(string: "https://checkout.link.com/#new")!
        let account = AuthAccountStub(session: authSession(fallback: fallbackParams(oldURL)))
        account.visitedFallbackURLs = [oldURL]
        account.refreshResult = .success(.init(consumerSession: authSession(fallback: fallbackParams(newURL))))
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

    private func makeFlow(_ account: AuthAccountStub) -> LinkAuthFlowCoordinator {
        LinkAuthFlowCoordinator(account: account, capabilities: [.sms, .email])
    }

    /// Stub responses are synchronous; drain the main-queue callbacks including one recovery/replay.
    private func settle() async {
        for _ in 0..<4 {
            await withCheckedContinuation { continuation in DispatchQueue.main.async { continuation.resume() } }
        }
    }
}

private func sms(advances: Bool = true, disabled: Bool = false) -> ConsumerSession.VerificationFactor {
    .init(type: .sms, providesFurtherVerification: advances, temporarilyDisabled: disabled, id: "sms_factor")
}

private func email(advances: Bool = true) -> ConsumerSession.VerificationFactor {
    .init(type: .email, providesFurtherVerification: advances, temporarilyDisabled: false, id: "email_factor")
}

private func authSession(secret: String = "secret", current: ConsumerSession.AuthenticationLevel = .notAuthenticated, minimum: ConsumerSession.AuthenticationLevel = .oneFactorAuth, factors: [ConsumerSession.VerificationFactor] = [sms(), email()], sessions: [ConsumerSession.VerificationSession] = [], fallback: ConsumerSession.MobileFallbackWebviewParams? = nil) -> ConsumerSession {
    ConsumerSession.make(clientSecret: secret, emailAddress: "jane@example.com", redactedFormattedPhoneNumber: "(***) *** **23", unredactedPhoneNumber: nil, phoneNumberCountry: "US", verificationSessions: sessions, supportedPaymentDetailsTypes: [], mobileFallbackWebviewParams: fallback, currentAuthenticationLevel: current, minimumAuthenticationLevel: minimum, availableVerificationFactors: factors)
}

private func authError(_ code: String) -> Error {
    NSError(domain: STPError.stripeDomain, code: 400, userInfo: [STPError.stripeErrorCodeKey: code, NSLocalizedDescriptionKey: code])
}

private func fallbackParams(_ url: URL) -> ConsumerSession.MobileFallbackWebviewParams {
    let data = try! JSONSerialization.data(withJSONObject: ["webview_open_url": url.absoluteString, "webview_requirement_type": "required"])
    return try! StripeJSONDecoder().decode(ConsumerSession.MobileFallbackWebviewParams.self, from: data)
}

private final class AuthAccountStub: LinkAuthAccount {
    var currentSession: ConsumerSession?
    var authLookupSettings: ConsumerSession.LookupSettings? = .init(emailOtpRequiresAdditionalInfo: false)
    var useMobileEndpoints = true
    var visitedFallbackURLs: [URL] = []
    var sessionState: PaymentSheetLinkAccount.SessionState { currentSession?.meetsMinimumAuthenticationLevel == true ? .verified : .requiresVerification }
    var nextStartResult: Result<ConsumerSession.AuthResponse, Error>?
    var confirmResult: Result<ConsumerSession.AuthResponse, Error> = .failure(authError("consumer_verification_code_invalid"))
    var refreshResult: Result<ConsumerSession.AuthResponse, Error> = .failure(authError("consumer_session_expired"))
    var starts: [(type: SupportedVerificationType, phone: String?, resend: Bool)] = []
    var confirms: [SupportedVerificationType] = []
    var refreshes: [Bool] = []
    var deferStart = false
    var pendingStart: ((Result<ConsumerSession.AuthResponse, Error>) -> Void)?

    init(session: ConsumerSession = authSession()) { currentSession = session }

    func applyAuthResponse(_ response: ConsumerSession.AuthResponse) {
        currentSession = response.consumerSession
        if let settings = response.settings { authLookupSettings = settings }
    }

    func startAuthVerification(type: SupportedVerificationType, phoneNumber: String?, isResending: Bool, completion: @escaping (Result<ConsumerSession.AuthResponse, Error>) -> Void) {
        starts.append((type, phoneNumber, isResending))
        if deferStart {
            pendingStart = completion
        } else if let result = nextStartResult {
            nextStartResult = nil
            completion(result)
        } else {
            let session = currentSession!
            completion(.success(.init(consumerSession: authSession(secret: session.clientSecret, current: session.currentAuthenticationLevel!, minimum: session.minimumAuthenticationLevel!, factors: session.availableVerificationFactors!, sessions: [.init(type: type == .sms ? .sms : .email, state: .started)]), verificationSessionId: "verification_\(starts.count)")))
        }
    }

    func confirmAuthVerification(type: SupportedVerificationType, code: String, consentGranted: Bool?, completion: @escaping (Result<ConsumerSession.AuthResponse, Error>) -> Void) {
        confirms.append(type)
        completion(confirmResult)
    }

    func refreshAuthSession(recoverCredentials: Bool, completion: @escaping (Result<ConsumerSession.AuthResponse, Error>) -> Void) {
        refreshes.append(recoverCredentials)
        completion(refreshResult)
    }
}
