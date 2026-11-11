//
//  PaymentConfirmerParityTests.swift
//  StripePaymentSheetTests
//
//  Created by David Estes on 11/10/26.
//

import SafariServices
import XCTest

@testable@_spi(InternalOnlyAPI) import StripeCore
@testable@_spi(InternalOnlyAPI) import StripePayments
@testable@_spi(InternalOnlyAPI) import StripePaymentSheet

/// `PaymentConfirmer` against STPPaymentHandler, through the same scripted scenarios as the table harness.
///
/// This runs the engine's real code, not just `decide`: the state machine, `ResolvedNextAction`, the real
/// `PaymentSheetNextActionPerformer` with its polling-screen session (hosted by a recording container), and, for
/// `use_stripe_sdk` and for card and Link, the real STPPaymentHandler delegate. Only the UIKit edges are fakes: the
/// redirect presenter reports the customer back at once, STPPaymentHandler's `_redirectShim` does the same for the
/// delegate, and polling screens are canceled once shown, since they never appear on screen.
///
/// The native side is the table harness's: the real `confirmPaymentIntent`/`confirmSetupIntent`/`handleNextAction(for:)`,
/// the real post-return loop, and the real dispatch. Every difference must be one of `engineDifferences`, each a
/// deliberate decision written up in paymentsheet-confirm-engine-prototype.md.
extension ConfirmationMetadataParityTests {
    /// What the engine does differently from STPPaymentHandler, on purpose.
    static let engineDifferences: [KnownMismatch] = [
        // M1: a SetupIntent in requires_payment_method fails as a decline whichever way PaymentSheet came in. STPPaymentHandler
        // says `requiresPaymentMethodErrorCode` only through handleNextAction(for:) (SPH:942).
        KnownMismatch(id: "M1", count: 24) { $0.group == "after_confirm" && $0.scenario == "si/requires_payment_method/handle_next_action" },
        // M2: PayNow and PromptPay wait for their polling screen only after their QR next action, not after any next action.
        KnownMismatch(id: "M2", count: 4) { ["paynow", "promptpay"].contains($0.type) && $0.scenario.hasPrefix("pi/requires_action+redirect_to_url") },
        // M3: requires_confirmation after a next action succeeds (manual confirmation), whichever way PaymentSheet came in.
        // STPPaymentHandler's confirm path fails it and asserts (SPH:236). Card and Link get this through the delegate too,
        // because handleNextAction(for:)'s guard accepts it (SPH:482).
        KnownMismatch(id: "M3", count: 122) { $0.scenario.hasPrefix("pi/requires_confirmation") && $0.scenario.hasSuffix("/via_confirm") },
        // M5: a SetupIntent whose terminal next action (a voucher, microdeposits) is done succeeds whichever way PaymentSheet
        // came in. STPPaymentHandler's handleNextAction(for:) guard fails it (SPH:770).
        // M4: the engine doesn't load Alipay's legacy "Marlin" return URL before reading a PaymentIntent; STPPaymentHandler
        // does (SPH:1597). Alipay PaymentIntents run on Alipay+ (EVO), where the ping is a no-op
        // (~/stripe/worktrees/handoff/alipay-marlin-research.md, task #69).
        KnownMismatch(id: "M4", count: 2) { $0.type == "alipay" && $0.scenario.hasSuffix("/before_fetch") && $0.native == "ping" && $0.table == "none" },
        KnownMismatch(id: "M5", count: 2) { $0.scenario.hasPrefix("si/requires_action+") && $0.scenario.hasSuffix("/via_handle_next_action") },
        // F1, a deliberate fix of an STPPaymentHandler bug: closing Pix's instructions web view never cancels; the polling
        // screen finishes the payment, like PayNow and PromptPay, for PaymentIntents and SetupIntents. STPPaymentHandler
        // cancels while the screen is still up and drops its later success, because Pix was left out of the PayNow/PromptPay
        // exclusion by accident (SPH:1708 for PIs; the SI branch at SPH:1794 has no exclusion). Confirmed a bug in task
        // #62: ~/stripe/worktrees/handoff/pix-dismiss-investigation.md.
        KnownMismatch(id: "F1", count: 4) { $0.type == "pix" && $0.scenario.contains("requires_action+pix_display_qr_code") && $0.native == "cancel" && $0.table == "wait_for_next_action_screen" },
    ]

