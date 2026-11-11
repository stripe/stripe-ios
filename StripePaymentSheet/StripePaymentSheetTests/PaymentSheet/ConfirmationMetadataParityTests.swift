//
//  ConfirmationMetadataParityTests.swift
//  StripePaymentSheetTests
//
//  Created by David Estes on 11/10/26.
//

import OHHTTPStubs
import OHHTTPStubsSwift
import SafariServices
import XCTest

@testable@_spi(InternalOnlyAPI) import StripeCore
@testable@_spi(InternalOnlyAPI) import StripePayments
@testable@_spi(InternalOnlyAPI) import StripePaymentSheet

/// Compares the native `ConfirmationMetadata` table, through `decide`, with what STPPaymentHandler does today.
///
/// It drives STPPaymentHandler's real code against scripted intents (no network, no UI):
/// - after confirm: `confirmPaymentIntent`/`confirmSetupIntent` with a scripted confirm response, and
///   `handleNextAction(for:)` with an already-confirmed intent, including their "succeeded must be a success state" guards;
/// - after a next action: `_retrieveAndCheckIntentForCurrentAction`, the loop every return path calls, with scripted
///   reads. A second read means it polled; the budget is inferred from the second read's timeout. Timeouts are driven
///   by passing an expired `PollingBudget`;
/// - next action dispatch: `_handleAuthenticationForCurrentAction` with `_redirectShim` and a recording
///   `PaymentSheetAuthenticationContext`.
///
/// Every difference is a mismatch. `knownMismatches` pins them, so a change to either side shows up here.
final class ConfirmationMetadataParityTests: XCTestCase {
    typealias Decision = ConfirmationMetadata.Decision
    typealias Situation = ConfirmationMetadata.Situation

    static let confirmReturnURL = "payments-example://confirm-return"
    static let nextActionReturnURL = "payments-example://next-action-return"

