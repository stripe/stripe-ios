//
//  ServerDrivenPaymentHandler.swift
//  StripePaymentSheet
//
//  Created by David Estes on 11/10/26.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments

/// Confirms one PaymentIntent for a server-driven payment method and performs its next action, following the
/// server's `ServerDrivenConfirmSpec` instead of `STPPaymentHandler`'s per-type rules.
///
/// PaymentSheet owns the whole payment here, so this skips what `STPPaymentHandler` carries for its public API:
/// 3DS2, QR code and polling screens, vouchers, per-type special cases, and SetupIntents (for now).
/// Everything else in PaymentSheet still confirms with `STPPaymentHandler`.
///
/// It's a small state machine (`State`): each step does at most one API call, redirect or wait, then returns the
/// next state. The API, the redirect UI and the clock are injected so tests can drive it without a network or UIKit.
@MainActor
final class ServerDrivenPaymentHandler {
    enum State {
        /// Confirm the intent client-side, then evaluate the result.
        case confirm(STPPaymentIntentConfirmParams)
        /// Decide what the intent's status means.
        case evaluate(STPPaymentIntent, Progress)
        /// Perform the intent's next action, then fetch it.
        case performNextAction(STPPaymentIntent, Progress)
        /// Wait before fetching the intent again.
        case wait(STPPaymentIntent, Progress)
        /// Retrieve or refresh the intent, then evaluate it.
        case fetch(STPPaymentIntent, Progress)
        case finished(PaymentSheetResult)
    }

    /// What's happened so far in this payment.
    struct Progress: Equatable {
        /// Before a next action, `requires_action` means "perform it". After, the spec says what it means.
        var hasPerformedNextAction = false
        /// Set the first time the spec says to poll.
        var pollDeadline: Date?
        /// Whether a failed fetch was retried while not polling. One retry covers a transient network error.
        var hasRetriedFetch = false
    }

    /// What an intent's status means, given the spec. Pure, so it's tested directly.
    enum Decision: Equatable {
        case succeed
        case fail(FailureReason)
        case cancel
        case performNextAction
        case poll
    }

    enum FailureReason: Equatable {
        /// `requires_payment_method`: confirmation failed, e.g. the customer was declined.
        case paymentFailed
        /// The spec says this status fails, or the status is unknown.
        case unexpectedStatus
    }

    static let pollInterval: TimeInterval = 1
    /// Guards against two server-driven payments at once. See the spike doc for why this doesn't share
    /// `STPPaymentHandler`'s lock.
    private(set) static var isInProgress = false

    let spec: ServerDrivenConfirmSpec
    /// The real payment method type, e.g. "demo_pay", for analytics.
    let paymentMethodType: String
    private let analyticsAPIClient: STPAPIClient
    private let api: ServerDrivenPaymentAPI
    private let redirectPresenter: ServerDrivenRedirectPresenting
    private let clock: ServerDrivenPaymentClock
    private let analyticsClient: STPAnalyticsClientProtocol
    private let actionID = UUID().uuidString
    private var startDate: Date?
    /// Every state the last payment passed through, for tests.
    private(set) var transitions: [State] = []

    init(
        spec: ServerDrivenConfirmSpec,
        paymentMethodType: String,
        apiClient: STPAPIClient,
        api: ServerDrivenPaymentAPI? = nil,
        redirectPresenter: ServerDrivenRedirectPresenting = ServerDrivenRedirectPresenter(),
        clock: ServerDrivenPaymentClock = .live,
        analyticsClient: STPAnalyticsClientProtocol = STPAnalyticsClient.sharedClient
    ) {
        self.spec = spec
        self.paymentMethodType = paymentMethodType
        self.analyticsAPIClient = apiClient
        self.api = api ?? apiClient
        self.redirectPresenter = redirectPresenter
        self.clock = clock
        self.analyticsClient = analyticsClient
    }

    // MARK: - Entry points

