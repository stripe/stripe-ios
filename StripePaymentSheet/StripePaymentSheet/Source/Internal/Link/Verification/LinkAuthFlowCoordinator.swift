// Copyright © 2026 Stripe, Inc. All rights reserved.

import Foundation
@_spi(STP) import StripeCore

protocol LinkAuthAccount: AnyObject {
    var currentSession: ConsumerSession? { get }
    var sessionState: PaymentSheetLinkAccount.SessionState { get }
    var authLookupSettings: ConsumerSession.LookupSettings? { get }
    var useMobileEndpoints: Bool { get }
    var visitedFallbackURLs: [URL] { get set }

    func applyAuthResponse(_ response: ConsumerSession.AuthResponse)
    func startAuthVerification(
        type: SupportedVerificationType,
        phoneNumber: String?,
        isResending: Bool,
        completion: @escaping (Result<ConsumerSession.AuthResponse, Error>) -> Void
    )
    func confirmAuthVerification(
        type: SupportedVerificationType,
        code: String,
        consentGranted: Bool?,
        completion: @escaping (Result<ConsumerSession.AuthResponse, Error>) -> Void
    )
    func refreshAuthSession(
        recoverCredentials: Bool,
        completion: @escaping (Result<ConsumerSession.AuthResponse, Error>) -> Void
    )
}

enum LinkVerificationResult {
    case completed
    case canceled
    case switchAccount
    case failed(Error)
}

/// Coordinates one authentication attempt independently of its presentation.
@MainActor
final class LinkAuthFlowCoordinator {
    enum Screen: Equatable {
        case loading
        case otp
        case phoneMatch
        case blocked
        case webHandoff
    }

    enum Action {
        case resend
        case email
    }

    struct Challenge {
        let type: SupportedVerificationType
        let factorID: String?
        var phoneNumber: String?
        var verificationSessionID: String?
        var resendDeadline: Date?
        var isStarted = false
    }

    private struct Route {
        let screen: Screen
        let challenge: Challenge?
    }

    private let account: LinkAuthAccount
    private let capabilities: [SupportedVerificationType]
    private let now: () -> Date
    private let consentGranted: Bool?
    private var history: [Route] = []
    private var previousChallenges: [SupportedVerificationType: Challenge] = [:]
    private var didStart = false
    private var finished = false
    private var generation = 0
    private var refreshedFallbackURL = false
    private var completedWebHandoff = false

    private(set) var screen: Screen = .loading
    private(set) var challenge: Challenge?
    private(set) var step = 1
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var inputRevision = 0
    private(set) var resendCount = 0

    var onUpdate: (() -> Void)?
    var onFinish: ((LinkVerificationResult) -> Void)?
    var onWebHandoff: ((URL) -> Void)?

    init(
        account: LinkAuthAccount,
        capabilities: [SupportedVerificationType] = SupportedVerificationType.nativeCapabilities,
        consentGranted: Bool? = nil,
        now: @escaping () -> Date = Date.init
    ) {
        self.account = account
        self.capabilities = capabilities
        self.consentGranted = consentGranted
        self.now = now
    }

    var showsBackButton: Bool {
        step == 1 && !history.isEmpty
    }

    var canGoBack: Bool {
        showsBackButton && !isLoading
    }

    var canSubmitCode: Bool {
        screen == .otp && challenge?.isStarted == true && !isLoading && !finished
    }

    var resendSecondsRemaining: Int {
        max(0, Int(ceil((challenge?.resendDeadline ?? .distantPast).timeIntervalSince(now()))))
    }

    var canResend: Bool {
        didStart && screen == .otp && !isLoading && !finished && resendSecondsRemaining == 0
    }

    /// Keep the initial OTP action in its loading state while presentation defers the first request.
    var isLoadingOTP: Bool {
        screen == .otp && !finished && (!didStart || isLoading)
    }

    var actions: [Action] {
        guard screen == .otp else { return [] }
        var actions: [Action] = [.resend]
        if step == 1, challenge?.type == .sms, factor(for: .email) != nil {
            actions.append(.email)
        }
        return actions
    }

    var recipient: String {
        if challenge?.type == .email {
            return account.currentSession?.emailAddress ?? ""
        }
        let phoneNumber = account.currentSession?.redactedFormattedPhoneNumber
        return phoneNumber?.replacingOccurrences(of: "*", with: "•") ?? ""
    }

    /// Selects the initial UI from the current lookup without sending requests or opening web auth.
    func prepare() {
        guard !didStart, !finished else { return }
        advance()
    }

    func start() {
        guard !didStart, !finished else { return }
        didStart = true
        STPAnalyticsClient.sharedClient.logLink2FAStart()
        advance()
    }

    func cancel(switchAccount: Bool = false) {
        guard !finished else { return }
        STPAnalyticsClient.sharedClient.logLink2FACancel()
        finish(switchAccount ? .switchAccount : .canceled)
    }