    override func setUp() {
        super.setUp()
        NetworkRecorder.shared.reset()
        stub(condition: { $0.url?.path.contains("source_cancel") ?? false }) { request in
            NetworkRecorder.shared.record(request.url?.path ?? "")
            return HTTPStubsResponse(jsonObject: [:], statusCode: 400, headers: nil)
        }
        stub(condition: { $0.url?.path.hasPrefix("/marlin/") ?? false }) { request in
            NetworkRecorder.shared.record(request.url?.path ?? "")
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    // MARK: - The harness

    func testNativeTableMatchesSTPPaymentHandler() {
        var report = ParityReport()
        checkPerTypeFunctions(&report)
        checkAfterConfirm(&report)
        let unexpectedErrors = RecordingAnalyticsClient.shared.events.filter { $0 == "unexpected_error.paymenthandler" }.count
        report.note("after confirm, STPPaymentHandler's success guard logged unexpected_error.paymenthandler \(unexpectedErrors) times")
        checkAfterNextAction(&report)
        checkNextActionDispatch(&report)

        let text = report.render()
        print(text)
        if let home = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"] {
            try? text.write(toFile: "\(home)/stripe/worktrees/handoff/confirmation-metadata-parity.txt", atomically: true, encoding: .utf8)
        }
        XCTAssertEqual(report.types, ConfirmationMetadata.nativeTypes.count)
        // Every mismatch belongs to exactly one known rule, and each rule still produces the same number of them.
        for mismatch in report.mismatches {
            let rules = Self.knownMismatches.filter { $0.matches(mismatch) }
            XCTAssertEqual(rules.count, 1, "Unexplained mismatch: \(mismatch.key) native=\(mismatch.native) table=\(mismatch.table)")
        }
        for rule in Self.knownMismatches {
            XCTAssertEqual(report.mismatches.filter(rule.matches).count, rule.count, "Mismatch \(rule.id) changed; update the doc")
        }
    }

    /// The rules the table can't express yet, as numbered in confirmation-metadata-table.md.
    struct KnownMismatch {
        let id: String
        let count: Int
        let matches: (ParityReport.Mismatch) -> Bool
    }

    static let knownMismatches: [KnownMismatch] = [
        // M1: a SetupIntent in requires_payment_method is a decline via confirmSetupIntent, but
        // `requiresPaymentMethodErrorCode` via handleNextAction(for:) (SPH:942). The table can't key on the entry point.
        KnownMismatch(id: "M1", count: 24) { $0.group == "after_confirm" && $0.scenario == "si/requires_payment_method/handle_next_action" },
        // M2: PayNow and PromptPay never cancel from the loop, whatever the next action (SPH:1708 keys on PM type); the
        // table keys it on their QR next action.
        KnownMismatch(id: "M2", count: 4) { ["paynow", "promptpay"].contains($0.type) && $0.scenario.hasPrefix("pi/requires_action+redirect_to_url") },
        // M3: requires_confirmation after a next action fails through confirmPaymentIntent (its guard, SPH:236, leaves it
        // out, and asserts) but succeeds through handleNextAction (SPH:482). The table says succeed (manual confirmation).
        KnownMismatch(id: "M3", count: 122) { $0.scenario.hasPrefix("pi/requires_confirmation") && $0.scenario.hasSuffix("/via_confirm") },
        // M4 (Alipay SetupIntents skip the Marlin ping) is gone: `beforeFetch` is PaymentIntent-only, like SPH:1626.
        // M5: handleNextAction(for: SetupIntent)'s guard (SPH:770) only accepts succeeded, so a terminal next action
        // (a voucher, microdeposits) that STPPaymentHandler completes as succeeded is turned into a failure.
        KnownMismatch(id: "M5", count: 2) { $0.scenario.hasPrefix("si/requires_action+") && $0.scenario.hasSuffix("/via_handle_next_action") },
        // F1, a deliberate fix: closing Pix's instructions web view cancels in STPPaymentHandler while the polling screen is
        // still up, and the screen's later success is dropped (SPH:1708 only exempts PayNow and PromptPay; task #62
        // reproduced it). The table lets Pix's polling screen finish the payment, like PayNow and PromptPay.
        KnownMismatch(id: "F1", count: 4) { $0.type == "pix" && $0.scenario.contains("requires_action+pix_display_qr_code") && $0.native == "cancel" && $0.table == "wait_for_next_action_screen" },
    ]

    // MARK: Per-type functions

    /// The table's per-type fields against STPPaymentHandler's per-type functions, called directly.
    func checkPerTypeFunctions(_ report: inout ParityReport) {
        for type in ConfirmationMetadata.nativeTypes {
            let metadata = ConfirmationMetadata.native(for: type)!
            report.types += 1

            // `_isProcessingIntentSuccess`, STPPaymentHandler.swift:820
            let nativeProcessingSuccess = STPPaymentHandler._isProcessingIntentSuccess(for: type)
            let tableProcessingSuccess = metadata.paymentIntent.afterConfirm.processing == .succeed
            report.compare("functions", type, "processing_is_success", native: "\(nativeProcessingSuccess)", table: "\(tableProcessingSuccess)", source: "called")

            // `supportsRefreshing`, STPPaymentMethodEnums.swift:435
            report.compare("functions", type, "retrieval", native: type.supportsRefreshing ? "refresh" : "retrieve", table: metadata.retrieval.rawValue, source: "called")

            // `PollingBudget(paymentMethodType:)`, PollingBudget.swift:43. Card's budget applies only to use_stripe_sdk.
            let budget = PollingBudget(startDate: Date(), paymentMethodType: type).map { Int($0.networkTimeout.doubleValue.rounded()) }
            let tableBudget: Int? = {
                if case .poll(let seconds, _) = metadata.paymentIntent.afterNextAction.requiresAction { return seconds }
                if case .poll(let seconds, _)? = metadata.nextActions["use_stripe_sdk"]?.whileRequiresAction { return seconds }
                return nil
            }()
            report.compare("functions", type, "requires_action_poll_seconds", native: budget.map(String.init) ?? "none", table: tableBudget.map(String.init) ?? "none", source: "called")

            // The polling screen's config, PollingViewModel.swift:15
            for (nextActionType, nextAction) in metadata.nextActions.sorted(by: { $0.key < $1.key }) {
                guard case .pollingScreen(let screen, _) = nextAction.presenter else { continue }
                let pollingType: STPPaymentMethodType = nextActionType == "await_authorization" ? .bizum : type
                let viewModel = PollingViewModel(paymentMethodType: pollingType)
                let nativeSeconds = Int(viewModel.deadline.timeIntervalSinceNow.rounded())
                report.compare("functions", type, "polling_screen(\(nextActionType))",
                               native: "\(nativeSeconds)s every \(Int(viewModel.retryInterval))s countdown=\(viewModel.showsCountdown)",
                               table: "\(screen.seconds)s every \(screen.intervalSeconds)s countdown=\(screen.showsCountdown)",
                               source: "called")
            }
        }

        // `isNextActionSuccessState`, STPPaymentHandler.swift:2120, for every next action type.
        let handler = STPPaymentHandler(apiClient: ScriptedAPIClient(publishableKey: "pk_test_123"))
        for actionType in STPIntentActionType.allNextActionTypes {
            let action = STPIntentAction.decodedObject(fromAPIResponse: Fixtures.nextAction(actionType.stringValue, id: "1"))
            XCTAssertEqual(action?.type, actionType, "Fixture for \(actionType.stringValue) didn't decode")
            let native = handler.isNextActionSuccessState(nextAction: action)
            let tableEntries = ConfirmationMetadata.nativeTypes.compactMap { ConfirmationMetadata.native(for: $0)?.nextActions[actionType.stringValue] }
            guard !tableEntries.isEmpty else {
                report.note("next action \(actionType.stringValue) isn't in the table: no PaymentSheet type gets it")
                continue
            }
            for entry in tableEntries {
                report.compare("functions", nil, "next_action_is_success(\(actionType.stringValue))", native: "\(native)", table: "\(entry.whileRequiresAction == .succeed)", source: "called")
            }
        }
    }

    // MARK: After confirm

    static let paymentIntentStatuses = ["succeeded", "requires_capture", "processing", "requires_payment_method", "canceled", "requires_confirmation", "bogus_status"]
    static let setupIntentStatuses = ["succeeded", "processing", "requires_payment_method", "canceled", "requires_confirmation", "bogus_status"]

    /// The first evaluation of an intent, through both entry points PaymentSheet uses.
    func checkAfterConfirm(_ report: inout ParityReport) {
        STPAssertTestUtil.shouldSuppressNextSTPAlert = false
        for type in ConfirmationMetadata.nativeTypes {
            let metadata = ConfirmationMetadata.native(for: type)!
            for status in Self.paymentIntentStatuses {
                let table = metadata.decide(Situation(intent: .paymentIntent, status: STPPaymentIntentStatus.status(from: status), nextActionType: nil, phase: .afterConfirm))
                for entry in ["confirm", "handle_next_action"] {
                    let native = nativeAfterConfirmPaymentIntent(type: type, status: status, entry: entry)
                    report.compare("after_confirm", type, "pi/\(status)/\(entry)", native: native.description, table: table.description, source: "driven")
                }
            }
            for status in Self.setupIntentStatuses {
                let table = metadata.decide(Situation(intent: .setupIntent, status: STPPaymentIntentStatus.status(from: status), nextActionType: nil, phase: .afterConfirm))
                // A type PaymentSheet doesn't set up never reaches STPPaymentHandler with a SetupIntent.
                guard metadata.setupIntent != nil else { continue }
                for entry in ["confirm", "handle_next_action"] {
                    let native = nativeAfterConfirmSetupIntent(type: type, status: status, entry: entry)
                    report.compare("after_confirm", type, "si/\(status)/\(entry)", native: native.description, table: table.description, source: "driven")
                }
            }
        }
    }

    func nativeAfterConfirmPaymentIntent(type: STPPaymentMethodType, status: String, entry: String) -> Decision {
        let client = ScriptedAPIClient(publishableKey: "pk_test_123")
        let handler = STPPaymentHandler(apiClient: client)
            handler.analyticsClient = RecordingAnalyticsClient.shared
        handler.analyticsClient = RecordingAnalyticsClient.shared
        let id = Fixtures.nextID()
        let paymentIntent = Fixtures.paymentIntent(id: id, type: type.identifier, status: status, nextAction: nil)
        var result: (STPPaymentHandlerActionStatus, NSError?)?
        // The confirm path's guard asserts when the handler's status and the intent disagree.
        STPAssertTestUtil.shouldSuppressNextSTPAlert = true
        if entry == "confirm" {
            client.confirmedPaymentIntent = paymentIntent
            let params = STPPaymentIntentConfirmParams(clientSecret: paymentIntent.clientSecret)
            handler.confirmPaymentIntent(params: params, authenticationContext: RecordingAuthenticationContext()) { status, _, error in
                result = (status, error)
            }
        } else {
            handler.handleNextAction(for: paymentIntent, with: RecordingAuthenticationContext(), returnURL: nil) { status, _, error in
                result = (status, error)
            }
        }
        STPAssertTestUtil.shouldSuppressNextSTPAlert = false
        return Decision(nativeResult: result, fetchCount: 0)
    }

    func nativeAfterConfirmSetupIntent(type: STPPaymentMethodType, status: String, entry: String) -> Decision {
        let client = ScriptedAPIClient(publishableKey: "pk_test_123")
        let handler = STPPaymentHandler(apiClient: client)
            handler.analyticsClient = RecordingAnalyticsClient.shared
        handler.analyticsClient = RecordingAnalyticsClient.shared
        let id = Fixtures.nextID()
        let setupIntent = Fixtures.setupIntent(id: id, type: type.identifier, status: status, nextAction: nil)
        var result: (STPPaymentHandlerActionStatus, NSError?)?
        STPAssertTestUtil.shouldSuppressNextSTPAlert = true
        if entry == "confirm" {
            client.confirmedSetupIntent = setupIntent
            let params = STPSetupIntentConfirmParams(clientSecret: setupIntent.clientSecret)
            handler.confirmSetupIntent(params: params, authenticationContext: RecordingAuthenticationContext()) { status, _, error in
                result = (status, error)
            }
        } else {
            handler.handleNextAction(for: setupIntent, with: RecordingAuthenticationContext(), returnURL: nil) { status, _, error in
                result = (status, error)
            }
        }
        STPAssertTestUtil.shouldSuppressNextSTPAlert = false
        return Decision(nativeResult: result, fetchCount: 0)
    }

    // MARK: After a next action

    /// One run of STPPaymentHandler's post-return loop.
    final class LoopRun {
        let type: STPPaymentMethodType
        let intent: ConfirmationMetadata.IntentKind
        let status: String
        let nextActionType: String?
        let webViewDismissed: Bool
        let expiredBudget: Bool
        let id = Fixtures.nextID()
        let client = ScriptedAPIClient(publishableKey: "pk_test_123")
        var handler: STPPaymentHandler!
        var result: (STPPaymentHandlerActionStatus, NSError?)?

        init(type: STPPaymentMethodType, intent: ConfirmationMetadata.IntentKind, status: String, nextActionType: String?, webViewDismissed: Bool, expiredBudget: Bool) {
            self.type = type
            self.intent = intent
            self.status = status
            self.nextActionType = nextActionType
            self.webViewDismissed = webViewDismissed
            self.expiredBudget = expiredBudget
        }

        /// The intent before the return has the type's first next action; each read returns `status`, and with a fresh
        /// budget the second read returns `succeeded` so a poll ends quickly.
        func start() {
            handler = STPPaymentHandler(apiClient: client)
            handler.analyticsClient = RecordingAnalyticsClient.shared
            handler.safariViewControllerDismissedManually = webViewDismissed
            let before = nextActionType ?? "redirect_to_url"
            let budget = expiredBudget ? PollingBudget(startDate: Date(timeIntervalSinceNow: -100), duration: 1) : nil
            let read = expiredBudget ? status : "succeeded"
            switch intent {
            case .paymentIntent:
                client.paymentIntents = [
                    Fixtures.paymentIntent(id: id, type: type.identifier, status: status, nextAction: nextActionType),
                    Fixtures.paymentIntent(id: id, type: type.identifier, status: read, nextAction: nextActionType),
                ]
                let action = STPPaymentHandlerPaymentIntentActionParams(
                    apiClient: client,
                    authenticationContext: RecordingAuthenticationContext(),
                    threeDSCustomizationSettings: .init(),
                    paymentIntent: Fixtures.paymentIntent(id: id, type: type.identifier, status: "requires_action", nextAction: before),
                    returnURL: nil
                ) { [weak self] status, _, error in
                    self?.result = (status, error)
                }
                handler.currentAction = action
                handler._retrieveAndCheckIntentForCurrentAction(currentAction: action, pollingBudget: budget)
            case .setupIntent:
                client.setupIntents = [
                    Fixtures.setupIntent(id: id, type: type.identifier, status: status, nextAction: nextActionType),
                    Fixtures.setupIntent(id: id, type: type.identifier, status: read, nextAction: nextActionType),
                ]
                let action = STPPaymentHandlerSetupIntentActionParams(
                    apiClient: client,
                    authenticationContext: RecordingAuthenticationContext(),
                    threeDSCustomizationSettings: .init(),
                    setupIntent: Fixtures.setupIntent(id: id, type: type.identifier, status: "requires_action", nextAction: before),
                    returnURL: nil
                ) { [weak self] status, _, error in
                    self?.result = (status, error)
                }
                handler.currentAction = action
                handler._retrieveAndCheckIntentForCurrentAction(currentAction: action, pollingBudget: budget)
            }
        }

        var decision: Decision {
            if client.fetches.count >= 2 && !expiredBudget {
                // The second read's timeout is the budget left: `PollingBudget.networkTimeout`. Refresh has no timeout.
                guard let timeout = client.fetches[1].timeout else {
                    return .poll(seconds: -1)
                }
                let elapsed = client.fetches[1].date.timeIntervalSince(client.fetches[0].date)
                return .poll(seconds: Int((timeout.doubleValue + elapsed).rounded()))
            }
            if result == nil {
                return .waitForNextActionScreen
            }
            return Decision(nativeResult: result, fetchCount: client.fetches.count)
        }

        var canceledSource: Bool { NetworkRecorder.shared.contains("_\(id)/source_cancel") }
        var loadedMarlinURL: Bool { NetworkRecorder.shared.contains("/marlin/\(id)") }
    }

    func checkAfterNextAction(_ report: inout ParityReport) {
        var runs: [LoopRun] = []
        for type in ConfirmationMetadata.nativeTypes {
            let metadata = ConfirmationMetadata.native(for: type)!
            for intent in [ConfirmationMetadata.IntentKind.paymentIntent, .setupIntent] {
                guard intent == .paymentIntent || metadata.setupIntent != nil else { continue }
                let statuses = (intent == .paymentIntent ? Self.paymentIntentStatuses : Self.setupIntentStatuses).filter { $0 != "bogus_status" }
                var scenarios: [(String, String?)] = statuses.map { ($0, nil) }
                // Polling-screen next actions finish in the screen; the loop doesn't run for them unless there's a web view.
                for (nextActionType, nextAction) in metadata.nextActions.sorted(by: { $0.key < $1.key }) {
                    if case .pollingScreen(_, false) = nextAction.presenter { continue }
                    if case .none = nextAction.presenter { continue }
                    scenarios.append(("requires_action", nextActionType))
                }
                for (status, nextActionType) in scenarios {
                    for webViewDismissed in [false, true] {
                        let run = LoopRun(type: type, intent: intent, status: status, nextActionType: nextActionType, webViewDismissed: webViewDismissed, expiredBudget: false)
                        runs.append(run)
                        run.start()
                    }
                }
            }
        }
        // Polls read again after 1s; give every run time to finish.
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 3))