    /// Confirms the PaymentIntent client-side and performs any next action.
    func confirm(params: STPPaymentIntentConfirmParams, authenticationContext: STPAuthenticationContext) async -> PaymentSheetResult {
        let params = params.copy() as! STPPaymentIntentConfirmParams
        // Like STPPaymentHandler, so the server returns the same next actions it would to STPPaymentHandler.
        params.useStripeSDK = true
        return await run(from: .confirm(params), authenticationContext: authenticationContext, startedEvent: .paymentHandlerConfirmStarted, finishedEvent: .paymentHandlerConfirmFinished, intentID: params.stripeId)
    }

    /// Performs the next action of a PaymentIntent that was already confirmed, e.g. server-side after a deferred
    /// intent's confirm handler.
    func handleNextAction(for paymentIntent: STPPaymentIntent, authenticationContext: STPAuthenticationContext) async -> PaymentSheetResult {
        return await run(from: .evaluate(paymentIntent, Progress()), authenticationContext: authenticationContext, startedEvent: .paymentHandlerHandleNextActionStarted, finishedEvent: .paymentHandlerHandleNextActionFinished, intentID: paymentIntent.stripeId)
    }

    // MARK: - State machine

    private func run(
        from initialState: State,
        authenticationContext: STPAuthenticationContext,
        startedEvent: STPAnalyticEvent,
        finishedEvent: STPAnalyticEvent,
        intentID: String?
    ) async -> PaymentSheetResult {
        startDate = clock.now()
        transitions = []
        log(startedEvent, intentID: intentID)
        guard !Self.isInProgress else {
            assertionFailure("A server-driven payment was started while another is still in progress.")
            let result = PaymentSheetResult.failed(error: Self.error(.noConcurrentActionsErrorCode))
            log(finishedEvent, intentID: intentID, result: result)
            return result
        }
        Self.isInProgress = true
        defer { Self.isInProgress = false }

        var state = initialState
        var lastIntentID = intentID
        while true {
            transitions.append(state)
            if case .finished(let result) = state {
                log(finishedEvent, intentID: lastIntentID, result: result)
                return result
            }
            state = await step(state, authenticationContext: authenticationContext)
            if case .evaluate(let paymentIntent, _) = state {
                lastIntentID = paymentIntent.stripeId
            }
        }
    }

    func step(_ state: State, authenticationContext: STPAuthenticationContext) async -> State {
        switch state {
        case .confirm(let params):
            do {
                let paymentIntent = try await api.confirm(params)
                return .evaluate(paymentIntent, Progress())
            } catch {
                return .finished(.failed(error: error))
            }

        case .evaluate(let paymentIntent, var progress):
            switch Self.decide(status: paymentIntent.status, hasPerformedNextAction: progress.hasPerformedNextAction, spec: spec) {
            case .succeed:
                return .finished(.completed)
            case .cancel:
                return .finished(.canceled)
            case .fail(let reason):
                return .finished(.failed(error: Self.error(for: reason, paymentIntent: paymentIntent)))
            case .performNextAction:
                return .performNextAction(paymentIntent, progress)
            case .poll:
                let deadline = progress.pollDeadline ?? clock.now().addingTimeInterval(TimeInterval(spec.pollSeconds))
                progress.pollDeadline = deadline
                guard clock.now() < deadline else {
                    return finishAfterPolling(paymentIntent, progress)
                }
                return .wait(paymentIntent, progress)
            }

        case .performNextAction(let paymentIntent, var progress):
            guard
                let nextAction = paymentIntent.nextAction,
                nextAction.type == .redirectToURL,
                spec.nextActions.contains(.redirectToURL),
                let redirect = nextAction.redirectToURL
            else {
                let type = paymentIntent.nextAction?.allResponseFields["type"] as? String ?? "none"
                return .finished(.failed(error: Self.error(.unsupportedAuthenticationErrorCode, loggingSafeErrorMessage: "Unsupported next action \(type) for a server-driven payment method")))
            }
            let redirectResult = await redirectPresenter.redirect(
                to: redirect.url,
                returnURL: redirect.returnURL,
                useWebAuthSession: redirect.useWebAuthSession,
                authenticationContext: authenticationContext,
                didOpen: { [weak self] redirectType in
                    self?.logRedirect(.urlRedirectNextAction, type: redirectType.rawValue)
                }
            )
            switch redirectResult {
            case .returned(let returnType):
                logRedirect(.urlRedirectNextActionCompleted, type: returnType.rawValue)
                progress.hasPerformedNextAction = true
                return .fetch(paymentIntent, progress)
            case .failed(let error):
                return .finished(.failed(error: error))
            }

        case .wait(let paymentIntent, let progress):
            await clock.sleep(Self.pollInterval)
            return .fetch(paymentIntent, progress)

        case .fetch(let paymentIntent, var progress):
            do {
                let fetched = try await fetch(paymentIntent, progress: progress)
                return .evaluate(fetched, progress)
            } catch {
                let canRetry = progress.pollDeadline.map { clock.now() < $0 } ?? !progress.hasRetriedFetch
                guard canRetry else {
                    return .finished(.failed(error: error))
                }
                progress.hasRetriedFetch = true
                return .wait(paymentIntent, progress)
            }

        case .finished:
            stpAssertionFailure("Stepped a finished server-driven payment")
            return state
        }
    }