    @MainActor
    func testEngineMatchesSTPPaymentHandler() {
        var report = ParityReport()
        report.types = ConfirmationMetadata.nativeTypes.count
        engineAfterConfirm(&report)
        engineAfterNextAction(&report)
        engineDispatch(&report)

        let text = report.render(header: "ENGINE_PARITY", families: true, rules: Self.engineDifferences)
        print(text)
        if let home = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"] {
            try? text.write(toFile: "\(home)/stripe/worktrees/handoff/paymentsheet-confirm-engine-parity.txt", atomically: true, encoding: .utf8)
        }
        // Every difference is a known, deliberate one, and each still produces the same number of rows.
        for mismatch in report.mismatches {
            let rules = Self.engineDifferences.filter { $0.matches(mismatch) }
            XCTAssertEqual(rules.count, 1, "Unexplained engine difference: \(mismatch.key) native=\(mismatch.native) engine=\(mismatch.table)")
        }
        for rule in Self.engineDifferences {
            XCTAssertEqual(report.mismatches.filter(rule.matches).count, rule.count, "Engine difference \(rule.id) changed; update the doc")
        }
        // Every routed family is covered by the harness.
        for family in PaymentConfirmer.routedFamilies {
            XCTAssertFalse(family.types.isEmpty, "\(family) has no types")
            XCTAssertTrue(family.types.allSatisfy { (report.comparisonsByType[$0.identifier] ?? 0) > 0 }, "\(family) isn't fully covered")
        }
    }

    @MainActor
    func testDelegatedEventsCarryTheEnginesActionID() throws {
        for type: STPPaymentMethodType in [.card, .link] {
            // Given a card or Link PaymentIntent whose redirect_to_url next action goes to the STPPaymentHandler delegate
            let run = EngineRun(type: type)
            let intent = Fixtures.paymentIntent(id: run.id, type: type.identifier, status: "requires_action", nextAction: "redirect_to_url")
            run.client.paymentIntents = [Fixtures.paymentIntent(id: run.id, type: type.identifier, status: "succeeded", nextAction: nil)]
            let firstEvent = RecordingAnalyticsClient.shared.analytics.count
            // ...and a customer who comes back only once the web view is up, as in a real redirect (the harness's shim
            // returns at once, which can be before STPPaymentHandler presents the web view and logs that it did)
            let paymentHandler = run.paymentHandler
            paymentHandler._redirectShim = { _, returnURL, _ in
                func returnOnceShown() {
                    let shown = RecordingAnalyticsClient.shared.analytics[firstEvent...].contains { $0.event == STPAnalyticEvent.urlRedirectNextAction.rawValue && $0.params["handler"] == nil }
                    guard shown else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute: returnOnceShown)
                        return
                    }
                    _ = paymentHandler.handleURLCallback(returnURL!)
                }
                DispatchQueue.main.async(execute: returnOnceShown)
            }

            // When the engine handles it
            run.start(entry: "handle_next_action", intent: .paymentIntent(intent), returnURL: Self.confirmReturnURL)

            // Then the redirect events STPPaymentHandler logs itself carry the engine's action_id
            let delegated = RecordingAnalyticsClient.shared.analytics[firstEvent...].filter { $0.params["handler"] == nil }
            let redirectEvents = delegated.filter { $0.event.hasPrefix("stripeios.url_redirect_next_action") }
            XCTAssertEqual(redirectEvents.map(\.event), [STPAnalyticEvent.urlRedirectNextAction.rawValue, STPAnalyticEvent.urlRedirectNextActionCompleted.rawValue], type.identifier)
            for event in redirectEvents {
                XCTAssertEqual(event.params["action_id"] as? String, run.confirmer.actionID, "\(type.identifier) \(event.event)")
            }
            // ...the same action_id as the engine's own events
            let engineEvents = RecordingAnalyticsClient.shared.analytics[firstEvent...].filter { $0.params["handler"] as? String == PaymentConfirmer.analyticsHandler }
            XCTAssertFalse(engineEvents.isEmpty, type.identifier)
            XCTAssertTrue(engineEvents.allSatisfy { $0.params["action_id"] as? String == run.confirmer.actionID }, type.identifier)
            // ...and STPPaymentHandler forgets it once the call finishes
            XCTAssertNil(run.paymentHandler.actionID, type.identifier)
        }
    }

    // MARK: After confirm

    @MainActor
    func engineAfterConfirm(_ report: inout ParityReport) {
        STPAssertTestUtil.shouldSuppressNextSTPAlert = false
        for type in ConfirmationMetadata.nativeTypes {
            let metadata = ConfirmationMetadata.native(for: type)!
            for status in Self.paymentIntentStatuses {
                for entry in ["confirm", "handle_next_action"] {
                    let native = nativeAfterConfirmPaymentIntent(type: type, status: status, entry: entry)
                    let run = EngineRun(type: type)
                    let intent = Fixtures.paymentIntent(id: run.id, type: type.identifier, status: status, nextAction: nil)
                    run.client.confirmedPaymentIntent = intent
                    run.start(entry: entry, intent: .paymentIntent(intent), returnURL: nil)
                    report.compare("after_confirm", type, "pi/\(status)/\(entry)", native: native.description, table: run.decision.description, source: "engine")
                }
            }
            guard metadata.setupIntent != nil else { continue }
            for status in Self.setupIntentStatuses {
                for entry in ["confirm", "handle_next_action"] {
                    let native = nativeAfterConfirmSetupIntent(type: type, status: status, entry: entry)
                    let run = EngineRun(type: type)
                    let intent = Fixtures.setupIntent(id: run.id, type: type.identifier, status: status, nextAction: nil)
                    run.client.confirmedSetupIntent = intent
                    run.start(entry: entry, intent: .setupIntent(intent), returnURL: nil)
                    report.compare("after_confirm", type, "si/\(status)/\(entry)", native: native.description, table: run.decision.description, source: "engine")
                }
            }
        }
    }

    // MARK: After a next action

    @MainActor
    func engineAfterNextAction(_ report: inout ParityReport) {
        for native in runNativeLoops() {
            let metadata = ConfirmationMetadata.native(for: native.type)!
            let isDelegated = metadata.performer == .stripePaymentHandler || native.nextActionType == ConfirmationMetadata.stripeSDKNextActionType
            // STPPaymentHandler owns the budget once it has the payment, so an expired one can't be injected.
            if isDelegated && native.expiredBudget { continue }

            let run = EngineRun(type: native.type, webViewDismissed: native.webViewDismissed, expiredBudget: native.expiredBudget)
            let before = native.nextActionType ?? "redirect_to_url"
            let read = native.expiredBudget ? native.status : "succeeded"
            let intent: ConfirmingIntent
            switch native.intent {
            case .paymentIntent:
                intent = .paymentIntent(Fixtures.paymentIntent(id: run.id, type: native.type.identifier, status: "requires_action", nextAction: before))
                run.client.confirmedPaymentIntent = intent.paymentIntent
                run.client.paymentIntents = [
                    Fixtures.paymentIntent(id: run.id, type: native.type.identifier, status: native.status, nextAction: native.nextActionType),
                    Fixtures.paymentIntent(id: run.id, type: native.type.identifier, status: read, nextAction: native.nextActionType),
                ]
            case .setupIntent:
                intent = .setupIntent(Fixtures.setupIntent(id: run.id, type: native.type.identifier, status: "requires_action", nextAction: before))
                run.client.confirmedSetupIntent = intent.setupIntent
                run.client.setupIntents = [
                    Fixtures.setupIntent(id: run.id, type: native.type.identifier, status: native.status, nextAction: native.nextActionType),
                    Fixtures.setupIntent(id: run.id, type: native.type.identifier, status: read, nextAction: native.nextActionType),
                ]
            }
            run.start(entry: "confirm", intent: intent, returnURL: Self.confirmReturnURL)

            var nativeDecision = native.decision
            var engineDecision = run.decision
            // Refresh reads have no timeout, so STPPaymentHandler's budget can't be observed; compare only "it polled".
            if case .poll(-1) = nativeDecision, case .poll = engineDecision {
                engineDecision = .poll(seconds: -1)
            }
            if native.expiredBudget, case .poll = nativeDecision {
                nativeDecision = .poll(seconds: 0)
            }
            let scenario = native.scenario
            if nativeDecision == .succeed {
                for (entry, guarded) in native.guardedDecisions {
                    report.compare("after_next_action", native.type, "\(scenario)/via_\(entry)", native: guarded.description, table: engineDecision.description, source: "engine")
                }
            } else {
                report.compare("after_next_action", native.type, scenario, native: nativeDecision.description, table: engineDecision.description, source: "engine")
            }

            if let nativeFetch = native.client.fetches.first {
                report.compare("after_next_action", native.type, "\(scenario)/read_endpoint", native: nativeFetch.endpoint, table: run.client.fetches.first?.endpoint ?? "none", source: "engine")
            }
            if native.nextActionType == "alipay_handle_redirect" {
                report.compare("after_next_action", native.type, "\(scenario)/before_fetch", native: native.loadedMarlinURL ? "ping" : "none", table: run.loadedMarlinURL ? "ping" : "none", source: "engine")
            }
            if nativeDecision == .cancel {
                report.compare("after_next_action", native.type, "\(scenario)/on_cancel", native: native.canceledSource ? "cancel3DSSource" : "none", table: run.canceledSource ? "cancel3DSSource" : "none", source: "engine")
            }
        }
    }

    // MARK: Next action dispatch

    @MainActor
    func engineDispatch(_ report: inout ParityReport) {
        for type in ConfirmationMetadata.nativeTypes {
            let metadata = ConfirmationMetadata.native(for: type)!
            for nextActionType in metadata.nextActions.keys.sorted() {
                for confirmReturnURL in [Self.confirmReturnURL, nil] {
                    let (native, _, nativeContext) = nativeDispatchWithContext(type: type, nextActionType: nextActionType, confirmReturnURL: confirmReturnURL)
                    let run = EngineRun(type: type)
                    let intent = Fixtures.paymentIntent(id: run.id, type: type.identifier, status: "requires_action", nextAction: nextActionType)
                    run.client.paymentIntents = [Fixtures.paymentIntent(id: run.id, type: type.identifier, status: "succeeded", nextAction: nil)]
                    run.start(entry: "handle_next_action", intent: .paymentIntent(intent), returnURL: confirmReturnURL)
                    let scenario = "\(nextActionType)/\(confirmReturnURL == nil ? "no_return_url" : "return_url")"
                    report.compare("dispatch", type, scenario, native: Self.normalizedNativeDispatch(native, context: nativeContext), table: run.dispatchDescription, source: "engine")
                }
            }
        }
    }

    /// The native dispatch string with each polling screen described by the screen STPPaymentHandler's container builds.
    static func normalizedNativeDispatch(_ native: String, context: RecordingAuthenticationContext?) -> String {
        guard let pollingViewController = context?.pollingViewControllers.first, let type = context?.pollingTypes.first else {
            return native
        }
        return native.replacingOccurrences(of: "polling_screen(\(type.identifier))", with: "polling_screen(\(describe(pollingViewController.viewModel)))")
    }

    static func describe(_ viewModel: PollingViewModel) -> String {
        let deadline = abs(viewModel.deadline.timeIntervalSince1970 - 1_900_000_000) < 1
            ? "expires_at"
            : "\(Int(viewModel.deadline.timeIntervalSinceNow.rounded()))s"
        return "\(describeStrings(viewModel)), every \(Int(viewModel.retryInterval))s, countdown=\(viewModel.showsCountdown), deadline=\(deadline)"
    }

    /// The screen's text as shown, with a fixed time left.
    static func describeStrings(_ viewModel: PollingViewModel) -> String {
        let strings = [viewModel.title, viewModel.instructions(timeRemaining: "0:59"), viewModel.cancelButtonTitle, viewModel.failureTitle, viewModel.failureInstructions]
        return strings.map { "\"\($0)\"" }.joined(separator: " / ")
    }
}