        // For every run that polled, run it again with an expired budget to see how the poll ends.
        var expiredRuns: [LoopRun] = []
        for run in runs {
            if case .poll = run.decision {
                let expired = LoopRun(type: run.type, intent: run.intent, status: run.status, nextActionType: run.nextActionType, webViewDismissed: run.webViewDismissed, expiredBudget: true)
                expiredRuns.append(expired)
                expired.start()
            }
        }
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 2))

        for run in runs + expiredRuns {
            let metadata = ConfirmationMetadata.native(for: run.type)!
            let situation = Situation(
                intent: run.intent,
                status: STPPaymentIntentStatus.status(from: run.status),
                nextActionType: run.nextActionType,
                phase: .afterNextAction(webViewDismissed: run.webViewDismissed),
                pollExpired: run.expiredBudget
            )
            var table = metadata.decide(situation)
            var native = run.decision
            // Refresh reads have no timeout, so the budget can't be observed; compare only "it polled".
            if case .poll(-1) = native, case .poll = table {
                table = .poll(seconds: -1)
            }
            // Poll budgets the loop creates and then shares: compare the seconds only on a fresh budget.
            if run.expiredBudget, case .poll = native {
                native = .poll(seconds: 0)
            }
            let intentName = run.intent == .paymentIntent ? "pi" : "si"
            let scenario = "\(intentName)/\(run.status)\(run.nextActionType.map { "+\($0)" } ?? "")\(run.webViewDismissed ? "/web_view_dismissed" : "")\(run.expiredBudget ? "/poll_expired" : "")"
            if native == .succeed {
                // The loop's `.succeeded` then passes the entry point's "succeeded must be a success state" guard.
                // The loop is driven; the guard is applied as written at SPH:236, :482, :577 and :770.
                let finalStatus = run.client.fetches.count > 1 && !run.expiredBudget ? "succeeded" : run.status
                for entry in ["confirm", "handle_next_action"] {
                    let passes = Self.nativeGuardPasses(intent: run.intent, entry: entry, status: finalStatus, type: run.type, nextActionType: run.nextActionType)
                    let guarded: Decision = passes ? .succeed : .fail(.unexpectedStatus)
                    report.compare("after_next_action", run.type, "\(scenario)/via_\(entry)", native: guarded.description, table: table.description, source: "driven+guard(code)")
                }
            } else {
                report.compare("after_next_action", run.type, scenario, native: native.description, table: table.description, source: "driven")
            }

            guard let firstFetch = run.client.fetches.first else { continue }
            let tableRetrieval = metadata.retrieval.rawValue
            report.compare("after_next_action", run.type, "\(scenario)/read_endpoint", native: firstFetch.endpoint, table: tableRetrieval, source: "driven")

            if run.nextActionType == "alipay_handle_redirect" {
                let tableBeforeFetch = run.intent == .paymentIntent ? metadata.beforeFetch : nil
                report.compare("after_next_action", run.type, "\(scenario)/before_fetch", native: run.loadedMarlinURL ? ConfirmationMetadata.BeforeFetch.loadAlipayMarlinReturnURL.rawValue : "none", table: tableBeforeFetch?.rawValue ?? "none", source: "driven")
            }
            if run.status == "requires_action", table == .cancel, ["redirect_to_url", "use_stripe_sdk"].contains(run.nextActionType ?? "") {
                report.compare("after_next_action", run.type, "\(scenario)/on_cancel", native: run.canceledSource ? "cancel3DSSource" : "none", table: metadata.onCancel.rawValue, source: "driven")
            }
        }
    }

    /// STPPaymentHandler's "succeeded must be a success state" guards, as written. They call the real
    /// `_isProcessingIntentSuccess` and `isNextActionSuccessState`.
    static func nativeGuardPasses(intent: ConfirmationMetadata.IntentKind, entry: String, status: String, type: STPPaymentMethodType, nextActionType: String?) -> Bool {
        let handler = STPPaymentHandler(apiClient: ScriptedAPIClient(publishableKey: "pk_test_123"))
        let nextAction = nextActionType.flatMap { STPIntentAction.decodedObject(fromAPIResponse: Fixtures.nextAction($0, id: "0")) }
        let terminalNextAction = status == "requires_action" && handler.isNextActionSuccessState(nextAction: nextAction)
        switch (intent, entry) {
        case (.paymentIntent, "confirm"):
            // SPH:236
            return ["succeeded", "requires_capture"].contains(status) || (status == "processing" && STPPaymentHandler._isProcessingIntentSuccess(for: type)) || terminalNextAction
        case (.paymentIntent, _):
            // SPH:482
            return ["succeeded", "requires_capture", "requires_confirmation"].contains(status) || (status == "processing" && STPPaymentHandler._isProcessingIntentSuccess(for: type)) || terminalNextAction
        case (.setupIntent, "confirm"):
            // SPH:577
            return status == "succeeded" || terminalNextAction
        case (.setupIntent, _):
            // SPH:770
            return status == "succeeded"
        }
    }

    // MARK: Next action dispatch

    func checkNextActionDispatch(_ report: inout ParityReport) {
        for type in ConfirmationMetadata.nativeTypes {
            let metadata = ConfirmationMetadata.native(for: type)!
            for (nextActionType, nextAction) in metadata.nextActions.sorted(by: { $0.key < $1.key }) {
                for confirmReturnURL in [Self.confirmReturnURL, nil] {
                    let (native, source) = nativeDispatch(type: type, nextActionType: nextActionType, confirmReturnURL: confirmReturnURL)
                    let table = Self.predictDispatch(nextAction, nextActionType: nextActionType, confirmReturnURL: confirmReturnURL)
                    let scenario = "\(nextActionType)/\(confirmReturnURL == nil ? "no_return_url" : "return_url")"
                    report.compare("dispatch", type, scenario, native: native, table: table, source: source)
                }
            }
        }
    }

    /// What `_handleAuthenticationForCurrentAction` does with the next action, and whether that was driven or read from code.
    func nativeDispatch(type: STPPaymentMethodType, nextActionType: String, confirmReturnURL: String?) -> (String, String) {
        // These `assertionFailure` without a return URL (STPPaymentHandler.swift:1456, :1468, :1497, :1536), which
        // would stop the test run, so this case is characterized from code instead of driven.
        let requiresReturnURL = ["cashapp_handle_redirect_or_display_qr_code", "paynow_display_qr_code", "promptpay_display_qr_code", "swish_handle_redirect_or_display_qr_code"]
        if confirmReturnURL == nil && requiresReturnURL.contains(nextActionType) {
            return ("fail(missing_return_url)", "code")
        }
        let client = ScriptedAPIClient(publishableKey: "pk_test_123")
        let handler = STPPaymentHandler(apiClient: client)
            handler.analyticsClient = RecordingAnalyticsClient.shared
        handler.analyticsClient = RecordingAnalyticsClient.shared
        var redirects: [(URL, URL?)] = []
        handler._redirectShim = { url, returnURL, _ in redirects.append((url, returnURL)) }
        let context = RecordingAuthenticationContext()
        var result: (STPPaymentHandlerActionStatus, NSError?)?
        let id = Fixtures.nextID()
        let paymentIntent = Fixtures.paymentIntent(id: id, type: type.identifier, status: "requires_action", nextAction: nextActionType)
        if nextActionType == "use_stripe_sdk" {
            // Only 3DS2's redirect variant can run without the 3DS2 SDK; fingerprinting is characterized from code.
            XCTAssertEqual(paymentIntent.nextAction?.useStripeSDK?.type, .threeDS2Redirect)
        }
        let action = STPPaymentHandlerPaymentIntentActionParams(
            apiClient: client,
            authenticationContext: context,
            threeDSCustomizationSettings: .init(),
            paymentIntent: paymentIntent,
            returnURL: confirmReturnURL
        ) { status, _, error in
            result = (status, error)
        }
        handler.currentAction = action
        handler._handleAuthenticationForCurrentAction()
        handler._redirectShim = nil

        var parts: [String] = []
        if let (url, returnURL) = redirects.first {
            let opened = url.scheme == "alipay" ? "native_url" : "url"
            parts.append("redirect(\(opened), return=\(Self.describeReturnURL(returnURL)))")
        }
        if let pollingType = context.pollingTypes.first {
            parts.append("polling_screen(\(pollingType.identifier))")
        }
        if let result {
            parts.append(Decision(nativeResult: result, fetchCount: 0).description)
        }
        return (parts.isEmpty ? "nothing" : parts.joined(separator: " "), "driven")
    }

    static func predictDispatch(_ nextAction: ConfirmationMetadata.NextAction, nextActionType: String, confirmReturnURL: String?) -> String {
        let returnURL: String?
        switch nextAction.returnURL {
        case .nextAction:
            returnURL = nextActionReturnURL
        case .confirmRequired:
            guard let confirmReturnURL else {
                return "fail(missing_return_url)"
            }
            returnURL = confirmReturnURL
        case .confirmIfSet:
            returnURL = confirmReturnURL
        case .confirmThenNextAction:
            returnURL = confirmReturnURL ?? nextActionReturnURL
        case .none:
            returnURL = nil
        }
        let opened = nextAction.appToApp == .nativeURLThenWeb ? "native_url" : "url"
        let redirect = "redirect(\(opened), return=\(describeReturnURL(returnURL.flatMap(URL.init(string:)))))"
        switch nextAction.presenter {
        case .redirect, .threeDS2:
            return redirect
        case .pollingScreen(_, let overWebView):
            let screen = "polling_screen(\(pollingScreenType(nextActionType)))"
            return overWebView ? "\(redirect) \(screen)" : screen
        case .none:
            return Decision.succeed.description
        }
    }

    static func pollingScreenType(_ nextActionType: String) -> String {
        switch nextActionType {
        case "blik_authorize": return "blik"
        case "mb_way_await_authorization": return "mb_way"
        case "await_authorization": return "bizum"
        case "paynow_display_qr_code": return "paynow"
        case "promptpay_display_qr_code": return "promptpay"
        case "pix_display_qr_code": return "pix"
        default: return "?"
        }
    }

    static func describeReturnURL(_ url: URL?) -> String {
        switch url?.absoluteString {
        case nil: return "none"
        case confirmReturnURL: return "confirm"
        case nextActionReturnURL: return "next_action"
        case let other?: return other
        }
    }

    // MARK: - Server specs

    /// `ConfirmationMetadata(serverSpec:)`, which the engine confirms server-driven payment methods with, agrees with the
    /// spike's lean handler for every spec the contract can send, except L1 and L2, where it now follows STPPaymentHandler.
    func testServerSpecMetadataMatchesTheSpikeExceptL1AndL2() {
        let statuses: [STPPaymentIntentStatus] = [.succeeded, .requiresCapture, .requiresConfirmation, .canceled, .requiresPaymentMethod, .processing, .requiresAction, .unknown]
        var mismatches: [String] = []
        for processing in [ServerDrivenConfirmSpec.ProcessingOutcome.succeed, .fail, .poll] {
            for requiresAction in [ServerDrivenConfirmSpec.RequiresActionOutcome.cancel, .poll, .succeed] {
                for pollSeconds in [0, 5] {
                    let spec = ServerDrivenConfirmSpec(nextActions: [.redirectToURL], retrieval: .retrieve, processing: processing, requiresAction: requiresAction, pollSeconds: pollSeconds)
                    let metadata = ConfirmationMetadata(serverSpec: spec, paymentMethodDataType: "demo_pay")
                    for status in statuses {
                        for hasPerformedNextAction in [false, true] {
                            let lean = Self.spikeDecide(status: status, hasPerformedNextAction: hasPerformedNextAction, spec: spec)
                            let table = metadata.decide(Situation(
                                intent: .paymentIntent,
                                status: status,
                                nextActionType: "redirect_to_url",
                                phase: hasPerformedNextAction ? .afterNextAction(webViewDismissed: false) : .afterConfirm
                            ))
                            var leanAsTable = Decision(lean, pollSeconds: pollSeconds)
                            // With 0 seconds the lean handler's poll finishes at once, as on a timeout.
                            if leanAsTable == .poll(seconds: 0) {
                                leanAsTable = status == .processing ? .fail(.unexpectedStatus) : .cancel
                            }
                            if leanAsTable != table {
                                mismatches.append("\(processing)/\(requiresAction)/\(pollSeconds)s \(STPPaymentIntentStatus.string(from: status)) after_next_action=\(hasPerformedNextAction): lean=\(leanAsTable.description) table=\(table.description)")
                            }
                        }
                    }
                }
            }
        }
        print(mismatches.joined(separator: "\n"))
        // Right after confirm, for each of the 18 specs, the spike differed from STPPaymentHandler (and the table) twice:
        // it succeeds `requires_confirmation`, which STPPaymentHandler fails, and it fails `requires_payment_method` as a
        // decline, which STPPaymentHandler fails as `requiresPaymentMethodErrorCode`.
        XCTAssertEqual(mismatches.count, 36, mismatches.joined(separator: "\n"))
        XCTAssertTrue(mismatches.allSatisfy { $0.contains("requires_confirmation after_next_action=false") || $0.contains("requires_payment_method after_next_action=false") })
    }

    /// The spike's `ServerDrivenPaymentHandler.decide` (task #54), frozen here as the reference for L1 and L2.
    enum SpikeDecision: Equatable {
        case succeed, cancel, performNextAction, poll
        case fail(paymentFailed: Bool)
    }

    static func spikeDecide(status: STPPaymentIntentStatus, hasPerformedNextAction: Bool, spec: ServerDrivenConfirmSpec) -> SpikeDecision {
        switch status {
        case .succeeded, .requiresCapture, .requiresConfirmation:
            return .succeed
        case .canceled:
            return .cancel
        case .requiresPaymentMethod:
            return .fail(paymentFailed: true)
        case .processing:
            switch spec.processing {
            case .succeed: return .succeed
            case .fail: return .fail(paymentFailed: false)
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
        default:
            return .fail(paymentFailed: false)
        }
    }

    /// The server's spec replaces the whole native policy, with nothing carried over.
    func testServerSpecReplacesNativePolicy() {
        let spec = ServerDrivenConfirmSpec(nextActions: [.redirectToURL], retrieval: .retrieve, processing: .succeed, requiresAction: .poll, pollSeconds: 5)
        // Given a native type with its own rules
        let native = ConfirmationMetadata.native(for: .cashApp)!
        XCTAssertEqual(native.retrieval, .refresh)
        // When the server sends a spec for it
        let resolved = ConfirmationMetadata.resolved(for: .cashApp, serverSpec: spec)!
        // Then nothing native survives
        XCTAssertEqual(resolved, ConfirmationMetadata(serverSpec: spec, paymentMethodDataType: "cashapp"))
        XCTAssertEqual(resolved.retrieval, .retrieve)
        XCTAssertNil(resolved.nextActions["cashapp_handle_redirect_or_display_qr_code"])
        XCTAssertEqual(resolved.params.mandateData, .none)
        // ...and without a spec, the native table applies
        XCTAssertEqual(ConfirmationMetadata.resolved(for: .cashApp, serverSpec: nil), native)
    }

    /// Every entry encodes and decodes, so a server spec could carry any of it.
    func testTableIsCodable() throws {
        for type in ConfirmationMetadata.nativeTypes {
            let metadata = ConfirmationMetadata.native(for: type)!
            let data = try JSONEncoder().encode(metadata)
            XCTAssertEqual(try JSONDecoder().decode(ConfirmationMetadata.self, from: data), metadata, type.identifier)
        }
    }

    /// STPPaymentHandler retries a failed read after a next action without limit while it isn't polling: each retry
    /// passes the original nil budget, so a fresh 1s budget is made every time (STPPaymentHandler.swift:1638).
    func testNativeReadRetryIsUnbounded() {
        let client = ScriptedAPIClient(publishableKey: "pk_test_123")
        let handler = STPPaymentHandler(apiClient: client)
            handler.analyticsClient = RecordingAnalyticsClient.shared
        handler.analyticsClient = RecordingAnalyticsClient.shared
        let id = Fixtures.nextID()
        client.paymentIntentErrorsBeforeSuccess = 3
        client.paymentIntents = [Fixtures.paymentIntent(id: id, type: "ideal", status: "succeeded", nextAction: nil)]
        var result: STPPaymentHandlerActionStatus?
        let action = STPPaymentHandlerPaymentIntentActionParams(
            apiClient: client,
            authenticationContext: RecordingAuthenticationContext(),
            threeDSCustomizationSettings: .init(),
            paymentIntent: Fixtures.paymentIntent(id: id, type: "ideal", status: "requires_action", nextAction: "redirect_to_url"),
            returnURL: nil
        ) { status, _, _ in
            result = status
        }
        handler.currentAction = action
        handler._retrieveAndCheckIntentForCurrentAction(currentAction: action)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 4.5))
        // Three failed reads, each retried after ~1s, then a success. The lean handler retries once.
        XCTAssertEqual(client.fetches.count, 4)
        XCTAssertEqual(result, .succeeded)
    }
}

