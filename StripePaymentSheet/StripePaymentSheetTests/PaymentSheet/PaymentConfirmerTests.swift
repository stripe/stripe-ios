//
//  PaymentConfirmerTests.swift
//  StripePaymentSheetTests
//
//  Created by David Estes on 11/10/26.
//

import OHHTTPStubs
import OHHTTPStubsSwift
import SafariServices
import XCTest

@testable@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripeCoreTestUtils
@testable@_spi(InternalOnlyAPI) import StripePayments
@testable@_spi(InternalOnlyAPI) import StripePaymentSheet
@testable@_spi(InternalOnlyAPI) import StripePaymentsTestUtils

/// The engine's state machine with a server spec (what server-driven payment methods confirm with).
@MainActor
final class PaymentConfirmerTests: XCTestCase {
    let api = StubPaymentConfirmerAPI()
    let performer = FakeNextActionPerformer()
    let clock = FakePaymentConfirmerClock()
    let analyticsClient = STPTestingAnalyticsClient()

    func makeConfirmer(
        retrieval: ServerDrivenConfirmSpec.Retrieval = .retrieve,
        processing: ServerDrivenConfirmSpec.ProcessingOutcome = .succeed,
        requiresAction: ServerDrivenConfirmSpec.RequiresActionOutcome = .cancel,
        pollSeconds: Int = 0
    ) -> PaymentConfirmer {
        let spec = ServerDrivenConfirmSpec(nextActions: [.redirectToURL], retrieval: retrieval, processing: processing, requiresAction: requiresAction, pollSeconds: pollSeconds)
        return makeConfirmer(metadata: ConfirmationMetadata(serverSpec: spec, paymentMethodDataType: "demo_pay"), policySource: .server, type: "demo_pay")
    }

    func makeConfirmer(metadata: ConfirmationMetadata, policySource: PaymentConfirmer.PolicySource = .defaultTable, type: String) -> PaymentConfirmer {
        return PaymentConfirmer(
            metadata: metadata,
            policySource: policySource,
            paymentMethodType: type,
            apiClient: STPAPIClient(publishableKey: "pk_test"),
            performer: performer,
            api: api,
            clock: clock.clock,
            analyticsClient: analyticsClient
        )
    }

    func confirm(_ confirmer: PaymentConfirmer, returnURL: String? = nil) async -> PaymentSheetResult {
        let params = STPPaymentIntentConfirmParams(clientSecret: PaymentConfirmerFixtures.clientSecret)
        params.returnURL = returnURL
        return await confirmer.confirm(.paymentIntent(params), authenticationContext: self).result
    }

    // MARK: - Processing

    func testProcessingSucceeds() async {
        // Given a spec where processing is success, and confirmation returns a processing intent
        api.confirmResults = [.success(PaymentConfirmerFixtures.paymentIntent(status: "processing"))]

        // When the payment is confirmed
        let result = await confirm(makeConfirmer(processing: .succeed))

        // Then it completes without fetching the intent or performing a next action
        assertCompleted(result)
        XCTAssertEqual(api.calls, ["confirm"])
        XCTAssertTrue(performer.performed.isEmpty)
    }

    func testProcessingFails() async {
        // Given a spec where processing fails
        api.confirmResults = [.success(PaymentConfirmerFixtures.paymentIntent(status: "processing"))]

        // When the payment is confirmed
        let result = await confirm(makeConfirmer(processing: .fail))

        // Then it fails with STPPaymentHandler's intent status error
        assertFailed(result, code: .intentStatusErrorCode)
        XCTAssertEqual(api.calls, ["confirm"])
    }

    func testProcessingPollsThenFailsAfterTimeout() async {
        // Given a spec that polls processing intents for 2 seconds, and an intent that stays processing
        api.confirmResults = [.success(PaymentConfirmerFixtures.paymentIntent(status: "processing"))]
        api.fetchResults = Array(repeating: .success(PaymentConfirmerFixtures.paymentIntent(status: "processing")), count: 10)

        // When the payment is confirmed
        let result = await confirm(makeConfirmer(processing: .poll, pollSeconds: 2))

        // Then it polls once a second until the deadline, then fails
        assertFailed(result, code: .intentStatusErrorCode)
        XCTAssertEqual(api.calls, ["confirm", "retrieve", "retrieve"])
        XCTAssertEqual(clock.sleeps, [1, 1])
    }

    // MARK: - Redirects and polling

    func testRedirectThenPollingSucceeds() async {
        // Given confirmation returns a redirect, and the intent succeeds on the third fetch after the customer returns
        api.confirmResults = [.success(PaymentConfirmerFixtures.redirectIntent())]
        api.fetchResults = [
            .success(PaymentConfirmerFixtures.redirectIntent()),
            .success(PaymentConfirmerFixtures.redirectIntent()),
            .success(PaymentConfirmerFixtures.paymentIntent(status: "succeeded")),
        ]
        performer.redirectResult = .returned(.returnURLCallback)

        // When the payment is confirmed with a spec that polls requires_action for 5 seconds
        let confirmer = makeConfirmer(requiresAction: .poll, pollSeconds: 5)
        let result = await confirm(confirmer)

        // Then it redirects to the next action's URL with its return URL
        assertCompleted(result)
        XCTAssertEqual(performer.redirects.map(\.webURL), [PaymentConfirmerFixtures.redirectURL])
        XCTAssertEqual(performer.redirects.map(\.returnURL), [PaymentConfirmerFixtures.returnURL])
        // ...and fetches until the intent succeeds, a second apart
        XCTAssertEqual(api.calls, ["confirm", "retrieve", "retrieve", "retrieve"])
        XCTAssertEqual(clock.sleeps, [1, 1])
        // ...passing through the expected states
        XCTAssertEqual(confirmer.transitions.map(\.name), ["confirm", "evaluate", "performNextAction", "fetch", "evaluate", "wait", "fetch", "evaluate", "wait", "fetch", "evaluate", "finished"])
    }

    func testPollingTimeoutCancels() async {
        // Given an intent that stays requires_action after the customer returns
        api.confirmResults = [.success(PaymentConfirmerFixtures.redirectIntent())]
        api.fetchResults = Array(repeating: .success(PaymentConfirmerFixtures.redirectIntent()), count: 10)

        // When the payment is confirmed with a spec that polls requires_action for 3 seconds
        let result = await confirm(makeConfirmer(requiresAction: .poll, pollSeconds: 3))

        // Then it fetches at 0, 1, 2 and 3 seconds, then cancels
        assertCanceled(result)
        XCTAssertEqual(api.calls, ["confirm", "retrieve", "retrieve", "retrieve", "retrieve"])
        // ...and logs that polling ran out of time
        let pollingExceeded = analyticsClient.events.first { $0.event == .paymentHandlerCanceledPollingDurationExceeded }
        XCTAssertEqual(pollingExceeded?.params["duration"] as? TimeInterval, 3)
        XCTAssertEqual(pollingExceeded?.params["payment_method_type"] as? String, "demo_pay")
    }