// MARK: - One engine run

/// One payment through `PaymentConfirmer` with a type's default-table entry, scripted like the native runs.
@MainActor
final class EngineRun {
    let type: STPPaymentMethodType
    let id = Fixtures.nextID()
    let client = ScriptedAPIClient(publishableKey: "pk_test_123")
    let paymentHandler: STPPaymentHandler
    let host = HarnessPollingHost()
    let clock = FakePaymentConfirmerClock()
    let webViewDismissed: Bool
    private(set) var redirects: [ResolvedNextAction.Redirect] = []
    private(set) var delegateRedirects: [(URL, URL?)] = []
    private(set) var confirmer: PaymentConfirmer!
    private(set) var outcome: PaymentConfirmer.Outcome?

    init(type: STPPaymentMethodType, webViewDismissed: Bool = false, expiredBudget: Bool = false) {
        self.type = type
        self.webViewDismissed = webViewDismissed
        // A poll's first wait jumps past any budget, so the next read is after the deadline.
        clock.extraSleep = expiredBudget ? 1000 : 0
        paymentHandler = STPPaymentHandler(apiClient: client)
        paymentHandler.analyticsClient = RecordingAnalyticsClient.shared
        // The delegate's redirects: record them, then bring the customer back the same way the engine's presenter does.
        paymentHandler._redirectShim = { [weak self, weak paymentHandler] url, returnURL, _ in
            guard let self, let paymentHandler else { return }
            delegateRedirects.append((url, returnURL))
            DispatchQueue.main.async { [webViewDismissed] in
                if webViewDismissed {
                    paymentHandler.safariViewControllerDidFinish(SFSafariViewController(url: url))
                } else {
                    _ = paymentHandler.handleURLCallback(returnURL ?? url)
                }
            }
        }
        let performer = PaymentSheetNextActionPerformer(paymentHandler: paymentHandler, makeRedirectPresenter: { [unowned self] in
            HarnessRedirectPresenter(run: self)
        })
        confirmer = PaymentConfirmer(
            metadata: ConfirmationMetadata.native(for: type)!,
            policySource: .defaultTable,
            paymentMethodType: type.identifier,
            apiClient: client,
            performer: performer,
            api: client,
            clock: clock.clock,
            analyticsClient: RecordingAnalyticsClient.shared
        )
    }

