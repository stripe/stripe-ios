//
//  PaymentConfirmer.swift
//  StripePaymentSheet
//
//  Created by David Estes on 11/10/26.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments

/// Confirms one PaymentIntent or SetupIntent and finishes the payment, following the payment method's
/// `ConfirmationMetadata` (a server-driven payment method's description, or the session's served entry for a native type)
/// instead of STPPaymentHandler's per-type rules.
///
/// Every next action is one of five primitives, performed by a `NextActionPerforming`:
/// - a redirect: a web view or another app, then the customer comes back;
/// - a polling screen, optionally behind an instructions web view;
/// - nothing to do (the outcome is known: vouchers once shown, microdeposits);
/// - no next action at all (only the status rules apply);
/// - `use_stripe_sdk` (3DS2, 3DS redirect, the intent confirmation challenge) and every next action of a type whose
///   client constants say `performer: stripePaymentHandler` (card, Link): handed to `STPPaymentHandler.handleNextAction(for:)`,
///   which then owns the rest of the payment.
///
/// It's a small state machine (`State`): each step does at most one API call, next action or wait. The API, the
/// performer and the clock are injected, so tests and the parity harness drive the real code with no network or UIKit.
@MainActor
final class PaymentConfirmer {
    enum State {
        /// Confirm the intent client-side, then evaluate the result.
        case confirm(ConfirmingParams)
        /// Decide what the intent's status means.
        case evaluate(ConfirmingIntent, Progress)
        /// Perform the intent's next action.
        case performNextAction(ConfirmingIntent, Progress)
        /// Let the next action's screen (PayNow's, PromptPay's and Pix's polling screen) finish the payment.
        case awaitNextActionScreen(ConfirmingIntent, Progress)
        /// Wait before fetching the intent again.
        case wait(ConfirmingIntent, Progress)
        /// Retrieve or refresh the intent, then evaluate it.
        case fetch(ConfirmingIntent, Progress)
        case finished(PaymentSheetResult, ConfirmingIntent?)
    }

    /// What's happened so far in this payment.
    struct Progress: Equatable {
        /// Before a next action, `requires_action` means "perform it". After, the metadata says what it means.
        var hasPerformedNextAction = false
        /// Whether the customer closed the in-app browser themselves (the metadata's `afterWebViewDismissed`).
        var webViewDismissed = false
        /// Set the first time the metadata says to poll. One deadline for the rest of the payment, like STPPaymentHandler.
        var pollDeadline: Date?
        /// The budget the deadline was set from, for analytics.
        var pollSeconds: Int?
        /// Whether a failed fetch was retried while not polling. One retry covers a transient network error.
        var hasRetriedFetch = false
    }

    /// The payment's result, and the intent it ended with (for setting the default payment method).
    struct Outcome {
        let result: PaymentSheetResult
        let intent: ConfirmingIntent?
    }

    static let pollInterval: TimeInterval = 1
    /// The value of the `handler` analytics param, which tells this engine's events from STPPaymentHandler's.
    static let analyticsHandler = "paymentsheet_engine"
    /// The value of the `spec_source` analytics param. Every policy comes from the server: a server-driven payment
    /// method's description or a served `payment_method_confirmations` entry.
    static let analyticsSpecSource = "server"
    /// Guards against two payments at once. It doesn't share STPPaymentHandler's lock (that's private); see the doc.
    private(set) static var isInProgress = false

    let metadata: ConfirmationMetadata
    /// The real payment method type, e.g. "ideal" or "demo_pay", for analytics.
    let paymentMethodType: String
    private let analyticsAPIClient: STPAPIClient
    private let api: PaymentConfirmerAPI
    private let performer: NextActionPerforming
    private let clock: PaymentConfirmerClock
    private let analyticsClient: STPAnalyticsClientProtocol
    let actionID = UUID().uuidString
    private var startDate: Date?
    /// The confirm request's `return_url` (or, for an intent confirmed elsewhere, PaymentSheet's `returnURL`).
    private var returnURL: String?
    /// A next action screen that's still showing after its web view closed.
    private var pendingScreen: NextActionScreen?
    /// The presenter of the last next action performed, for analytics.
    private var presenter: String?
    /// Every state the last payment passed through, for tests.
    private(set) var transitions: [State] = []