    /// The decision for an intent status. A `poll` that has run out of time is decided by `finishAfterPolling`.
    nonisolated static func decide(status: STPPaymentIntentStatus, hasPerformedNextAction: Bool, spec: ServerDrivenConfirmSpec) -> Decision {
        switch status {
        case .succeeded, .requiresCapture:
            return .succeed
        case .requiresConfirmation:
            // Like STPPaymentHandler: the merchant confirms on their server (manual confirmation).
            return .succeed
        case .canceled:
            return .cancel
        case .requiresPaymentMethod:
            return .fail(.paymentFailed)
        case .processing:
            switch spec.processing {
            case .succeed: return .succeed
            case .fail: return .fail(.unexpectedStatus)
            case .poll: return .poll
            }
        case .requiresAction:
            guard hasPerformedNextAction else {
                return .performNextAction
            }
            switch spec.requiresAction {
            case .cancel: return .cancel
            case .poll: return .poll
            case .succeed: return .succeed
            }
        case .unknown:
            return .fail(.unexpectedStatus)
        @unknown default:
            return .fail(.unexpectedStatus)
        }
    }

    /// Polling ran out of time: a `processing` intent fails and a `requires_action` intent is canceled, like STPPaymentHandler.
    private func finishAfterPolling(_ paymentIntent: STPPaymentIntent, _ progress: Progress) -> State {
        let duration = progress.pollDeadline.map { clock.now().timeIntervalSince($0) + TimeInterval(spec.pollSeconds) }
        log(.paymentHandlerCanceledPollingDurationExceeded, intentID: paymentIntent.stripeId, duration: duration)
        switch paymentIntent.status {
        case .requiresAction:
            return .finished(.canceled)
        default:
            return .finished(.failed(error: Self.error(.intentStatusErrorCode)))
        }
    }

    private func fetch(_ paymentIntent: STPPaymentIntent, progress: Progress) async throws -> STPPaymentIntent {
        switch spec.retrieval {
        case .retrieve:
            // Like STPPaymentHandler, don't let one request outlast the polling budget, but give the last one a minute.
            let remaining = progress.pollDeadline.map { $0.timeIntervalSince(clock.now()) } ?? 0
            return try await api.retrieve(clientSecret: paymentIntent.clientSecret, timeout: remaining > 0 ? remaining : 60)
        case .refresh:
            return try await api.refresh(clientSecret: paymentIntent.clientSecret)
        }
    }

    // MARK: - Errors

    /// Errors match STPPaymentHandler's domain and codes, so merchants see the same errors for server-driven types.
    nonisolated static func error(_ code: STPPaymentHandlerErrorCode, apiErrorCode: String? = nil, loggingSafeErrorMessage: String? = nil) -> NSError {
        return STPPaymentHandler.sharedHandler._error(for: code, apiErrorCode: apiErrorCode, loggingSafeErrorMessage: loggingSafeErrorMessage)
    }