    func recordRedirect(_ redirect: ResolvedNextAction.Redirect) {
        redirects.append(redirect)
    }

    /// Runs the payment to the end, through `confirm` (with the client's scripted confirm response) or `handleNextAction`.
    func start(entry: String, intent: ConfirmingIntent, returnURL: String?) {
        let confirmer = confirmer!
        let host = host
        // STPPaymentHandler's "succeeded must be a success state" guards assert when they reject a status (e.g. a SetupIntent
        // in requires_confirmation through handleNextAction(for:), SPH:779); the native harness suppresses them too.
        STPAssertTestUtil.shouldSuppressNextSTPAlert = true
        defer { STPAssertTestUtil.shouldSuppressNextSTPAlert = false }
        Task { @MainActor in
            if entry == "confirm" {
                let params: ConfirmingParams
                switch intent {
                case .paymentIntent(let paymentIntent):
                    let paymentIntentParams = STPPaymentIntentConfirmParams(clientSecret: paymentIntent.clientSecret)
                    paymentIntentParams.returnURL = returnURL
                    params = .paymentIntent(paymentIntentParams)
                case .setupIntent(let setupIntent):
                    let setupIntentParams = STPSetupIntentConfirmParams(clientSecret: setupIntent.clientSecret)
                    setupIntentParams.returnURL = returnURL
                    params = .setupIntent(setupIntentParams)
                }
                outcome = await confirmer.confirm(params, authenticationContext: host)
            } else {
                outcome = await confirmer.handleNextAction(for: intent, returnURL: returnURL, authenticationContext: host)
            }
        }
        // The engine runs one payment at a time, so wait for this one. STPPaymentHandler's polls take real seconds.
        let deadline = Date(timeIntervalSinceNow: 40)
        while outcome == nil && Date() < deadline {
            RunLoop.main.run(mode: .default, before: Date(timeIntervalSinceNow: 0.002))
        }
        XCTAssertNotNil(outcome, "The engine didn't finish \(type.identifier)")
    }