    init(
        metadata: ConfirmationMetadata,
        paymentMethodType: String,
        apiClient: STPAPIClient,
        performer: NextActionPerforming,
        api: PaymentConfirmerAPI? = nil,
        clock: PaymentConfirmerClock = .live,
        analyticsClient: STPAnalyticsClientProtocol = STPAnalyticsClient.sharedClient
    ) {
        self.metadata = metadata
        self.paymentMethodType = paymentMethodType
        self.analyticsAPIClient = apiClient
        self.api = api ?? apiClient
        self.performer = performer
        self.clock = clock
        self.analyticsClient = analyticsClient
    }

    // MARK: - Entry points

    /// Confirms the intent client-side and finishes the payment.
    func confirm(_ params: ConfirmingParams, authenticationContext: STPAuthenticationContext) async -> Outcome {
        // Like STPPaymentHandler, so the server returns the same next actions it would to STPPaymentHandler.
        let params = params.withUseStripeSDK()
        returnURL = params.returnURL
        return await run(from: .confirm(params), authenticationContext: authenticationContext, startedEvent: .paymentHandlerConfirmStarted, finishedEvent: .paymentHandlerConfirmFinished, intentID: params.intentID, paymentMethodID: params.paymentMethodID)
    }

    /// Finishes the payment for an intent that was already confirmed, e.g. server-side after a deferred intent's
    /// confirm handler.
    func handleNextAction(for intent: ConfirmingIntent, returnURL: String?, authenticationContext: STPAuthenticationContext) async -> Outcome {
        self.returnURL = returnURL
        // Like STPPaymentHandler.handleNextAction(for:): a `requires_confirmation` intent should have been confirmed first.
        guard intent.status != .requiresConfirmation else {
            let error = Self.error(.intentStatusErrorCode, loggingSafeErrorMessage: "Confirm the intent on the backend before handling its next action.")
            return await run(from: .finished(.failed(error: error), intent), authenticationContext: authenticationContext, startedEvent: .paymentHandlerHandleNextActionStarted, finishedEvent: .paymentHandlerHandleNextActionFinished, intentID: intent.stripeID, paymentMethodID: intent.paymentMethod?.stripeId)
        }
        return await run(from: .evaluate(intent, Progress()), authenticationContext: authenticationContext, startedEvent: .paymentHandlerHandleNextActionStarted, finishedEvent: .paymentHandlerHandleNextActionFinished, intentID: intent.stripeID, paymentMethodID: intent.paymentMethod?.stripeId)
    }

    // MARK: - State machine

    private func run(
        from initialState: State,
        authenticationContext: STPAuthenticationContext,
        startedEvent: STPAnalyticEvent,
        finishedEvent: STPAnalyticEvent,
        intentID: String?,
        paymentMethodID: String?
    ) async -> Outcome {
        startDate = clock.now()
        transitions = []
        presenter = nil
        log(startedEvent, intentID: intentID, paymentMethodID: paymentMethodID)
        guard !Self.isInProgress else {
            assertionFailure("A PaymentSheet payment was started while another is still in progress.")
            let result = PaymentSheetResult.failed(error: Self.error(.noConcurrentActionsErrorCode))
            log(finishedEvent, intentID: intentID, paymentMethodID: paymentMethodID, result: result)
            return Outcome(result: result, intent: nil)
        }
        Self.isInProgress = true
        defer { Self.isInProgress = false }

        var state = initialState
        var lastIntentID = intentID
        while true {
            transitions.append(state)
            if case .finished(let result, let intent) = state {
                pendingScreen?.stop(dismiss: result.paymentHandlerStatus != .succeeded)
                pendingScreen = nil
                log(finishedEvent, intentID: lastIntentID, paymentMethodID: intent?.paymentMethod?.stripeId ?? paymentMethodID, result: result)
                return Outcome(result: result, intent: intent)
            }
            state = await step(state, authenticationContext: authenticationContext)
            if case .evaluate(let intent, _) = state {
                lastIntentID = intent.stripeID
            }
        }
    }