    func testCanceledRedirect() async {
        // Given the customer closes the web view without paying, so the intent is still requires_action
        api.confirmResults = [.success(PaymentConfirmerFixtures.redirectIntent())]
        api.fetchResults = [.success(PaymentConfirmerFixtures.redirectIntent())]
        performer.redirectResult = .returned(.safariViewController)

        // When the payment is confirmed with a spec that cancels requires_action after a redirect
        let result = await confirm(makeConfirmer(requiresAction: .cancel))

        // Then it fetches once and cancels
        assertCanceled(result)
        XCTAssertEqual(api.calls, ["confirm", "retrieve"])
        XCTAssertTrue(clock.sleeps.isEmpty)
    }

    func testRefreshVsRetrieve() async {
        for (retrieval, expectedCall) in [(ServerDrivenConfirmSpec.Retrieval.retrieve, "retrieve"), (.refresh, "refresh")] {
            // Given a redirect that succeeds after the customer returns
            api.calls = []
            api.confirmResults = [.success(PaymentConfirmerFixtures.redirectIntent())]
            api.fetchResults = [.success(PaymentConfirmerFixtures.paymentIntent(status: "succeeded"))]

            // When the payment is confirmed with each retrieval
            let result = await confirm(makeConfirmer(retrieval: retrieval))

            // Then it fetches the intent the way the spec says
            assertCompleted(result)
            XCTAssertEqual(api.calls, ["confirm", expectedCall])
        }
    }

    func testRefreshPollsWithRefresh() async {
        // Given an intent that's still requires_action for two refreshes after the customer returns, then succeeds
        api.confirmResults = [.success(PaymentConfirmerFixtures.redirectIntent())]
        api.fetchResults = [
            .success(PaymentConfirmerFixtures.redirectIntent()),
            .success(PaymentConfirmerFixtures.redirectIntent()),
            .success(PaymentConfirmerFixtures.paymentIntent(status: "succeeded")),
        ]

        // When the payment is confirmed with a spec that refreshes and polls requires_action
        let result = await confirm(makeConfirmer(retrieval: .refresh, requiresAction: .poll, pollSeconds: 5))

        // Then every read after the redirect is a refresh, a second apart
        assertCompleted(result)
        XCTAssertEqual(api.calls, ["confirm", "refresh", "refresh", "refresh"])
        XCTAssertEqual(clock.sleeps, [1, 1])
    }

    func testRefreshProcessingAfterRedirectPollsThenFails() async {
        // Given an intent that's processing after the customer returns, and stays processing
        api.confirmResults = [.success(PaymentConfirmerFixtures.redirectIntent())]
        api.fetchResults = Array(repeating: .success(PaymentConfirmerFixtures.paymentIntent(status: "processing")), count: 10)

        // When the payment is confirmed with a spec that refreshes and polls processing for 2 seconds
        let result = await confirm(makeConfirmer(retrieval: .refresh, processing: .poll, pollSeconds: 2))

        // Then it refreshes until the deadline, then fails
        assertFailed(result, code: .intentStatusErrorCode)
        XCTAssertEqual(api.calls, ["confirm", "refresh", "refresh", "refresh"])
    }

    func testRefreshOnlyAppliesAfterANextAction() async {
        // Given confirmation returns a processing intent, which succeeds on the second read
        api.confirmResults = [.success(PaymentConfirmerFixtures.paymentIntent(status: "processing"))]
        api.fetchResults = [
            .success(PaymentConfirmerFixtures.paymentIntent(status: "processing")),
            .success(PaymentConfirmerFixtures.paymentIntent(status: "succeeded")),
        ]

        // When the payment is confirmed with a spec that refreshes and polls processing
        let result = await confirm(makeConfirmer(retrieval: .refresh, processing: .poll, pollSeconds: 5))

        // Then it retrieves, since `intent_retrieval` is how to read the intent after a next action
        assertCompleted(result)
        XCTAssertEqual(api.calls, ["confirm", "retrieve", "retrieve"])
    }

    func testRefreshErrorRetriesOnceThenFails() async {
        // Given every refresh after the redirect fails
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)
        api.confirmResults = [.success(PaymentConfirmerFixtures.redirectIntent())]
        api.fetchResults = [.failure(networkError), .failure(networkError)]

        // When the payment is confirmed with a spec that refreshes and doesn't poll
        let result = await confirm(makeConfirmer(retrieval: .refresh))