    var transitions: [PaymentConfirmer.State] { confirmer.transitions }

    var isDelegated: Bool {
        return transitions.contains { state in
            if case .performNextAction(let intent, _) = state {
                return (try? ResolvedNextAction(intent: intent, metadata: confirmer.metadata, confirmReturnURL: nil)) == .stripeSDK
            }
            return false
        }
    }

    /// The run in the table's terms. A first poll is reported as `poll(seconds)`, like the native runs.
    var decision: ConfirmationMetadata.Decision {
        if isDelegated {
            // STPPaymentHandler polled if it read twice; the second read's timeout is the budget left.
            if client.fetches.count >= 2 && clock.extraSleep == 0 {
                guard let timeout = client.fetches[1].timeout else { return .poll(seconds: -1) }
                let elapsed = client.fetches[1].date.timeIntervalSince(client.fetches[0].date)
                return .poll(seconds: Int((timeout.doubleValue + elapsed).rounded()))
            }
        } else if clock.extraSleep == 0 {
            for state in transitions {
                if case .wait(_, let progress) = state, let seconds = progress.pollSeconds {
                    return .poll(seconds: seconds)
                }
            }
        }
        if transitions.contains(where: { if case .awaitNextActionScreen = $0 { return true } else { return false } }) {
            return .waitForNextActionScreen
        }
        guard let outcome else {
            return .fail(.unexpectedStatus)
        }
        return ConfirmationMetadata.Decision(nativeResult: (outcome.result.paymentHandlerStatus, outcome.result.paymentHandlerError), fetchCount: 0)
    }