// MARK: - Report

struct ParityReport {
    struct Mismatch {
        let group: String
        let type: String
        let scenario: String
        let native: String
        let table: String
        let source: String
        var key: String { "\(group)|\(type)|\(scenario)" }
    }

    var types = 0
    var comparisons = 0
    var mismatches: [Mismatch] = []
    var notes: [String] = []

    mutating func compare(_ group: String, _ type: STPPaymentMethodType?, _ scenario: String, native: String, table: String, source: String) {
        comparisons += 1
        if native != table {
            mismatches.append(Mismatch(group: group, type: type?.identifier ?? "*", scenario: scenario, native: native, table: table, source: source))
        }
    }

    mutating func note(_ note: String) {
        notes.append(note)
    }

    func render() -> String {
        var lines = ["PARITY types=\(types) comparisons=\(comparisons) mismatches=\(mismatches.count)"]
        lines += notes.map { "NOTE \($0)" }
        lines += mismatches.map { "MISMATCH \($0.key) native=\($0.native) table=\($0.table) [\($0.source)]" }
        return lines.joined(separator: "\n")
    }
}

extension ConfirmationMetadata.Decision {
    /// What STPPaymentHandler's completion means, in the table's terms.
    init(nativeResult: (STPPaymentHandlerActionStatus, NSError?)?, fetchCount: Int) {
        guard let (status, error) = nativeResult else {
            self = .fail(.unexpectedStatus)
            return
        }
        switch status {
        case .succeeded:
            self = .succeed
        case .canceled:
            self = .cancel
        case .failed:
            switch STPPaymentHandlerErrorCode(rawValue: error?.code ?? -1) {
            case .paymentErrorCode, .notAuthenticatedErrorCode:
                self = .fail(.paymentFailed)
            case .unsupportedAuthenticationErrorCode:
                self = .fail(.unsupportedNextAction)
            case .requiresPaymentMethodErrorCode:
                self = .fail(.requiresPaymentMethod)
            default:
                self = .fail(.unexpectedStatus)
            }
        @unknown default:
            self = .fail(.unexpectedStatus)
        }
    }