        // Then it refreshes again once, then fails with the error
        guard case .failed(let error) = result else {
            return XCTFail("Expected failure, got \(result)")
        }
        XCTAssertEqual(error as NSError, networkError)
        XCTAssertEqual(api.calls, ["confirm", "refresh", "refresh"])
    }

    func testPollWithZeroSecondsDoesntReadAgain() async {
        // Given an intent that's still requires_action after the customer returns
        api.confirmResults = [.success(PaymentConfirmerFixtures.redirectIntent())]
        api.fetchResults = Array(repeating: .success(PaymentConfirmerFixtures.redirectIntent()), count: 10)

        // When the payment is confirmed with a spec that polls requires_action for 0 seconds
        let result = await confirm(makeConfirmer(requiresAction: .poll, pollSeconds: 0))

        // Then it reads the intent once after the redirect, doesn't read it again, and cancels
        assertCanceled(result)
        XCTAssertEqual(api.calls, ["confirm", "retrieve"])
        XCTAssertTrue(clock.sleeps.isEmpty)
    }

    func testProcessingPollWithZeroSecondsFailsWithoutReading() async {
        // Given confirmation returns a processing intent
        api.confirmResults = [.success(PaymentConfirmerFixtures.paymentIntent(status: "processing"))]

        // When the payment is confirmed with a spec that polls processing for 0 seconds
        let result = await confirm(makeConfirmer(processing: .poll, pollSeconds: 0))

        // Then it fails without reading the intent
        assertFailed(result, code: .intentStatusErrorCode)
        XCTAssertEqual(api.calls, ["confirm"])
    }

    func testRequiresActionSucceedsAfterRedirect() async {
        // Given an intent that's still requires_action after the customer returns, e.g. a voucher they pay later
        api.confirmResults = [.success(PaymentConfirmerFixtures.redirectIntent())]
        api.fetchResults = [.success(PaymentConfirmerFixtures.redirectIntent())]

        // When the payment is confirmed with a spec where requires_action after the next action is success
        let result = await confirm(makeConfirmer(requiresAction: .succeed))

        // Then it completes after one read
        assertCompleted(result)
        XCTAssertEqual(api.calls, ["confirm", "retrieve"])
    }

    func testRedirectThatCantBeShownFails() async {
        // Given the redirect can't be presented
        api.confirmResults = [.success(PaymentConfirmerFixtures.redirectIntent())]
        performer.redirectResult = .failed(PaymentConfirmer.error(.requiresAuthenticationContextErrorCode))

        // When the payment is confirmed
        let result = await confirm(makeConfirmer())

        // Then it fails with the presenter's error, without fetching the intent
        assertFailed(result, code: .requiresAuthenticationContextErrorCode)
        XCTAssertEqual(api.calls, ["confirm"])
    }

    // MARK: - Next actions

    func testUnknownNextActionFailsCleanly() async {
        // Given confirmation returns a next action the spec doesn't list
        api.confirmResults = [.success(PaymentConfirmerFixtures.paymentIntent(status: "requires_action", nextAction: ["type": "display_bank_transfer_instructions"]))]

        // When the payment is confirmed (reporting it as an unexpected error asserts in debug builds)
        STPAssertTestUtil.shouldSuppressNextSTPAlert = true
        let result = await confirm(makeConfirmer())

        // Then it fails without performing anything or fetching
        assertFailed(result, code: .unsupportedAuthenticationErrorCode)
        XCTAssertTrue(performer.performed.isEmpty)
        XCTAssertEqual(api.calls, ["confirm"])
        // ...and reports the type and the next action, so a gap in the server's table shows up
        assertReportedUnsupportedNextAction(paymentMethodType: "demo_pay", nextActionType: "display_bank_transfer_instructions")
    }

    func testNextActionTheEntryDoesNotListFailsAndIsReported() async {
        // Given BLIK, whose entry lists only blik_authorize, and confirmation returns a redirect_to_url
        api.confirmResults = [.success(PaymentConfirmerFixtures.paymentIntent(status: "requires_action", type: "blik", nextAction: ["type": "redirect_to_url", "redirect_to_url": ["url": "https://bank.example", "return_url": "x://y"]]))]
        let confirmer = makeConfirmer(metadata: ConfirmationMetadata.native(for: .blik)!, type: "blik")

        // When the payment is confirmed
        STPAssertTestUtil.shouldSuppressNextSTPAlert = true
        let result = await confirm(confirmer)

        // Then it fails as an unsupported next action without redirecting, unlike STPPaymentHandler (U1)
        assertFailed(result, code: .unsupportedAuthenticationErrorCode)
        XCTAssertTrue(performer.performed.isEmpty)
        // ...and reports it
        assertReportedUnsupportedNextAction(paymentMethodType: "blik", nextActionType: "redirect_to_url")
    }

    func testNextActionTheEntryDoesNotListFailsAndIsReportedViaHandleNextAction() async {
        // Given a BLIK intent confirmed elsewhere, with a redirect_to_url next action
        let intent = PaymentConfirmerFixtures.paymentIntent(status: "requires_action", type: "blik", nextAction: ["type": "redirect_to_url", "redirect_to_url": ["url": "https://bank.example", "return_url": "x://y"]])
        let confirmer = makeConfirmer(metadata: ConfirmationMetadata.native(for: .blik)!, type: "blik")

        // When PaymentSheet handles its next action
        STPAssertTestUtil.shouldSuppressNextSTPAlert = true
        let result = await confirmer.handleNextAction(for: intent, returnURL: nil, authenticationContext: self).result

        // Then it fails the same way, and reports it
        assertFailed(result, code: .unsupportedAuthenticationErrorCode)
        XCTAssertTrue(performer.performed.isEmpty)
        assertReportedUnsupportedNextAction(paymentMethodType: "blik", nextActionType: "redirect_to_url")
    }

    func assertReportedUnsupportedNextAction(paymentMethodType: String, nextActionType: String, file: StaticString = #filePath, line: UInt = #line) {
        let reported = analyticsClient.events.filter { $0.event == .unexpectedPaymentSheetConfirmationError }
        XCTAssertEqual(reported.count, 1, file: file, line: line)
        XCTAssertEqual(reported.first?.params["payment_method_type"] as? String, paymentMethodType, file: file, line: line)
        XCTAssertEqual(reported.first?.params["next_action_type"] as? String, nextActionType, file: file, line: line)
        XCTAssertEqual(reported.first?.params["handler"] as? String, PaymentConfirmer.analyticsHandler, file: file, line: line)
    }

    func testHandleNextActionForConfirmedIntent() async {
        // Given an intent the merchant's server already confirmed, which needs a redirect
        api.fetchResults = [.success(PaymentConfirmerFixtures.paymentIntent(status: "succeeded"))]

        // When its next action is handled
        let result = await makeConfirmer().handleNextAction(for: .paymentIntent(PaymentConfirmerFixtures.redirectIntent()), returnURL: nil, authenticationContext: self).result

        // Then it redirects and fetches without confirming
        assertCompleted(result)
        XCTAssertEqual(performer.redirects.count, 1)
        XCTAssertEqual(api.calls, ["retrieve"])
        // ...and logs STPPaymentHandler's events with the real type, the engine and where the policy came from
        let events = analyticsClient.events.map(\.event)
        XCTAssertEqual(events, [.paymentHandlerHandleNextActionStarted, .urlRedirectNextAction, .urlRedirectNextActionCompleted, .paymentHandlerHandleNextActionFinished])
        let finished = analyticsClient.events.last
        XCTAssertEqual(finished?.params["payment_method_type"] as? String, "demo_pay")
        XCTAssertEqual(finished?.params["handler"] as? String, "paymentsheet_engine")
        XCTAssertEqual(finished?.params["spec_source"] as? String, "server")
        XCTAssertEqual(finished?.params["presenter"] as? String, "redirect")
        XCTAssertEqual(finished?.params["status"] as? String, "succeeded")
        XCTAssertEqual(finished?.params["intent_id"] as? String, "pi_123")
    }

    func testHandleNextActionRejectsRequiresConfirmation() async {
        // Given an intent that wasn't confirmed
        let intent = PaymentConfirmerFixtures.paymentIntent(status: "requires_confirmation")

        // When its next action is handled
        let result = await makeConfirmer().handleNextAction(for: intent, returnURL: nil, authenticationContext: self).result

        // Then it fails like STPPaymentHandler.handleNextAction(for:) (SPH:510), without a read
        assertFailed(result, code: .intentStatusErrorCode)
        XCTAssertTrue(api.calls.isEmpty)
    }

    // MARK: - Errors

    func testConfirmErrorFails() async {
        // Given confirmation fails with an API error
        let apiError = NSError(domain: STPError.stripeDomain, code: STPErrorCode.apiError.rawValue)
        api.confirmResults = [.failure(apiError)]

        // When the payment is confirmed
        let result = await confirm(makeConfirmer())

        // Then it fails with that error
        guard case .failed(let error) = result else {
            return XCTFail("Expected failure, got \(result)")
        }
        XCTAssertEqual(error as NSError, apiError)
    }

    func testFetchErrorRetriesOnceThenFails() async {
        // Given every fetch after the redirect fails
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        api.confirmResults = [.success(PaymentConfirmerFixtures.redirectIntent())]
        api.fetchResults = [.failure(networkError), .failure(networkError)]

        // When the payment is confirmed with a spec that doesn't poll
        let result = await confirm(makeConfirmer())

        // Then it retries once, a second later, then fails with the error
        guard case .failed(let error) = result else {
            return XCTFail("Expected failure, got \(result)")
        }
        XCTAssertEqual(error as NSError, networkError)
        XCTAssertEqual(api.calls, ["confirm", "retrieve", "retrieve"])
        XCTAssertEqual(clock.sleeps, [1])
    }

    func testDeclineAfterRedirectFails() async {
        // Given the customer was declined in the redirect
        api.confirmResults = [.success(PaymentConfirmerFixtures.redirectIntent())]
        api.fetchResults = [.success(PaymentConfirmerFixtures.paymentIntent(status: "requires_payment_method", lastPaymentError: ["type": "invalid_request_error", "code": "payment_method_provider_decline"]))]

        // When the payment is confirmed
        let result = await confirm(makeConfirmer())

        // Then it fails with STPPaymentHandler's payment error and the decline code
        assertFailed(result, code: .paymentErrorCode)
    }

    func testRequiresPaymentMethodRightAfterConfirmMatchesSTPPaymentHandler() async {
        // Given confirmation leaves the intent requires_payment_method (L2: the spike failed it as a decline)
        api.confirmResults = [.success(PaymentConfirmerFixtures.paymentIntent(status: "requires_payment_method"))]

        // When the payment is confirmed
        let result = await confirm(makeConfirmer())

        // Then it fails like STPPaymentHandler (SPH:906)
        assertFailed(result, code: .requiresPaymentMethodErrorCode)
    }

    func testRequiresConfirmationRightAfterConfirmMatchesSTPPaymentHandler() async {
        // Given confirmation leaves the intent requires_confirmation (L1: the spike succeeded it)
        api.confirmResults = [.success(PaymentConfirmerFixtures.paymentIntent(status: "requires_confirmation"))]

        // When the payment is confirmed
        let result = await confirm(makeConfirmer())

        // Then it fails like STPPaymentHandler, whose success guard rejects it (SPH:236)
        assertFailed(result, code: .intentStatusErrorCode)
    }

    func testSpecFromWireFields() throws {
        func spec(_ postConfirm: [String: Any]) throws -> ServerDrivenConfirmSpec {
            let json = ServerDrivenPaymentMethodFixtures.json { $0[jsonDict: "confirm"]?["post_confirm"] = postConfirm }
            return try ServerDrivenPaymentMethodFixtures.serverDrivenPaymentMethod(json).confirmSpec
        }
        // Each post_confirm field maps 1:1
        let cases: [([String: Any], ServerDrivenConfirmSpec)] = [
            (
                ["intent_retrieval": "retrieve", "on_processing": "succeed", "on_requires_action": "poll", "poll_seconds": 5],
                .init(nextActions: [.redirectToURL], retrieval: .retrieve, processing: .succeed, requiresAction: .poll, pollSeconds: 5)
            ),
            (
                ["intent_retrieval": "refresh", "on_processing": "fail", "on_requires_action": "cancel", "poll_seconds": 0],
                .init(nextActions: [.redirectToURL], retrieval: .refresh, processing: .fail, requiresAction: .cancel, pollSeconds: 0)
            ),
            (
                ["intent_retrieval": "retrieve", "on_processing": "poll", "on_requires_action": "succeed", "poll_seconds": 60],
                .init(nextActions: [.redirectToURL], retrieval: .retrieve, processing: .poll, requiresAction: .succeed, pollSeconds: 60)
            ),
        ]
        for (postConfirm, expected) in cases {
            XCTAssertEqual(try spec(postConfirm), expected, "\(postConfirm)")
        }

        // next_actions maps each entry's type, and may be empty
        let noNextActions = ServerDrivenPaymentMethodFixtures.json { $0[jsonDict: "confirm"]?["next_actions"] = [[String: Any]]() }
        XCTAssertEqual(try ServerDrivenPaymentMethodFixtures.serverDrivenPaymentMethod(noNextActions).confirmSpec.nextActions, [])
    }

    // MARK: - Helpers

    func assertCompleted(_ result: PaymentSheetResult, file: StaticString = #filePath, line: UInt = #line) {
        guard case .completed = result else {
            return XCTFail("Expected completed, got \(result)", file: file, line: line)
        }
    }

    func assertCanceled(_ result: PaymentSheetResult, file: StaticString = #filePath, line: UInt = #line) {
        guard case .canceled = result else {
            return XCTFail("Expected canceled, got \(result)", file: file, line: line)
        }
    }

    func assertFailed(_ result: PaymentSheetResult, code: STPPaymentHandlerErrorCode, file: StaticString = #filePath, line: UInt = #line) {
        guard case .failed(let error) = result else {
            return XCTFail("Expected failure, got \(result)", file: file, line: line)
        }
        XCTAssertEqual((error as NSError).domain, STPPaymentHandler.errorDomain, file: file, line: line)
        XCTAssertEqual((error as NSError).code, code.rawValue, file: file, line: line)
    }
}