    /// What was performed, in the native dispatch's terms.
    var dispatchDescription: String {
        var parts: [String] = []
        let describeReturnURL = ConfirmationMetadataParityTests.describeReturnURL
        if let redirect = redirects.first, let url = redirect.appURL ?? redirect.webURL {
            parts.append("redirect(\(url.scheme == "alipay" ? "native_url" : "url"), return=\(describeReturnURL(redirect.returnURL)))")
        } else if let (url, returnURL) = delegateRedirects.first {
            parts.append("redirect(\(url.scheme == "alipay" ? "native_url" : "url"), return=\(describeReturnURL(returnURL)))")
        }
        if let pollingViewController = host.presented.first {
            parts.append("polling_screen(\(ConfirmationMetadataParityTests.describe(pollingViewController.viewModel)))")
        }
        if parts.isEmpty, let outcome {
            if outcome.result.paymentHandlerError?.code == STPPaymentHandlerErrorCode.missingReturnURL.rawValue {
                return "fail(missing_return_url)"
            }
            return ConfirmationMetadata.Decision(nativeResult: (outcome.result.paymentHandlerStatus, outcome.result.paymentHandlerError), fetchCount: 0).description
        }
        return parts.isEmpty ? "nothing" : parts.joined(separator: " ")
    }

    var canceledSource: Bool { NetworkRecorder.shared.contains("_\(id)/source_cancel") }
    var loadedMarlinURL: Bool { NetworkRecorder.shared.contains("/marlin/\(id)") }
}