    /// The spike's decision, in the table's terms.
    init(_ lean: ConfirmationMetadataParityTests.SpikeDecision, pollSeconds: Int) {
        switch lean {
        case .succeed: self = .succeed
        case .cancel: self = .cancel
        case .performNextAction: self = .performNextAction
        case .poll: self = .poll(seconds: pollSeconds)
        case .fail(let paymentFailed): self = .fail(paymentFailed ? .paymentFailed : .unexpectedStatus)
        }
    }

    var description: String {
        switch self {
        case .succeed: return "succeed"
        case .fail(let reason): return "fail(\(reason))"
        case .cancel: return "cancel"
        case .performNextAction: return "perform_next_action"
        case .poll(let seconds): return "poll(\(seconds))"
        case .waitForNextActionScreen: return "wait_for_next_action_screen"
        }
    }
}

extension STPIntentActionType {
    static let allNextActionTypes: [STPIntentActionType] = [
        .redirectToURL, .useStripeSDK, .OXXODisplayDetails, .alipayHandleRedirect, .BLIKAuthorize, .weChatPayRedirectToApp,
        .boletoDisplayDetails, .verifyWithMicrodeposits, .cashAppRedirectToApp, .payNowDisplayQrCode, .konbiniDisplayDetails,
        .promptpayDisplayQrCode, .pixDisplayQrCode, .swishHandleRedirect, .multibancoDisplayDetails, .mbWayAwaitAuthorization,
        .awaitAuthorization,
    ]
}