extension PaymentConfirmerTests: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
    }
}

// MARK: - Native types, SetupIntents and the primitives

/// The engine with default-table entries: one test per primitive, SetupIntents, and the STPPaymentHandler delegate.
@MainActor
final class PaymentConfirmerNativeTests: XCTestCase {
    let api = StubPaymentConfirmerAPI()
    let performer = FakeNextActionPerformer()
    let clock = FakePaymentConfirmerClock()

    func makeConfirmer(_ type: STPPaymentMethodType) -> PaymentConfirmer {
        return PaymentConfirmer(
            metadata: ConfirmationMetadata.native(for: type)!,
            policySource: .defaultTable,
            paymentMethodType: type.identifier,
            apiClient: STPAPIClient(publishableKey: "pk_test"),
            performer: performer,
            api: api,
            clock: clock.clock,
            analyticsClient: STPTestingAnalyticsClient()
        )
    }

    func confirmPaymentIntent(_ type: STPPaymentMethodType, returnURL: String? = PaymentConfirmerFixtures.confirmReturnURL) async -> PaymentConfirmer.Outcome {
        let params = STPPaymentIntentConfirmParams(clientSecret: PaymentConfirmerFixtures.clientSecret)
        params.returnURL = returnURL
        return await makeConfirmer(type).confirm(.paymentIntent(params), authenticationContext: self)
    }