    func goBack() {
        guard canGoBack, let route = history.popLast() else { return }
        generation += 1
        screen = route.screen
        challenge = route.challenge
        resetInput()
        onUpdate?()
    }

    func sendToEmail() {
        guard didStart, !isLoading, !finished, actions
            .contains(.email), let factor = factor(for: .email) else { return }
        history.append(Route(screen: screen, challenge: challenge))
        select(factor)
    }

    func submitPhoneNumber(_ phoneNumber: String) {
        guard didStart, screen == .phoneMatch, !isLoading, !finished else { return }
        challenge?.phoneNumber = phoneNumber
        sendCode(isResending: false)
    }

    func resend() {
        guard canResend else { return }
        STPAnalyticsClient.sharedClient.logLink2FAResendCode()
        sendCode(isResending: true)
    }

    func confirm(code: String) {
        guard canSubmitCode, let challenge else { return }
        request(
            { completion in
                self.account.confirmAuthVerification(
                    type: challenge.type,
                    code: code,
                    consentGranted: self.consentGranted,
                    completion: completion
                )
        }) { result in
            switch result {
            case .success:
                self.step += 1
                self.history.removeAll()
                self.previousChallenges.removeAll()
                self.resetInput()
                self.advance(previous: challenge.type)
            case .failure(let error):
                STPAnalyticsClient.sharedClient.logLink2FAFailure()
                self.resetInput()
                self.errorMessage = LinkUtils.getLocalizedErrorMessage(from: error)
                let errorCode = error._stp_error_code.flatMap(LinkUtils.ConsumerErrorCode.init(rawValue:))
                switch errorCode {
                case .consumerVerificationExpired, .consumerVerificationNotFound:
                    self.challenge?.isStarted = false
                    self.previousChallenges[challenge.type]?.isStarted = false
                    self.sendCode(isResending: false)
                    return
                case .consumerVerificationMaxAttemptsExceeded:
                    self.challenge?.isStarted = false
                    self.previousChallenges[challenge.type]?.isStarted = false
                default:
                    break
                }
                self.onUpdate?()
            }
        }
    }

    func webHandoffFinished(_ result: LinkVerificationResult) {
        guard !finished, screen == .webHandoff else { return }
        switch result {
        case .completed:
            completedWebHandoff = true
            request(
                { completion in
                    self.account.refreshAuthSession(
                        recoverCredentials: false,
                        completion: completion
                    )
            }) { result in
                switch result {
                case .success: self.advance()
                case .failure(let error): self.block(error.localizedDescription)
                }
            }
        case .canceled, .switchAccount, .failed:
            finish(result)
        }
    }

    private func factor(for type: SupportedVerificationType) -> ConsumerSession.VerificationFactor? {
        guard capabilities.contains(type) else { return nil }
        if let factors = account.currentSession?.availableVerificationFactors {
            return factors.first { $0.isStartable && $0.type.verificationType == type }
        }
        // Legacy endpoints predate the factor list and only support SMS.
        if !account.useMobileEndpoints, type == .sms {
            return .init(
                type: .sms,
                providesFurtherVerification: true,
                temporarilyDisabled: false,
                id: nil
            )
        }
        return nil
    }

    private func advance(previous: SupportedVerificationType? = nil) {
        guard !finished else { return }
        if account.sessionState == .verified {
            guard didStart else {
                screen = .loading
                onUpdate?()
                return
            }
            STPAnalyticsClient.sharedClient.logLink2FAComplete()
            finish(.completed)
            return
        }
        if account.currentSession?.mobileFallbackWebviewParams?.webviewRequirementType == .required {
            guard didStart else {
                screen = .webHandoff
                onUpdate?()
                return
            }
            handoffToWeb()
            return
        }
        let order: [SupportedVerificationType] = previous == .sms ? [.email, .sms] : [.sms, .email]
        guard let factor = order.compactMap({ factor(for: $0) }).first else {
            block()
            return
        }
        // A legacy response has no advancement information; don't loop on the same identifier.
        if previous != nil, account.currentSession?.availableVerificationFactors == nil {
            block()
            return
        }
        select(factor)
    }

    private func select(_ factor: ConsumerSession.VerificationFactor) {
        guard let type = factor.type.verificationType else { return }
        if let previous = previousChallenges[type], previous.factorID == factor.id, previous.isStarted {
            challenge = previous
            screen = .otp
            resetInput()
            onUpdate?()
            return
        }
        challenge = Challenge(type: type, factorID: factor.id)
        resetInput()
        if type == .email, account.authLookupSettings?.emailOtpRequiresAdditionalInfo != false {
            screen = .phoneMatch
            onUpdate?()
        } else {
            screen = .otp
            if didStart {
                sendCode(isResending: false)
            } else {
                onUpdate?()
            }
        }
    }