    func step(_ state: State, authenticationContext: STPAuthenticationContext) async -> State {
        switch state {
        case .confirm(let params):
            do {
                let intent = try await api.confirmIntent(params)
                return .evaluate(intent, Progress())
            } catch {
                return .finished(.failed(error: error), nil)
            }

        case .evaluate(let intent, var progress):
            let pollExpired = progress.pollDeadline.map { clock.now() >= $0 } ?? false
            let decision = metadata.decide(situation(for: intent, progress: progress, pollExpired: pollExpired))
            switch decision {
            case .succeed:
                return .finished(.completed, intent)
            case .cancel:
                if pollExpired, intent.status == .requiresAction {
                    // Like STPPaymentHandler: log a cancel because polling ran out while the customer hadn't finished.
                    log(.paymentHandlerCanceledPollingDurationExceeded, intentID: intent.stripeID, paymentMethodID: nil, duration: progress.pollSeconds.map(TimeInterval.init))
                }
                return .finished(.canceled, intent)
            case .fail(let reason):
                if reason == .unsupportedNextAction {
                    logUnsupportedNextAction(intent)
                }
                return .finished(.failed(error: Self.error(for: reason, intent: intent)), intent)
            case .performNextAction:
                return .performNextAction(intent, progress)
            case .poll(let seconds):
                if progress.pollDeadline == nil {
                    progress.pollDeadline = clock.now().addingTimeInterval(TimeInterval(seconds))
                    progress.pollSeconds = seconds
                }
                return .wait(intent, progress)
            case .waitForNextActionScreen:
                guard pendingScreen != nil else {
                    // STPPaymentHandler never finishes here (SPH:1708) and waits for a screen that doesn't exist.
                    return .finished(.canceled, intent)
                }
                return .awaitNextActionScreen(intent, progress)
            }

        case .performNextAction(let intent, var progress):
            let resolved: ResolvedNextAction
            do {
                resolved = try ResolvedNextAction(intent: intent, metadata: metadata, confirmReturnURL: returnURL)
            } catch {
                if (error as NSError).code == STPPaymentHandlerErrorCode.unsupportedAuthenticationErrorCode.rawValue {
                    logUnsupportedNextAction(intent)
                }
                return .finished(.failed(error: error), intent)
            }
            presenter = resolved.analyticsName
            let outcome = await performer.perform(
                resolved,
                intent: intent,
                returnURL: returnURL,
                actionID: actionID,
                authenticationContext: authenticationContext,
                poll: { [weak self] in await self?.pollForScreen(intent) },
                didOpen: { [weak self] redirectType in
                    self?.logRedirect(.urlRedirectNextAction, type: redirectType.rawValue)
                }
            )
            switch outcome {
            case .returned(let returnType, let screen):
                logRedirect(.urlRedirectNextActionCompleted, type: returnType.rawValue)
                progress.hasPerformedNextAction = true
                progress.webViewDismissed = returnType == .safariViewController
                pendingScreen = screen
                return .fetch(intent, progress)
            case .performed:
                progress.hasPerformedNextAction = true
                return .evaluate(intent, progress)
            case .finished(let result, let finalIntent):
                return .finished(result, finalIntent ?? intent)
            }

        case .awaitNextActionScreen(let intent, _):
            guard let screen = pendingScreen else {
                return .finished(.canceled, intent)
            }
            let (result, finalIntent) = await screen.result()
            pendingScreen = nil
            return .finished(result, finalIntent ?? intent)

        case .wait(let intent, let progress):
            await clock.sleep(Self.pollInterval)
            return .fetch(intent, progress)

        case .fetch(let intent, var progress):
            do {
                let fetched = try await fetch(intent, progress: progress)
                return .evaluate(fetched, progress)
            } catch {
                // STPPaymentHandler retries forever while it isn't polling (L11 in the table doc); this retries once.
                let canRetry = progress.pollDeadline.map { clock.now() < $0 } ?? !progress.hasRetriedFetch
                guard canRetry else {
                    return .finished(.failed(error: error), intent)
                }
                progress.hasRetriedFetch = true
                return .wait(intent, progress)
            }

        case .finished:
            stpAssertionFailure("Stepped a finished payment")
            return state
        }
    }

    private func situation(for intent: ConfirmingIntent, progress: Progress, pollExpired: Bool) -> ConfirmationMetadata.Situation {
        return ConfirmationMetadata.Situation(
            intent: intent.kind,
            status: intent.status,
            nextActionType: intent.nextActionType,
            phase: progress.hasPerformedNextAction ? .afterNextAction(webViewDismissed: progress.webViewDismissed) : .afterConfirm,
            pollExpired: pollExpired
        )
    }