    func testRedirectProcessingRightAfterConfirmFailsButPollsAfterReturn() async {
        // Given iDEAL, whose processing isn't success
        // When confirmation returns processing
        api.confirmResults = [.success(PaymentConfirmerFixtures.paymentIntent(status: "processing", type: "ideal"))]
        let afterConfirm = await confirmPaymentIntent(.iDEAL).result
        // Then it fails right away, like STPPaymentHandler (SPH:1098)
        XCTAssertEqual(afterConfirm.errorCode, STPPaymentHandlerErrorCode.intentStatusErrorCode.rawValue)

        // When the intent is processing after the customer returns from the redirect
        api.calls = []
        api.confirmResults = [.success(PaymentConfirmerFixtures.redirectIntent(type: "ideal"))]
        api.fetchResults = [
            .success(PaymentConfirmerFixtures.paymentIntent(status: "processing", type: "ideal")),
            .success(PaymentConfirmerFixtures.paymentIntent(status: "succeeded", type: "ideal")),
        ]
        let outcome = await confirmPaymentIntent(.iDEAL)

        // Then it polls (for up to 30s) and completes
        XCTAssertEqual(outcome.result, .completed)
        XCTAssertEqual(api.calls, ["confirm", "retrieve", "retrieve"])
        XCTAssertEqual(outcome.intent?.paymentIntent?.status, .succeeded)
    }

    func testVoucherSucceedsWhileRequiresAction() async {
        // Given OXXO's voucher next action
        api.confirmResults = [.success(PaymentConfirmerFixtures.paymentIntent(status: "requires_action", type: "oxxo", nextAction: ["type": "oxxo_display_details", "oxxo_display_details": ["hosted_voucher_url": "https://voucher.example", "expires_after": 1_900_000_000]]))]
        api.fetchResults = [.success(PaymentConfirmerFixtures.paymentIntent(status: "requires_action", type: "oxxo", nextAction: ["type": "oxxo_display_details", "oxxo_display_details": ["hosted_voucher_url": "https://voucher.example", "expires_after": 1_900_000_000]]))]
        performer.redirectResult = .returned(.safariViewController)

        // When the payment is confirmed and the customer closes the voucher
        let result = await confirmPaymentIntent(.OXXO).result

        // Then the voucher opened in a web view with no return URL, and requires_action means success (SPH:2134)
        XCTAssertEqual(result, .completed)
        XCTAssertEqual(performer.redirects, [.init(appURL: URL(string: "https://voucher.example"), webURL: URL(string: "https://voucher.example"), returnURL: nil, useWebAuthSession: false, followRedirects: false)])
        XCTAssertEqual(api.calls, ["confirm", "retrieve"])
    }

    func testMicrodepositsSucceedWithoutAFetch() async {
        // Given a US bank account SetupIntent waiting on microdeposits
        let setupIntent = PaymentConfirmerFixtures.setupIntent(status: "requires_action", type: "us_bank_account", nextAction: ["type": "verify_with_microdeposits", "verify_with_microdeposits": ["arrival_date": 1_900_000_000, "hosted_verification_url": "https://verify.example", "microdeposit_type": "amounts"]])

        // When its next action is handled (deferred, server-side confirmation)
        let result = await makeConfirmer(.USBankAccount).handleNextAction(for: .setupIntent(setupIntent), returnURL: nil, authenticationContext: self).result

        // Then there's nothing to show and it succeeds without a read. STPPaymentHandler fails this (M5, SPH:770).
        XCTAssertEqual(result, .completed)
        XCTAssertEqual(performer.performed, [.none])
        XCTAssertTrue(api.calls.isEmpty)
    }

    func testSetupIntentRedirect() async {
        // Given an iDEAL SetupIntent that needs a redirect
        api.confirmResults = [.success(.setupIntent(PaymentConfirmerFixtures.setupIntent(status: "requires_action", type: "ideal", nextAction: PaymentConfirmerFixtures.redirectNextAction)))]
        api.fetchResults = [.success(.setupIntent(PaymentConfirmerFixtures.setupIntent(status: "succeeded", type: "ideal", nextAction: nil)))]

        // When it's confirmed
        let params = STPSetupIntentConfirmParams(clientSecret: "seti_123_secret_456")
        let outcome = await makeConfirmer(.iDEAL).confirm(.setupIntent(params), authenticationContext: self)

        // Then it redirects, reads the SetupIntent and completes
        XCTAssertEqual(outcome.result, .completed)
        XCTAssertEqual(performer.redirects.count, 1)
        XCTAssertEqual(api.calls, ["confirm", "retrieve"])
        XCTAssertEqual(outcome.intent?.setupIntent?.status, .succeeded)
    }

    func testSetupIntentProcessingFails() async {
        // Given SEPA, whose PaymentIntent processing is success
        api.confirmResults = [.success(.setupIntent(PaymentConfirmerFixtures.setupIntent(status: "processing", type: "sepa_debit", nextAction: nil)))]

        // When its SetupIntent is processing right after confirm
        let outcome = await makeConfirmer(.SEPADebit).confirm(.setupIntent(STPSetupIntentConfirmParams(clientSecret: "seti_123_secret_456")), authenticationContext: self)

        // Then it fails: a processing SetupIntent always fails (SPH:1026)
        XCTAssertEqual(outcome.result.errorCode, STPPaymentHandlerErrorCode.intentStatusErrorCode.rawValue)
    }

    func testPollingScreenFinishesThePayment() async {
        // Given BLIK's next action, and a polling screen that sees success
        api.confirmResults = [.success(PaymentConfirmerFixtures.paymentIntent(status: "requires_action", type: "blik", nextAction: ["type": "blik_authorize", "blik_authorize": [:] as [String: Any]]))]
        performer.pollingScreenResult = .completed

        // When the payment is confirmed
        let result = await confirmPaymentIntent(.blik).result

        // Then the polling screen showed BLIK's config, with no web view, and finished the payment without a read
        XCTAssertEqual(result, .completed)
        guard case .pollingScreen(let screen) = performer.performed.first else {
            return XCTFail("Expected a polling screen, got \(performer.performed)")
        }
        XCTAssertEqual(screen.screen.seconds, 60)
        XCTAssertEqual(screen.screen.instructions, "Confirm the payment in your bank's app within {time_remaining} to complete the purchase.")
        XCTAssertNil(screen.instructions)
        XCTAssertEqual(api.calls, ["confirm"])
    }