// MARK: - Fakes

/// Serves scripted intents for confirm, retrieve and refresh, and records each read.
final class ScriptedAPIClient: STPAPIClient {
    struct Fetch {
        let endpoint: String
        let timeout: NSNumber?
        let date: Date
    }

    var confirmedPaymentIntent: STPPaymentIntent?
    var confirmedSetupIntent: STPSetupIntent?
    /// Served in order; the last one repeats.
    var paymentIntents: [STPPaymentIntent] = []
    var setupIntents: [STPSetupIntent] = []
    var paymentIntentErrorsBeforeSuccess = 0
    private(set) var fetches: [Fetch] = []

    override func confirmPaymentIntent(with paymentIntentConfirmParams: STPPaymentIntentConfirmParams, expand: [String]?, completion: @escaping STPPaymentIntentCompletionBlock) {
        completion(confirmedPaymentIntent, nil)
    }

    override func confirmSetupIntent(with setupIntentParams: STPSetupIntentConfirmParams, expand: [String]?, completion: @escaping STPSetupIntentCompletionBlock) {
        completion(confirmedSetupIntent, nil)
    }

    override func retrievePaymentIntent(withClientSecret secret: String, expand: [String]?, timeout: NSNumber?, completion: @escaping STPPaymentIntentCompletionBlock) {
        fetches.append(Fetch(endpoint: "retrieve", timeout: timeout, date: Date()))
        servePaymentIntent(completion)
    }