    private func sendCode(isResending: Bool) {
        guard let challenge, !isLoading, !finished else { return }
        let previousScreen = screen
        errorMessage = nil
        request(
            { completion in
                self.account.startAuthVerification(
                    type: challenge.type,
                    phoneNumber: challenge.phoneNumber,
                    isResending: isResending,
                    completion: completion
                )
        }) { result in
            switch result {
            case .success(let response):
                if self.account.sessionState == .verified || response.consumerSession.mobileFallbackWebviewParams?.webviewRequirementType == .required {
                    self.advance()
                    return
                }
                self.challenge?.verificationSessionID = response.verificationSessionId
                self.challenge?.isStarted = response.consumerSession.verificationSessions.contains {
                    $0.type.rawValue == challenge.type.rawValue && $0.state == .started
                }
                if self.challenge?.isStarted != true {
                    self.block()
                    return
                }
                if previousScreen == .phoneMatch, self.step == 1 {
                    self.history.append(Route(screen: .phoneMatch, challenge: self.challenge))
                }
                self.screen = .otp
                self.resetInput()
                if isResending {
                    self.resendCount += 1
                    self.challenge?.resendDeadline = self.now().addingTimeInterval(10)
                }
                self.previousChallenges[challenge.type] = self.challenge
                self.onUpdate?()
            case .failure(let error):
                STPAnalyticsClient.sharedClient.logLink2FAStartFailure()
                if challenge.type == .email, ["phone_number_missing", "phone_number_mismatch"].contains(error._stp_error_code ?? "") {
                    self.screen = .phoneMatch
                    self.challenge?.isStarted = false
                }
                self.errorMessage = LinkUtils.getLocalizedErrorMessage(from: error)
                self.onUpdate?()
            }
        }
    }

    private func handoffToWeb() {
        guard !completedWebHandoff else {
            block()
            return
        }
        if let url = account.currentSession?.mobileFallbackWebviewParams?.webviewOpenUrl,
           !account.visitedFallbackURLs.contains(url) {
            screen = .webHandoff
            account.visitedFallbackURLs.append(url)
            onUpdate?()
            onWebHandoff?(url)
        } else if !refreshedFallbackURL {
            refreshedFallbackURL = true
            request({ completion in
                self.account.refreshAuthSession(recoverCredentials: false, completion: completion)
            }) { result in
                switch result {
                case .success: self.advance()
                case .failure(let error): self.block(error.localizedDescription)
                }
            }
        } else {
            block()
        }
    }

    private func resetInput() {
        inputRevision += 1
        errorMessage = nil
    }

    private func block(_ message: String? = nil) {
        screen = .blocked
        errorMessage = message ?? STPLocalizedString("We couldn't verify your account. Please close this window and try again.", "Link authentication cannot continue with the available verification methods.")
        isLoading = false
        history.removeAll()
        onUpdate?()
    }

    private func finish(_ result: LinkVerificationResult) {
        guard !finished else { return }
        finished = true
        generation += 1
        isLoading = false
        history.removeAll()
        challenge = nil
        previousChallenges.removeAll()
        onFinish?(result)
    }

    private typealias Request = (@escaping (Result<ConsumerSession.AuthResponse, Error>) -> Void) -> Void

    private func request(_ operation: @escaping Request, completion: @escaping (Result<ConsumerSession.AuthResponse, Error>) -> Void) {
        guard didStart, !finished, !isLoading else { return }
        isLoading = true
        onUpdate?()
        let requestGeneration = generation
        execute(
            operation,
            generation: requestGeneration,
            originalError: nil,
            completion: completion
        )
    }

    private func execute(
        _ operation: @escaping Request,
        generation requestGeneration: Int,
        originalError: Error?,
        completion: @escaping (Result<ConsumerSession.AuthResponse, Error>) -> Void
    ) {
        operation { [weak self] result in
            DispatchQueue.main.async {
                guard let self, !self.finished, self.generation == requestGeneration else { return }
                if case .failure(let error) = result, error._stp_error_code == "consumer_session_expired" || error._stp_error_code == "consumer_session_credentials_invalid", originalError == nil {
                    self.account.refreshAuthSession(recoverCredentials: true) { [weak self] refreshResult in
                        DispatchQueue.main.async {
                            guard let self, !self.finished, self.generation == requestGeneration else { return }
                            switch refreshResult {
                            case .success(let response):
                                self.account.applyAuthResponse(response)
                                self.execute(
                                    operation,
                                    generation: requestGeneration,
                                    originalError: error,
                                    completion: completion
                                )
                            case .failure:
                                self.finish(.failed(error))
                            }
                        }
                    }
                    return
                }
                self.isLoading = false
                if case .success(let response) = result {
                    self.account.applyAuthResponse(response)
                } else if let originalError {
                    self.finish(.failed(originalError))
                    return
                }
                completion(result)
            }
        }
    }
}