    func testPixWebViewCloseLetsThePollingScreenFinish() async {
        // Given Pix's QR next action, the customer closes the instructions while the screen keeps polling (F1)
        let pix = PaymentConfirmerFixtures.paymentIntent(status: "requires_action", type: "pix", nextAction: ["type": "pix_display_qr_code", "pix_display_qr_code": ["hosted_instructions_url": "https://qr.example/instructions", "expires_at": 1_900_000_000]])
        api.confirmResults = [.success(pix)]
        api.fetchResults = [.success(pix)]
        let screen = FakeNextActionScreen(result: .completed)
        performer.outcome = { _ in .returned(.safariViewController, screen: screen) }

        // When the payment is confirmed
        let result = await confirmPaymentIntent(.pix).result

        // Then the read after the web view closes still says requires_action, and the screen's success wins
        XCTAssertEqual(result, .completed)
        XCTAssertEqual(api.calls, ["confirm", "retrieve"])
        guard case .pollingScreen(let resolved) = performer.performed.first else {
            return XCTFail("Expected a polling screen, got \(performer.performed)")
        }
        XCTAssertEqual(resolved.deadline, Date(timeIntervalSince1970: 1_900_000_000))
        XCTAssertEqual(resolved.instructions?.webURL, URL(string: "https://qr.example/instructions"))
        XCTAssertEqual(resolved.instructions?.returnURL, URL(string: PaymentConfirmerFixtures.confirmReturnURL))
        XCTAssertFalse(screen.stopped)
    }

    func testPollingScreenIsStoppedWhenTheIntentFailsFirst() async {
        // Given PayNow's QR next action, and the intent was canceled when the customer closed the instructions
        let paynow = PaymentConfirmerFixtures.paymentIntent(status: "requires_action", type: "paynow", nextAction: ["type": "paynow_display_qr_code", "paynow_display_qr_code": ["hosted_instructions_url": "https://qr.example/instructions"]])
        api.confirmResults = [.success(paynow)]
        api.fetchResults = [.success(PaymentConfirmerFixtures.paymentIntent(status: "canceled", type: "paynow"))]
        let screen = FakeNextActionScreen(result: .completed)
        performer.outcome = { _ in .returned(.safariViewController, screen: screen) }

        // When the payment is confirmed
        let result = await confirmPaymentIntent(.paynow).result

        // Then it's canceled and the screen behind the web view is taken down
        XCTAssertEqual(result, .canceled)
        XCTAssertTrue(screen.stopped)
        XCTAssertEqual(screen.dismissed, true)
    }

    func testCardGoesToSTPPaymentHandler() async {
        for nextAction in [PaymentConfirmerFixtures.redirectNextAction, ["type": "use_stripe_sdk", "use_stripe_sdk": ["type": "three_d_secure_redirect", "stripe_js": "https://hooks.stripe.com/3d_secure_2/authenticate/src_1"]]] {
            // Given a card payment that needs any next action, even a plain redirect (3DS1)
            performer.performed = []
            api.confirmResults = [.success(PaymentConfirmerFixtures.paymentIntent(status: "requires_action", type: "card", nextAction: nextAction))]
            performer.stripeSDKResult = .completed

            // When it's confirmed
            let result = await confirmPaymentIntent(.card).result

            // Then STPPaymentHandler performs it and finishes the payment
            XCTAssertEqual(result, .completed)
            XCTAssertEqual(performer.performed, [.stripeSDK])
        }
    }

    func testUseStripeSDKOnAnLPMGoesToSTPPaymentHandler() async {
        // Given an iDEAL payment that gets an intent confirmation challenge
        api.confirmResults = [.success(PaymentConfirmerFixtures.paymentIntent(status: "requires_action", type: "ideal", nextAction: ["type": "use_stripe_sdk", "use_stripe_sdk": ["type": "intent_confirmation_challenge", "stripe_js": [:] as [String: Any]]]))]
        performer.stripeSDKResult = .completed

        // When it's confirmed
        let result = await confirmPaymentIntent(.iDEAL).result

        // Then STPPaymentHandler performs it, like it would for any type
        XCTAssertEqual(result, .completed)
        XCTAssertEqual(performer.performed, [.stripeSDK])
    }

    func testCashAppNeedsAConfirmReturnURL() async {
        // Given Cash App's next action, which returns to the confirm-time return URL
        api.confirmResults = [.success(PaymentConfirmerFixtures.paymentIntent(status: "requires_action", type: "cashapp", nextAction: ["type": "cashapp_handle_redirect_or_display_qr_code", "cashapp_handle_redirect_or_display_qr_code": ["mobile_auth_url": "https://cash.app/auth"]]))]

        // When it's confirmed without a return URL
        let result = await confirmPaymentIntent(.cashApp, returnURL: nil).result

        // Then it fails like STPPaymentHandler (SPH:1455)
        XCTAssertEqual(result.errorCode, STPPaymentHandlerErrorCode.missingReturnURL.rawValue)
        XCTAssertTrue(performer.performed.isEmpty)
    }

    func testAlipayDoesNotPingMarlinBeforeReading() async {
        // Given Alipay's next action, with a legacy Marlin URL in the native URL's return_url
        let marlin = "https://hooks.stripe.com/marlin/1"
        let details: [String: Any] = [
            "native_url": "alipay://alipayclient/?return_url=\(marlin.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)",
            "url": "https://alipay.example/pay",
            "return_url": "https://hooks.stripe.com/trampoline",
        ]
        let nextAction: [String: Any] = ["type": "alipay_handle_redirect", "alipay_handle_redirect": details]
        api.confirmResults = [.success(PaymentConfirmerFixtures.paymentIntent(status: "requires_action", type: "alipay", nextAction: nextAction))]
        api.fetchResults = [.success(PaymentConfirmerFixtures.paymentIntent(status: "succeeded", type: "alipay"))]

        // When it's confirmed
        let result = await confirmPaymentIntent(.alipay).result

        // Then it tries the native URL, falls back to the web URL, returns to the confirm-time URL, and reads the intent
        // without loading the Marlin URL first (M4: Alipay+ makes the ping a no-op)
        XCTAssertEqual(result, .completed)
        XCTAssertEqual(performer.redirects.first?.appURL?.scheme, "alipay")
        XCTAssertEqual(performer.redirects.first?.webURL, URL(string: "https://alipay.example/pay"))
        XCTAssertEqual(performer.redirects.first?.returnURL, URL(string: PaymentConfirmerFixtures.confirmReturnURL))
        XCTAssertEqual(api.calls, ["confirm", "retrieve"])
    }