    private func fetch(_ intent: ConfirmingIntent, progress: Progress) async throws -> ConfirmingIntent {
        // `retrieval` is how to read the intent after a next action, like STPPaymentHandler's refresh for Cash App and
        // Klarna. Before one, e.g. polling a `processing` intent right after confirmation, retrieve it.
        guard progress.hasPerformedNextAction else {
            return try await api.fetchIntent(intent, retrieval: .retrieve, timeout: remainingBudget(progress))
        }
        // Unlike STPPaymentHandler (STPPaymentHandler.swift:1597), there's no Alipay "Marlin" ping before the read:
        // Alipay PaymentIntents run on Alipay+ (EVO), where the ping is a no-op.
        return try await api.fetchIntent(intent, retrieval: metadata.retrieval, timeout: remainingBudget(progress))
    }

    /// Like STPPaymentHandler, don't let one request outlast the polling budget, but give the last one a minute.
    private func remainingBudget(_ progress: Progress) -> TimeInterval {
        let remaining = progress.pollDeadline.map { $0.timeIntervalSince(clock.now()) } ?? 0
        return remaining > 0 ? remaining : 60
    }

    /// One read for a polling screen. The screen keeps its own schedule; this only reads.
    private func pollForScreen(_ intent: ConfirmingIntent) async -> ConfirmingIntent? {
        return try? await api.fetchIntent(intent, retrieval: .retrieve, timeout: nil)
    }

    // MARK: - Errors

    /// Errors use STPPaymentHandler's domain and codes, so merchants see the same errors whichever engine ran.
    nonisolated static func error(_ code: STPPaymentHandlerErrorCode, apiErrorCode: String? = nil, loggingSafeErrorMessage: String? = nil, localizedDescription: String? = nil) -> NSError {
        return STPPaymentHandler.sharedHandler._error(for: code, apiErrorCode: apiErrorCode, loggingSafeErrorMessage: loggingSafeErrorMessage, localizedDescription: localizedDescription)
    }

    /// The same mapping as STPPaymentHandler's `_handlePaymentIntentStatus` and `_handleSetupIntentStatus`.
    nonisolated static func error(for reason: ConfirmationMetadata.FailureReason, intent: ConfirmingIntent) -> NSError {
        switch reason {
        case .paymentFailed:
            switch intent {
            case .paymentIntent(let paymentIntent):
                guard let lastPaymentError = paymentIntent.lastPaymentError else {
                    return error(.paymentErrorCode)
                }
                if lastPaymentError.code == STPPaymentIntentLastPaymentError.ErrorCodeAuthenticationFailure {
                    return error(.notAuthenticatedErrorCode)
                }
                if lastPaymentError.type == .card {
                    return error(.paymentErrorCode, apiErrorCode: lastPaymentError.code, localizedDescription: lastPaymentError.message)
                }
                return error(.paymentErrorCode, apiErrorCode: lastPaymentError.code)
            case .setupIntent(let setupIntent):
                guard let lastSetupError = setupIntent.lastSetupError else {
                    return error(.paymentErrorCode)
                }
                if lastSetupError.code == STPSetupIntentLastSetupError.CodeAuthenticationFailure {
                    return error(.notAuthenticatedErrorCode)
                }
                if lastSetupError.type == .card {
                    return error(.paymentErrorCode, apiErrorCode: lastSetupError.code, localizedDescription: lastSetupError.message)
                }
                return error(.paymentErrorCode, apiErrorCode: lastSetupError.code)
            }
        case .requiresPaymentMethod:
            return error(.requiresPaymentMethodErrorCode)
        case .unexpectedStatus:
            if intent.status == .unknown {
                return error(.unexpectedErrorCode, loggingSafeErrorMessage: "Unknown intent status")
            }
            return error(.intentStatusErrorCode)
        case .unsupportedNextAction:
            return error(.unsupportedAuthenticationErrorCode, loggingSafeErrorMessage: "Unsupported next action \(intent.nextActionType ?? "none")")
        case .unsupportedIntent:
            return error(.unexpectedErrorCode, loggingSafeErrorMessage: "This payment method can't be set up")
        }
    }

    // MARK: - Analytics

