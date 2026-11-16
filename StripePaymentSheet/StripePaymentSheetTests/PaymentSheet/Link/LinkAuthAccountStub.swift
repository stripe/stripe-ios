// Copyright © 2026 Stripe, Inc. All rights reserved.

@testable @_spi(InternalOnlyAPI) import StripeCore
@testable @_spi(InternalOnlyAPI) import StripePaymentSheet

/// Builders for Link auth test values.
enum LinkAuthStubs {
    static func sms(advances: Bool = true, disabled: Bool = false) -> ConsumerSession.VerificationFactor {
        .init(type: .sms, providesFurtherVerification: advances, temporarilyDisabled: disabled, id: "sms_factor")
    }

    static func email(advances: Bool = true) -> ConsumerSession.VerificationFactor {
        .init(type: .email, providesFurtherVerification: advances, temporarilyDisabled: false, id: "email_factor")
    }

    static func session(
        secret: String = "secret",
        current: ConsumerSession.AuthenticationLevel = .notAuthenticated,
        minimum: ConsumerSession.AuthenticationLevel = .oneFactorAuth,
        factors: [ConsumerSession.VerificationFactor] = [sms(), email()],
        sessions: [ConsumerSession.VerificationSession] = [],
        fallback: ConsumerSession.MobileFallbackWebviewParams? = nil
    ) -> ConsumerSession {
        ConsumerSession.make(clientSecret: secret, emailAddress: "jane@example.com", redactedFormattedPhoneNumber: "(***) *** **23", unredactedPhoneNumber: nil, phoneNumberCountry: "US", verificationSessions: sessions, supportedPaymentDetailsTypes: [], mobileFallbackWebviewParams: fallback, currentAuthenticationLevel: current, minimumAuthenticationLevel: minimum, availableVerificationFactors: factors)
    }

    static func error(_ code: String) -> Error {
        NSError(domain: STPError.stripeDomain, code: 400, userInfo: [STPError.stripeErrorCodeKey: code, NSLocalizedDescriptionKey: code])
    }

    static func fallbackParams(_ url: URL) -> ConsumerSession.MobileFallbackWebviewParams {
        let data = try! JSONSerialization.data(withJSONObject: ["webview_open_url": url.absoluteString, "webview_requirement_type": "required"])
        return try! StripeJSONDecoder().decode(ConsumerSession.MobileFallbackWebviewParams.self, from: data)
    }
}

/// A Link account whose auth requests complete synchronously with configurable results.
final class LinkAuthAccountStub: LinkAuthAccount {
    var currentSession: ConsumerSession?
    var authLookupSettings: ConsumerSession.LookupSettings? = .init(emailOtpRequiresAdditionalInfo: false)
    var useMobileEndpoints = true
    var supportedVerificationTypes: [SupportedVerificationType] = [.sms, .email]
    var visitedFallbackURLs: [URL] = []
    var sessionState: PaymentSheetLinkAccount.SessionState { currentSession?.meetsMinimumAuthenticationLevel == true ? .verified : .requiresVerification }
    var nextStartResult: Result<ConsumerSession.AuthResponse, Error>?
    var confirmResult: Result<ConsumerSession.AuthResponse, Error> = .failure(LinkAuthStubs.error("consumer_verification_code_invalid"))
    var refreshResult: Result<ConsumerSession.AuthResponse, Error> = .failure(LinkAuthStubs.error("consumer_session_expired"))
    var starts: [(type: SupportedVerificationType, phone: String?, resend: Bool)] = []
    var confirms: [SupportedVerificationType] = []
    var refreshes: [Bool] = []
    var deferStart = false
    var pendingStart: ((Result<ConsumerSession.AuthResponse, Error>) -> Void)?

    init(session: ConsumerSession = LinkAuthStubs.session()) { currentSession = session }

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
            completion(.success(.init(consumerSession: LinkAuthStubs.session(secret: session.clientSecret, current: session.currentAuthenticationLevel!, minimum: session.minimumAuthenticationLevel!, factors: session.availableVerificationFactors!, sessions: [.init(type: type == .sms ? .sms : .email, state: .started)]), verificationSessionId: "verification_\(starts.count)")))
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