    func testRedirectFlagsFromTheURL() throws {
        // Given a redirect_to_url whose stripe.com URL asks for ASWebAuthenticationSession and pre-following
        let url = "https://hooks.stripe.com/redirect?useWebAuthSession=true&followRedirectsInSDK=true"
        let intent = PaymentConfirmerFixtures.paymentIntent(status: "requires_action", type: "klarna", nextAction: ["type": "redirect_to_url", "redirect_to_url": ["url": url, "return_url": "x://y"]])

        // When it's resolved
        let resolved = try ResolvedNextAction(intent: intent, metadata: ConfirmationMetadata.native(for: .klarna)!, confirmReturnURL: nil)

        // Then both flags are read, like STPIntentActionRedirectToURL
        XCTAssertEqual(resolved, ResolvedNextAction.redirect(.init(appURL: URL(string: url), webURL: URL(string: url), returnURL: URL(string: "x://y"), useWebAuthSession: true, followRedirects: true)))
    }
}

extension PaymentConfirmerNativeTests: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
    }
}

// MARK: - PaymentSheet routing

@MainActor
final class PaymentConfirmerRoutingTests: APIStubbedTestCase {
    /// PaymentSheet doesn't retain the STPPaymentHandler it's given, so the test does.
    var paymentHandler: STPPaymentHandler?

    func testOnlyServerDrivenPaymentMethodsUseTheEngineByDefault() throws {
        // Given confirmation returns a processing DemoPay intent and a succeeded Cash App Pay intent
        stub { $0.url?.pathComponents.last == "confirm" } response: { request in
            let isServerDriven = RequestBodyTestHelpers.formEncodedBodyParams(from: request)["payment_method_data[type]"] == "demo_pay"
            let json = isServerDriven
                ? PaymentConfirmerFixtures.json(status: "processing", paymentMethodType: "demo_pay")
                : PaymentConfirmerFixtures.json(status: "succeeded", paymentMethodType: "cashapp")
            return HTTPStubsResponse(jsonObject: json, statusCode: 200, headers: nil)
        }
        let serverDriven = try ServerDrivenPaymentMethodFixtures.serverDrivenPaymentMethod()
        STPAnalyticsClient.sharedClient._testLogHistory = []

        // When PaymentSheet confirms a server-driven payment method
        let serverDrivenResult = confirm(paymentMethodType: .serverDriven(serverDriven))

        // Then the engine confirms it, so its processing intent completes per the spec
        // (STPPaymentHandler fails a processing intent of a type it doesn't know)
        guard case .completed = serverDrivenResult else {
            return XCTFail("Expected completed, got \(serverDrivenResult)")
        }
        // ...and logs the real type and the engine
        let serverDrivenConfirmStarted = confirmStartedEvents()
        XCTAssertEqual(serverDrivenConfirmStarted.count, 1)
        XCTAssertEqual(serverDrivenConfirmStarted.first?["payment_method_type"] as? String, "demo_pay")
        XCTAssertEqual(serverDrivenConfirmStarted.first?["handler"] as? String, "paymentsheet_engine")
        XCTAssertEqual(serverDrivenConfirmStarted.first?["spec_source"] as? String, "server")

        // When PaymentSheet confirms a native payment method whose family isn't routed
        let routedFamilies = PaymentConfirmer.routedFamilies
        defer { PaymentConfirmer.routedFamilies = routedFamilies }
        PaymentConfirmer.routedFamilies.remove(.appToApp)
        STPAnalyticsClient.sharedClient._testLogHistory = []
        let nativeResult = confirm(paymentMethodType: .stripe(.cashApp))

        // Then STPPaymentHandler confirms it
        guard case .completed = nativeResult else {
            return XCTFail("Expected completed, got \(nativeResult)")
        }
        let nativeConfirmStarted = confirmStartedEvents()
        XCTAssertEqual(nativeConfirmStarted.count, 1)
        XCTAssertEqual(nativeConfirmStarted.first?["payment_method_type"] as? String, "cashapp")
        XCTAssertNil(nativeConfirmStarted.first?["handler"])
    }

    func testSTPAPIClientRefreshCallsTheRefreshEndpoint() async throws {
        // Given the refresh endpoint returns a succeeded intent
        var refreshRequests: [URLRequest] = []
        stub { $0.url?.path == "/v1/payment_intents/pi_123/refresh" } response: { request in
            refreshRequests.append(request)
            return HTTPStubsResponse(jsonObject: PaymentConfirmerFixtures.json(status: "succeeded"), statusCode: 200, headers: nil)
        }
        let apiClient = stubbedAPIClient()
        apiClient.publishableKey = "pk_test_123"

        // When the engine's API refreshes the intent, as it does for `retrieval: refresh`
        let intent = try await (apiClient as PaymentConfirmerAPI).fetchIntent(.paymentIntent(PaymentConfirmerFixtures.redirectIntent()), retrieval: .refresh, timeout: nil)

        // Then it POSTs to the intent's refresh endpoint with the client secret, like STPPaymentHandler for Cash App and Klarna
        XCTAssertEqual(intent.status, .succeeded)
        XCTAssertEqual(refreshRequests.count, 1)
        XCTAssertEqual(refreshRequests.first?.httpMethod, "POST")
        let body = refreshRequests.first.map { RequestBodyTestHelpers.formEncodedBodyParams(from: $0) } ?? [:]
        XCTAssertEqual(body["client_secret"], PaymentConfirmerFixtures.clientSecret)
    }

    func confirm(paymentMethodType: PaymentSheet.PaymentMethodType) -> PaymentSheetResult {
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive()
        configuration.apiClient = stubbedAPIClient()
        configuration.apiClient.publishableKey = "pk_test_123"
        let paymentIntent = STPPaymentIntent.decodedObject(fromAPIResponse: PaymentConfirmerFixtures.json(status: "requires_payment_method", paymentMethodType: nil))!
        let exp = expectation(description: "confirmed")
        var result: PaymentSheetResult?
        let paymentHandler = STPPaymentHandler(apiClient: configuration.apiClient)
        self.paymentHandler = paymentHandler
        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: self,
            intent: .paymentIntent(paymentIntent),
            elementsSession: ._testCardValue(),
            paymentOption: .new(confirmParams: IntentConfirmParams(type: paymentMethodType)),
            paymentHandler: paymentHandler,
            analyticsHelper: ._testValue(),
            completion: { paymentSheetResult, _ in
                result = paymentSheetResult
                exp.fulfill()
            }
        )
        waitForExpectations(timeout: 10)
        return result ?? .failed(error: PaymentSheetError.unknown(debugDescription: "No result"))
    }

    func confirmStartedEvents() -> [[String: Any]] {
        return STPAnalyticsClient.sharedClient._testLogHistory.filter { $0["event"] as? String == STPAnalyticEvent.paymentHandlerConfirmStarted.rawValue }
    }
}