    /// STPPaymentHandler's event names, so dashboards keep working, with the real payment method type and
    /// `handler: paymentsheet_engine` to tell the engines apart.
    private func log(_ event: STPAnalyticEvent, intentID: String?, paymentMethodID: String?, result: PaymentSheetResult? = nil, duration: TimeInterval? = nil) {
        var params: [String: Any] = [
            "action_id": actionID,
            "payment_method_type": paymentMethodType,
            "handler": Self.analyticsHandler,
            "spec_source": Self.analyticsSpecSource,
        ]
        params["intent_id"] = intentID
        params["payment_method_id"] = paymentMethodID
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
            params["presenter"] = presenter
        }
        if let duration {
            params["duration"] = duration
        }
        analyticsClient.log(analytic: GenericAnalytic(event: event, params: params), apiClient: analyticsAPIClient)
    }

    /// A type handles only the next actions its entry lists. The server vends the table, so another one is a gap in the
    /// server's entry, not in the SDK: report it as an unexpected error (which alerts) with the type and the next action.
    private func logUnsupportedNextAction(_ intent: ConfirmingIntent) {
        let nextActionType = intent.nextActionType ?? "none"
        let error = Self.error(.unsupportedAuthenticationErrorCode, loggingSafeErrorMessage: "Unsupported next action \(nextActionType)")
        let analytic = ErrorAnalytic(event: .unexpectedPaymentSheetConfirmationError, error: error, additionalNonPIIParams: [
            "action_id": actionID,
            "payment_method_type": paymentMethodType,
            "next_action_type": nextActionType,
            "intent_id": intent.stripeID,
            "handler": Self.analyticsHandler,
            "spec_source": Self.analyticsSpecSource,
        ])
        analyticsClient.log(analytic: analytic, apiClient: analyticsAPIClient)
    }

    private func logRedirect(_ event: STPAnalyticEvent, type: String) {
        let params: [String: Any] = ["redirect_type": type, "action_id": actionID, "handler": Self.analyticsHandler]
        analyticsClient.log(analytic: GenericAnalytic(event: event, params: params), apiClient: analyticsAPIClient)
    }
}

// MARK: - Intents

/// The intent `PaymentConfirmer` is finishing.
enum ConfirmingIntent {
    case paymentIntent(STPPaymentIntent)
    case setupIntent(STPSetupIntent)

    var kind: ConfirmationMetadata.IntentKind {
        switch self {
        case .paymentIntent: return .paymentIntent
        case .setupIntent: return .setupIntent
        }
    }

    /// The status in PaymentIntent terms, which `ConfirmationMetadata.decide` takes for both kinds.
    var status: STPPaymentIntentStatus {
        switch self {
        case .paymentIntent(let paymentIntent):
            return paymentIntent.status
        case .setupIntent(let setupIntent):
            switch setupIntent.status {
            case .requiresPaymentMethod: return .requiresPaymentMethod
            case .requiresConfirmation: return .requiresConfirmation
            case .requiresAction: return .requiresAction
            case .processing: return .processing
            case .succeeded: return .succeeded
            case .canceled: return .canceled
            case .unknown: return .unknown
            @unknown default: return .unknown
            }
        }
    }

    var nextAction: STPIntentAction? {
        switch self {
        case .paymentIntent(let paymentIntent): return paymentIntent.nextAction
        case .setupIntent(let setupIntent): return setupIntent.nextAction
        }
    }

    /// The API's `next_action[type]`, e.g. "redirect_to_url".
    var nextActionType: String? {
        return nextAction?.allResponseFields["type"] as? String
    }

    var clientSecret: String {
        switch self {
        case .paymentIntent(let paymentIntent): return paymentIntent.clientSecret
        case .setupIntent(let setupIntent): return setupIntent.clientSecret
        }
    }

    var stripeID: String {
        switch self {
        case .paymentIntent(let paymentIntent): return paymentIntent.stripeId
        case .setupIntent(let setupIntent): return setupIntent.stripeID
        }
    }

    var paymentMethod: STPPaymentMethod? {
        switch self {
        case .paymentIntent(let paymentIntent): return paymentIntent.paymentMethod
        case .setupIntent(let setupIntent): return setupIntent.paymentMethod
        }
    }

    var paymentIntent: STPPaymentIntent? {
        guard case .paymentIntent(let paymentIntent) = self else { return nil }
        return paymentIntent
    }

    var setupIntent: STPSetupIntent? {
        guard case .setupIntent(let setupIntent) = self else { return nil }
        return setupIntent
    }