    private nonisolated static func error(for reason: FailureReason, paymentIntent: STPPaymentIntent) -> NSError {
        switch reason {
        case .paymentFailed:
            guard let lastPaymentError = paymentIntent.lastPaymentError else {
                return error(.paymentErrorCode)
            }
            if lastPaymentError.code == STPPaymentIntentLastPaymentError.ErrorCodeAuthenticationFailure {
                return error(.notAuthenticatedErrorCode)
            }
            return error(.paymentErrorCode, apiErrorCode: lastPaymentError.code)
        case .unexpectedStatus:
            return error(.intentStatusErrorCode)
        }
    }

    // MARK: - Analytics

    /// Uses STPPaymentHandler's event names so dashboards keep working, with the real payment method type and
    /// `handler: server_driven` to tell the two engines apart.
    private func log(_ event: STPAnalyticEvent, intentID: String?, result: PaymentSheetResult? = nil, duration: TimeInterval? = nil) {
        var params: [String: Any] = [
            "action_id": actionID,
            "payment_method_type": paymentMethodType,
            "handler": "server_driven",
        ]
        params["intent_id"] = intentID
        switch result {
        case .completed:
            params["status"] = "succeeded"
        case .canceled:
            params["status"] = "canceled"
        case .failed(let error):
            params["status"] = "failed"
            params.merge(error.serializeForV1Analytics()) { _, new in new }
        case nil:
            break
        }
        if result != nil {
            params["duration"] = startDate.map { clock.now().timeIntervalSince($0) }
        }
        if let duration {
            params["duration"] = duration
        }
        analyticsClient.log(analytic: GenericAnalytic(event: event, params: params), apiClient: analyticsAPIClient)
    }

    private func logRedirect(_ event: STPAnalyticEvent, type: String) {
        let params: [String: Any] = ["redirect_type": type, "action_id": actionID, "handler": "server_driven"]
        analyticsClient.log(analytic: GenericAnalytic(event: event, params: params), apiClient: analyticsAPIClient)
    }
}

// MARK: - Dependencies

/// The Stripe API calls `ServerDrivenPaymentHandler` makes. `STPAPIClient` conforms; tests stub it.
protocol ServerDrivenPaymentAPI {
    func confirm(_ params: STPPaymentIntentConfirmParams) async throws -> STPPaymentIntent
    func retrieve(clientSecret: String, timeout: TimeInterval) async throws -> STPPaymentIntent
    func refresh(clientSecret: String) async throws -> STPPaymentIntent
}

extension STPAPIClient: ServerDrivenPaymentAPI {
    func confirm(_ params: STPPaymentIntentConfirmParams) async throws -> STPPaymentIntent {
        return try await confirmPaymentIntent(with: params, expand: ["payment_method"])
    }

    func retrieve(clientSecret: String, timeout: TimeInterval) async throws -> STPPaymentIntent {
        return try await withCheckedThrowingContinuation { continuation in
            retrievePaymentIntent(withClientSecret: clientSecret, expand: ["payment_method"], timeout: NSNumber(value: timeout)) { paymentIntent, error in
                guard let paymentIntent else {
                    continuation.resume(throwing: error ?? NSError.stp_genericFailedToParseResponseError())
                    return
                }
                continuation.resume(returning: paymentIntent)
            }
        }
    }

    func refresh(clientSecret: String) async throws -> STPPaymentIntent {
        return try await withCheckedThrowingContinuation { continuation in
            refreshPaymentIntent(withClientSecret: clientSecret) { paymentIntent, error in
                guard let paymentIntent else {
                    continuation.resume(throwing: error ?? NSError.stp_genericFailedToParseResponseError())
                    return
                }
                continuation.resume(returning: paymentIntent)
            }
        }
    }
}

/// The time source for polling. Tests replace it so polling doesn't actually wait.
struct ServerDrivenPaymentClock {
    var now: () -> Date
    var sleep: (TimeInterval) async -> Void

    static let live = ServerDrivenPaymentClock(
        now: { Date() },
        sleep: { seconds in try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000)) }
    )
}