extension PaymentConfirmerRoutingTests: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
    }
}

// MARK: - Fakes

enum PaymentConfirmerFixtures {
    static let clientSecret = "pi_123_secret_456"
    static let redirectURL = URL(string: "https://hooks.stripe.com/redirect/authenticate/src_123")!
    static let returnURL = URL(string: "payments-example://stripe-redirect")!
    static let confirmReturnURL = "payments-example://confirm-return"
    static let redirectNextAction: [String: Any] = [
        "type": "redirect_to_url",
        "redirect_to_url": ["url": redirectURL.absoluteString, "return_url": returnURL.absoluteString],
    ]

    static func json(status: String, paymentMethodType: String? = "demo_pay", nextAction: [String: Any]? = nil, lastPaymentError: [String: Any]? = nil) -> [String: Any] {
        var json: [String: Any] = [
            "id": "pi_123",
            "object": "payment_intent",
            "client_secret": clientSecret,
            "amount": 1000,
            "currency": "usd",
            "status": status,
            "livemode": false,
            "created": 1652736692,
            "payment_method_types": ["demo_pay", "cashapp"],
        ]
        if let paymentMethodType {
            json["payment_method"] = ["id": "pm_123", "object": "payment_method", "type": paymentMethodType, "created": 1652736692, "livemode": false] as [String: Any]
        }
        json["next_action"] = nextAction
        json["last_payment_error"] = lastPaymentError
        return json
    }

    static func paymentIntent(status: String, type: String = "demo_pay", nextAction: [String: Any]? = nil, lastPaymentError: [String: Any]? = nil) -> ConfirmingIntent {
        return .paymentIntent(STPPaymentIntent.decodedObject(fromAPIResponse: json(status: status, paymentMethodType: type, nextAction: nextAction, lastPaymentError: lastPaymentError))!)
    }

    static func redirectIntent(type: String = "demo_pay") -> STPPaymentIntent {
        return paymentIntent(status: "requires_action", type: type, nextAction: redirectNextAction).paymentIntent!
    }

    static func setupIntent(status: String, type: String, nextAction: [String: Any]?) -> STPSetupIntent {
        var json: [String: Any] = [
            "id": "seti_123",
            "object": "setup_intent",
            "client_secret": "seti_123_secret_456",
            "status": status,
            "livemode": false,
            "created": 1652736692,
            "payment_method_types": [type],
            "payment_method": ["id": "pm_123", "object": "payment_method", "type": type, "created": 1652736692, "livemode": false] as [String: Any],
        ]
        json["next_action"] = nextAction
        return STPSetupIntent.decodedObject(fromAPIResponse: json)!
    }
}

final class StubPaymentConfirmerAPI: PaymentConfirmerAPI {
    var confirmResults: [Result<ConfirmingIntent, Error>] = []
    /// Served in order for both retrieve and refresh.
    var fetchResults: [Result<ConfirmingIntent, Error>] = []
    var calls: [String] = []

    func confirmIntent(_ params: ConfirmingParams) async throws -> ConfirmingIntent {
        calls.append("confirm")
        return try confirmResults.removeFirst().get()
    }

    func fetchIntent(_ intent: ConfirmingIntent, retrieval: ConfirmationMetadata.Retrieval, timeout: TimeInterval?) async throws -> ConfirmingIntent {
        calls.append(retrieval.rawValue)
        return try fetchResults.removeFirst().get()
    }
}

extension Result where Success == ConfirmingIntent, Failure == Error {
    static func success(_ paymentIntent: STPPaymentIntent) -> Self { .success(.paymentIntent(paymentIntent)) }
}

/// Records each resolved next action instead of performing it, and returns a scripted outcome.
@MainActor
final class FakeNextActionPerformer: NextActionPerforming {
    var performed: [ResolvedNextAction] = []
    var redirectResult: RedirectResult = .returned(.returnURLCallback)
    var pollingScreenResult: PaymentSheetResult = .completed
    var stripeSDKResult: PaymentSheetResult = .completed
    /// Overrides the outcome for every next action.
    var outcome: ((ResolvedNextAction) -> NextActionOutcome)?

    var redirects: [ResolvedNextAction.Redirect] {
        return performed.compactMap { if case .redirect(let redirect) = $0 { return redirect } else { return nil } }
    }

    func perform(
        _ action: ResolvedNextAction,
        intent: ConfirmingIntent,
        returnURL: String?,
        actionID: String,
        authenticationContext: STPAuthenticationContext,
        poll: @escaping () async -> ConfirmingIntent?,
        didOpen: @escaping (RedirectType) -> Void
    ) async -> NextActionOutcome {
        performed.append(action)
        if let outcome {
            return outcome(action)
        }
        switch action {
        case .redirect:
            didOpen(.safariViewController)
            switch redirectResult {
            case .returned(let returnType):
                return .returned(returnType, screen: nil)
            case .failed(let error):
                return .finished(.failed(error: error), nil)
            }
        case .pollingScreen:
            return .finished(pollingScreenResult, nil)
        case .none:
            return .performed
        case .stripeSDK:
            return .finished(stripeSDKResult, nil)
        }
    }
}

@MainActor
final class FakeNextActionScreen: NextActionScreen {
    let finalResult: PaymentSheetResult
    private(set) var stopped = false
    private(set) var dismissed: Bool?

    init(result: PaymentSheetResult) {
        self.finalResult = result
    }

    func result() async -> (PaymentSheetResult, ConfirmingIntent?) {
        return (finalResult, nil)
    }

    func stop(dismiss: Bool) {
        stopped = true
        dismissed = dismiss
    }
}

/// A clock whose `sleep` advances time instantly.
final class FakePaymentConfirmerClock {
    var now = Date(timeIntervalSince1970: 1_000_000)
    var sleeps: [TimeInterval] = []
    /// Added to every sleep, to make polls run out of time.
    var extraSleep: TimeInterval = 0

    var clock: PaymentConfirmerClock {
        return PaymentConfirmerClock(
            now: { [unowned self] in now },
            sleep: { [unowned self] seconds in
                sleeps.append(seconds)
                now.addTimeInterval(seconds + extraSleep)
            }
        )
    }
}

extension PaymentConfirmer.State {
    var name: String {
        switch self {
        case .confirm: return "confirm"
        case .evaluate: return "evaluate"
        case .performNextAction: return "performNextAction"
        case .awaitNextActionScreen: return "awaitNextActionScreen"
        case .wait: return "wait"
        case .fetch: return "fetch"
        case .finished: return "finished"
        }
    }
}

extension PaymentSheetResult {
    var errorCode: Int? {
        guard case .failed(let error) = self else { return nil }
        return (error as NSError).code
    }
}