    override func refreshPaymentIntent(withClientSecret secret: String, completion: @escaping STPPaymentIntentCompletionBlock) {
        fetches.append(Fetch(endpoint: "refresh", timeout: nil, date: Date()))
        servePaymentIntent(completion)
    }

    override func retrieveSetupIntent(withClientSecret secret: String, expand: [String]?, timeout: NSNumber?, completion: @escaping STPSetupIntentCompletionBlock) {
        fetches.append(Fetch(endpoint: "retrieve", timeout: timeout, date: Date()))
        completion(nextSetupIntent(), nil)
    }

    override func refreshSetupIntent(withClientSecret secret: String, completion: @escaping STPSetupIntentCompletionBlock) {
        fetches.append(Fetch(endpoint: "refresh", timeout: nil, date: Date()))
        completion(nextSetupIntent(), nil)
    }

    private func servePaymentIntent(_ completion: STPPaymentIntentCompletionBlock) {
        if paymentIntentErrorsBeforeSuccess > 0 {
            paymentIntentErrorsBeforeSuccess -= 1
            completion(nil, NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet))
            return
        }
        let paymentIntent = paymentIntents.count > 1 ? paymentIntents.removeFirst() : paymentIntents.first
        completion(paymentIntent, nil)
    }

    private func nextSetupIntent() -> STPSetupIntent? {
        return setupIntents.count > 1 ? setupIntents.removeFirst() : setupIntents.first
    }
}