/// The engine's redirect presenter in the harness: records the resolved redirect and reports the customer back at once,
/// by the return URL or by closing the web view.
@MainActor
final class HarnessRedirectPresenter: RedirectPresenting {
    private weak var run: EngineRun?

    init(run: EngineRun) {
        self.run = run
    }

    func redirect(
        _ redirect: ResolvedNextAction.Redirect,
        authenticationContext: STPAuthenticationContext,
        didOpen: @escaping (RedirectType) -> Void,
        didPresent: ((SFSafariViewController?) -> Void)?
    ) async -> RedirectResult {
        run?.recordRedirect(redirect)
        didOpen(.safariViewController)
        didPresent?(nil)
        return .returned(run?.webViewDismissed == true ? .safariViewController : .returnURLCallback)
    }

    func close() {}
}

/// A PaymentSheet container that records the polling screens it's given. They never appear, so they never poll; each
/// is canceled shortly after, which ends a payment that waits for it.
final class HarnessPollingHost: NSObject, PollingScreenHosting {
    private(set) var presented: [PollingViewController] = []
    let viewController = UIViewController()
    var pollingScreenAppearance: PaymentSheet.Appearance { .default }

    func authenticationPresentingViewController() -> UIViewController {
        return viewController
    }

    func present(_ authenticationViewController: UIViewController, completion: @escaping () -> Void) {}

    func dismiss(_ authenticationViewController: UIViewController, completion: (() -> Void)?) {
        completion?()
    }

    func presentPollingViewController(_ pollingViewController: PollingViewController, safariViewController: SFSafariViewController?) {
        presented.append(pollingViewController)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            pollingViewController.didTapCancel()
        }
    }
}

extension ParityReport {
    /// The report, with each family's comparisons and differences when `families` is set.
    @MainActor
    func render(header: String, families: Bool, rules: [ConfirmationMetadataParityTests.KnownMismatch]) -> String {
        var lines = ["\(header) types=\(types) comparisons=\(comparisons) differences=\(mismatches.count)"]
        if families {
            for family in PaymentConfirmerFamily.allCases {
                let typeIDs = Set(family.types.map(\.identifier))
                let comparisons = comparisonsByType.filter { typeIDs.contains($0.key) }.values.reduce(0, +)
                let differences = mismatches.filter { typeIDs.contains($0.type) }
                let byRule = rules.map { rule in "\(rule.id)=\(differences.filter(rule.matches).count)" }.joined(separator: " ")
                let unexplained = differences.filter { mismatch in !rules.contains { $0.matches(mismatch) } }.count
                let routed = PaymentConfirmer.routedFamilies.contains(family) ? "yes" : "no"
                lines.append("FAMILY \(family.rawValue) types=\(typeIDs.count) comparisons=\(comparisons) differences=\(differences.count) [\(byRule)] unexplained=\(unexplained) routed=\(routed) (\(family.types.map(\.identifier).joined(separator: ",")))")
            }
        }
        lines += notes.map { "NOTE \($0)" }
        lines += mismatches.map { "DIFFERENCE \($0.key) native=\($0.native) engine=\($0.table) [\($0.source)]" }
        return lines.joined(separator: "\n")
    }
}