    /// How the polling screen reads the status, like `STPPaymentHandlerActionParams.retrievePollingResult`: anything
    /// but `requires_action` and `succeeded` ends the screen with an error.
    var pollingStatus: STPPaymentHandlerPollingStatus {
        switch status {
        case .requiresAction: return .pending
        case .succeeded: return .succeeded
        default: return .failed
        }
    }
}

/// The params `PaymentConfirmer` confirms with.
enum ConfirmingParams {
    case paymentIntent(STPPaymentIntentConfirmParams)
    case setupIntent(STPSetupIntentConfirmParams)

    var returnURL: String? {
        switch self {
        case .paymentIntent(let params): return params.returnURL
        case .setupIntent(let params): return params.returnURL
        }
    }

    var intentID: String? {
        switch self {
        case .paymentIntent(let params): return params.stripeId
        case .setupIntent(let params): return STPSetupIntent.id(fromClientSecret: params.clientSecret)
        }
    }

    var paymentMethodID: String? {
        switch self {
        case .paymentIntent(let params): return params.paymentMethodId
        case .setupIntent(let params): return params.paymentMethodID
        }
    }

    func withUseStripeSDK() -> ConfirmingParams {
        switch self {
        case .paymentIntent(let params):
            let params = params.copy() as! STPPaymentIntentConfirmParams
            params.useStripeSDK = true
            return .paymentIntent(params)
        case .setupIntent(let params):
            let params = params.copy() as! STPSetupIntentConfirmParams
            params.useStripeSDK = true
            return .setupIntent(params)
        }
    }
}

// MARK: - Dependencies

/// The Stripe API calls `PaymentConfirmer` makes. `STPAPIClient` conforms; tests and the parity harness script it.
protocol PaymentConfirmerAPI {
    func confirmIntent(_ params: ConfirmingParams) async throws -> ConfirmingIntent
    func fetchIntent(_ intent: ConfirmingIntent, retrieval: ConfirmationMetadata.Retrieval, timeout: TimeInterval?) async throws -> ConfirmingIntent
}

extension STPAPIClient: PaymentConfirmerAPI {
    // These call the completion-block methods STPPaymentHandler calls, with the same `expand`.
    func confirmIntent(_ params: ConfirmingParams) async throws -> ConfirmingIntent {
        switch params {
        case .paymentIntent(let params):
            return .paymentIntent(try await withIntentContinuation { confirmPaymentIntent(with: params, expand: ["payment_method"], completion: $0) })
        case .setupIntent(let params):
            return .setupIntent(try await withIntentContinuation { confirmSetupIntent(with: params, expand: ["payment_method"], completion: $0) })
        }
    }

    func fetchIntent(_ intent: ConfirmingIntent, retrieval: ConfirmationMetadata.Retrieval, timeout: TimeInterval?) async throws -> ConfirmingIntent {
        let secret = intent.clientSecret
        switch (intent, retrieval) {
        case (.paymentIntent, .retrieve):
            return .paymentIntent(try await withIntentContinuation { retrievePaymentIntent(withClientSecret: secret, expand: ["payment_method"], timeout: timeout.map { NSNumber(value: $0) }, completion: $0) })
        case (.paymentIntent, .refresh):
            return .paymentIntent(try await withIntentContinuation { refreshPaymentIntent(withClientSecret: secret, completion: $0) })
        case (.setupIntent, .retrieve):
            // The SetupIntent retrieve that takes a timeout is internal to StripePayments, so this one has none.
            return .setupIntent(try await withIntentContinuation { retrieveSetupIntent(withClientSecret: secret, expand: ["payment_method"], completion: $0) })
        case (.setupIntent, .refresh):
            return .setupIntent(try await withIntentContinuation { refreshSetupIntent(withClientSecret: secret, completion: $0) })
        }
    }

    private func withIntentContinuation<Intent>(_ start: (@escaping (Intent?, Error?) -> Void) -> Void) async throws -> Intent {
        return try await withCheckedThrowingContinuation { continuation in
            start { intent, error in
                guard let intent else {
                    continuation.resume(throwing: error ?? NSError.stp_genericFailedToParseResponseError())
                    return
                }
                continuation.resume(returning: intent)
            }
        }
    }
}

/// The time source for polling. Tests replace it so polling doesn't actually wait.
struct PaymentConfirmerClock {
    var now: () -> Date
    var sleep: (TimeInterval) async -> Void

    static let live = PaymentConfirmerClock(
        now: { Date() },
        sleep: { seconds in try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000)) }
    )
}