/// Records STPPaymentHandler's analytics without sending them. The real client asserts on `unexpected_error` events,
/// which the confirm path's success guard logs on purpose.
final class RecordingAnalyticsClient: STPAnalyticsClient {
    static let shared = RecordingAnalyticsClient()
    private(set) var events: [String] = []

    override func log(analytic: Analytic, apiClient: STPAPIClient = .shared) {
        events.append(analytic.event.rawValue)
    }
}

/// A PaymentSheet authentication context that records polling screens instead of showing them.
final class RecordingAuthenticationContext: NSObject, PaymentSheetAuthenticationContext {
    private(set) var pollingTypes: [STPPaymentMethodType] = []
    let viewController = UIViewController()

    func authenticationPresentingViewController() -> UIViewController {
        return viewController
    }

    func present(_ authenticationViewController: UIViewController, completion: @escaping () -> Void) {}

    func dismiss(_ authenticationViewController: UIViewController, completion: (() -> Void)?) {
        completion?()
    }

    func presentPollingVCForAction(action: STPPaymentHandlerActionParams, type: STPPaymentMethodType, safariViewController: SFSafariViewController?) {
        pollingTypes.append(type)
    }
}

/// Requests the loop makes outside STPAPIClient's overridable methods (3DS source cancel, Alipay's Marlin URL).
final class NetworkRecorder {
    static let shared = NetworkRecorder()
    private let lock = NSLock()
    private var paths: [String] = []

    func reset() {
        lock.lock(); defer { lock.unlock() }
        paths = []
    }

    func record(_ path: String) {
        lock.lock(); defer { lock.unlock() }
        paths.append(path)
    }

    func contains(_ suffix: String) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return paths.contains { $0.hasSuffix(suffix) }
    }
}

enum Fixtures {
    private static var counter = 0

    static func nextID() -> String {
        counter += 1
        return "\(counter)"
    }

    /// A payment method object. Card and Link get their sub-object, which `_markChallengeCanceled` checks.
    static func paymentMethod(id: String, type: String) -> [String: Any] {
        var json: [String: Any] = ["id": "pm_\(id)", "object": "payment_method", "type": type, "created": 1652736692, "livemode": false]
        if type == "card" {
            json["card"] = ["brand": "visa", "exp_month": 1, "exp_year": 2040, "last4": "4242"]
        } else if type == "link" {
            json["link"] = ["email": "jane@example.com"]
        }
        return json
    }

    static func paymentIntent(id: String, type: String, status: String, nextAction: String?) -> STPPaymentIntent {
        var json: [String: Any] = [
            "id": "pi_\(id)",
            "object": "payment_intent",
            "client_secret": "pi_\(id)_secret_abc",
            "amount": 1000,
            "currency": "usd",
            "status": status,
            "livemode": false,
            "created": 1652736692,
            "payment_method_types": [type],
            "payment_method": paymentMethod(id: id, type: type),
        ]
        json["next_action"] = nextAction.map { self.nextAction($0, id: id) }
        return STPPaymentIntent.decodedObject(fromAPIResponse: json)!
    }

    static func setupIntent(id: String, type: String, status: String, nextAction: String?) -> STPSetupIntent {
        var json: [String: Any] = [
            "id": "seti_\(id)",
            "object": "setup_intent",
            "client_secret": "seti_\(id)_secret_abc",
            "status": status,
            "livemode": false,
            "created": 1652736692,
            "payment_method_types": [type],
            "payment_method": paymentMethod(id: id, type: type),
        ]
        json["next_action"] = nextAction.map { self.nextAction($0, id: id) }
        return STPSetupIntent.decodedObject(fromAPIResponse: json)!
    }

    /// A decodable `next_action` of `type`. Redirect URLs end in a 3DS source ID so a cancel can cancel it.
    static func nextAction(_ type: String, id: String) -> [String: Any] {
        let details: [String: Any]?
        switch type {
        case "redirect_to_url":
            details = ["url": "https://hooks.stripe.com/redirect/authenticate/src_\(id)", "return_url": ConfirmationMetadataParityTests.nextActionReturnURL]
        case "use_stripe_sdk":
            details = ["type": "three_d_secure_redirect", "stripe_js": "https://hooks.stripe.com/3d_secure_2/authenticate/src_\(id)"]
        case "alipay_handle_redirect":
            let marlin = "https://hooks.stripe.com/marlin/\(id)".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
            details = ["native_url": "alipay://alipayclient/?return_url=\(marlin)", "url": "https://alipay.example/pay", "return_url": ConfirmationMetadataParityTests.nextActionReturnURL]
        case "wechat_pay_redirect_to_ios_app":
            details = ["native_url": "weixin://app/pay"]
        case "cashapp_handle_redirect_or_display_qr_code", "swish_handle_redirect_or_display_qr_code":
            details = ["mobile_auth_url": "https://wallet.example/auth"]
        case "paynow_display_qr_code", "promptpay_display_qr_code":
            details = ["hosted_instructions_url": "https://qr.example/instructions"]
        case "pix_display_qr_code":
            details = ["hosted_instructions_url": "https://qr.example/instructions", "expires_at": 1_900_000_000]
        case "oxxo_display_details":
            details = ["expires_after": 1_900_000_000, "hosted_voucher_url": "https://voucher.example", "number": "123"]
        case "boleto_display_details":
            details = ["number": "123", "expires_at": 1_900_000_000, "hosted_voucher_url": "https://voucher.example"]
        case "konbini_display_details":
            details = ["expires_at": 1_900_000_000, "hosted_voucher_url": "https://voucher.example"]
        case "multibanco_display_details":
            details = ["entity": "1", "reference": "2", "expires_at": 1_900_000_000, "hosted_voucher_url": "https://voucher.example"]
        case "verify_with_microdeposits":
            details = ["arrival_date": 1_900_000_000, "hosted_verification_url": "https://verify.example", "microdeposit_type": "amounts"]
        default:
            details = nil
        }
        var json: [String: Any] = ["type": type]
        json[type] = details
        return json
    }
}
