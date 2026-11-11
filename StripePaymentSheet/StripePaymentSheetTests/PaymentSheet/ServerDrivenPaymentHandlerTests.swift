//
//  ServerDrivenPaymentHandlerTests.swift
//  StripePaymentSheetTests
//
//  Created by David Estes on 11/10/26.
//

import OHHTTPStubs
import OHHTTPStubsSwift
import XCTest

@testable@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripeCoreTestUtils
@testable@_spi(InternalOnlyAPI) import StripePayments
@testable@_spi(InternalOnlyAPI) import StripePaymentSheet
@testable@_spi(InternalOnlyAPI) import StripePaymentsTestUtils

@MainActor
final class ServerDrivenPaymentHandlerTests: XCTestCase {
    let api = StubServerDrivenPaymentAPI()
    let presenter = FakeServerDrivenRedirectPresenter()
    let clock = FakeServerDrivenPaymentClock()
    let analyticsClient = STPTestingAnalyticsClient()

    func makeHandler(
        retrieval: ServerDrivenConfirmSpec.Retrieval = .retrieve,
        processing: ServerDrivenConfirmSpec.Outcome = .succeed,
        requiresAction: ServerDrivenConfirmSpec.Outcome = .cancel,
        pollSeconds: Int = 0
    ) -> ServerDrivenPaymentHandler {
        return ServerDrivenPaymentHandler(
            spec: .init(nextActions: [.redirectToURL], retrieval: retrieval, processing: processing, requiresAction: requiresAction, pollSeconds: pollSeconds),
            paymentMethodType: "demo_pay",
            apiClient: STPAPIClient(publishableKey: "pk_test"),
            api: api,
            redirectPresenter: presenter,
            clock: clock.clock,
            analyticsClient: analyticsClient
        )
    }

    func confirm(_ handler: ServerDrivenPaymentHandler) async -> PaymentSheetResult {
        return await handler.confirm(params: STPPaymentIntentConfirmParams(clientSecret: ServerDrivenIntentFixtures.clientSecret), authenticationContext: self)
    }

    // MARK: - Processing

    func testProcessingSucceeds() async {
        // Given a spec where processing is success, and confirmation returns a processing intent
        api.confirmResults = [.success(ServerDrivenIntentFixtures.paymentIntent(status: "processing"))]

        // When the payment is confirmed
        let result = await confirm(makeHandler(processing: .succeed))

        // Then it completes without fetching the intent or redirecting
        assertCompleted(result)
        XCTAssertEqual(api.calls, ["confirm"])
        XCTAssertTrue(presenter.redirects.isEmpty)
    }

    func testProcessingFails() async {
        // Given a spec where processing fails
        api.confirmResults = [.success(ServerDrivenIntentFixtures.paymentIntent(status: "processing"))]

        // When the payment is confirmed
        let result = await confirm(makeHandler(processing: .fail))

        // Then it fails with STPPaymentHandler's intent status error
        assertFailed(result, code: .intentStatusErrorCode)
        XCTAssertEqual(api.calls, ["confirm"])
    }

    func testProcessingPollsThenFailsAfterTimeout() async {
        // Given a spec that polls processing intents for 2 seconds, and an intent that stays processing
        api.confirmResults = [.success(ServerDrivenIntentFixtures.paymentIntent(status: "processing"))]
        api.fetchResults = Array(repeating: .success(ServerDrivenIntentFixtures.paymentIntent(status: "processing")), count: 10)

        // When the payment is confirmed
        let result = await confirm(makeHandler(processing: .poll, pollSeconds: 2))

        // Then it polls once a second until the deadline, then fails
        assertFailed(result, code: .intentStatusErrorCode)
        XCTAssertEqual(api.calls, ["confirm", "retrieve", "retrieve"])
        XCTAssertEqual(clock.sleeps, [1, 1])
    }

    // MARK: - Redirects and polling

    func testRedirectThenPollingSucceeds() async {
        // Given confirmation returns a redirect, and the intent succeeds on the third fetch after the customer returns
        api.confirmResults = [.success(ServerDrivenIntentFixtures.redirectIntent())]
        api.fetchResults = [
            .success(ServerDrivenIntentFixtures.redirectIntent()),
            .success(ServerDrivenIntentFixtures.redirectIntent()),
            .success(ServerDrivenIntentFixtures.paymentIntent(status: "succeeded")),
        ]
        presenter.result = .returned(.returnURLCallback)

        // When the payment is confirmed with a spec that polls requires_action for 5 seconds
        let handler = makeHandler(requiresAction: .poll, pollSeconds: 5)
        let result = await confirm(handler)

        // Then it redirects to the next action's URL with its return URL
        assertCompleted(result)
        XCTAssertEqual(presenter.redirects.map(\.url), [ServerDrivenIntentFixtures.redirectURL])
        XCTAssertEqual(presenter.redirects.map(\.returnURL), [ServerDrivenIntentFixtures.returnURL])
        // ...and fetches until the intent succeeds, a second apart
        XCTAssertEqual(api.calls, ["confirm", "retrieve", "retrieve", "retrieve"])
        XCTAssertEqual(clock.sleeps, [1, 1])
        // ...passing through the expected states
        XCTAssertEqual(handler.transitions.map(\.name), ["confirm", "evaluate", "performNextAction", "fetch", "evaluate", "wait", "fetch", "evaluate", "wait", "fetch", "evaluate", "finished"])
    }

    func testPollingTimeoutCancels() async {
        // Given an intent that stays requires_action after the customer returns
        api.confirmResults = [.success(ServerDrivenIntentFixtures.redirectIntent())]
        api.fetchResults = Array(repeating: .success(ServerDrivenIntentFixtures.redirectIntent()), count: 10)

        // When the payment is confirmed with a spec that polls requires_action for 3 seconds
        let result = await confirm(makeHandler(requiresAction: .poll, pollSeconds: 3))

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
        api.confirmResults = [.success(ServerDrivenIntentFixtures.redirectIntent())]
        api.fetchResults = [.success(ServerDrivenIntentFixtures.redirectIntent())]
        presenter.result = .returned(.safariViewController)

        // When the payment is confirmed with a spec that cancels requires_action after a redirect
        let result = await confirm(makeHandler(requiresAction: .cancel))

        // Then it fetches once and cancels
        assertCanceled(result)
        XCTAssertEqual(api.calls, ["confirm", "retrieve"])
        XCTAssertTrue(clock.sleeps.isEmpty)
    }

    func testRefreshVsRetrieve() async {
        for (retrieval, expectedCall) in [(ServerDrivenConfirmSpec.Retrieval.retrieve, "retrieve"), (.refresh, "refresh")] {
            // Given a redirect that succeeds after the customer returns
            api.calls = []
            api.confirmResults = [.success(ServerDrivenIntentFixtures.redirectIntent())]
            api.fetchResults = [.success(ServerDrivenIntentFixtures.paymentIntent(status: "succeeded"))]

            // When the payment is confirmed with each retrieval
            let result = await confirm(makeHandler(retrieval: retrieval))

            // Then it fetches the intent the way the spec says
            assertCompleted(result)
            XCTAssertEqual(api.calls, ["confirm", expectedCall])
        }
    }

    func testRedirectThatCantBeShownFails() async {
        // Given the redirect can't be presented
        api.confirmResults = [.success(ServerDrivenIntentFixtures.redirectIntent())]
        presenter.result = .failed(ServerDrivenPaymentHandler.error(.requiresAuthenticationContextErrorCode))

        // When the payment is confirmed
        let result = await confirm(makeHandler())

        // Then it fails with the presenter's error, without fetching the intent
        assertFailed(result, code: .requiresAuthenticationContextErrorCode)
        XCTAssertEqual(api.calls, ["confirm"])
    }

    // MARK: - Next actions

    func testUnknownNextActionFailsCleanly() async {
        // Given confirmation returns a next action the spec doesn't list
        api.confirmResults = [.success(ServerDrivenIntentFixtures.paymentIntent(status: "requires_action", nextAction: ["type": "display_bank_transfer_instructions"]))]

        // When the payment is confirmed
        let result = await confirm(makeHandler())

        // Then it fails without redirecting or fetching
        assertFailed(result, code: .unsupportedAuthenticationErrorCode)
        XCTAssertTrue(presenter.redirects.isEmpty)
        XCTAssertEqual(api.calls, ["confirm"])
    }

    func testHandleNextActionForConfirmedIntent() async {
        // Given an intent the merchant's server already confirmed, which needs a redirect
        api.fetchResults = [.success(ServerDrivenIntentFixtures.paymentIntent(status: "succeeded"))]

        // When its next action is handled
        let result = await makeHandler().handleNextAction(for: ServerDrivenIntentFixtures.redirectIntent(), authenticationContext: self)

        // Then it redirects and fetches without confirming
        assertCompleted(result)
        XCTAssertEqual(presenter.redirects.count, 1)
        XCTAssertEqual(api.calls, ["retrieve"])
        // ...and logs STPPaymentHandler's events with the real type and the handler
        let events = analyticsClient.events.map(\.event)
        XCTAssertEqual(events, [.paymentHandlerHandleNextActionStarted, .urlRedirectNextAction, .urlRedirectNextActionCompleted, .paymentHandlerHandleNextActionFinished])
        let finished = analyticsClient.events.last
        XCTAssertEqual(finished?.params["payment_method_type"] as? String, "demo_pay")
        XCTAssertEqual(finished?.params["handler"] as? String, "server_driven")
        XCTAssertEqual(finished?.params["status"] as? String, "succeeded")
        XCTAssertEqual(finished?.params["intent_id"] as? String, "pi_123")
    }

    // MARK: - Errors

    func testConfirmErrorFails() async {
        // Given confirmation fails with an API error
        let apiError = NSError(domain: STPError.stripeDomain, code: STPErrorCode.apiError.rawValue)
        api.confirmResults = [.failure(apiError)]

        // When the payment is confirmed
        let result = await confirm(makeHandler())

        // Then it fails with that error
        guard case .failed(let error) = result else {
            return XCTFail("Expected failure, got \(result)")
        }
        XCTAssertEqual(error as NSError, apiError)
    }

    func testFetchErrorRetriesOnceThenFails() async {
        // Given every fetch after the redirect fails
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        api.confirmResults = [.success(ServerDrivenIntentFixtures.redirectIntent())]
        api.fetchResults = [.failure(networkError), .failure(networkError)]

        // When the payment is confirmed with a spec that doesn't poll
        let result = await confirm(makeHandler())

        // Then it retries once, a second later, then fails with the error
        guard case .failed(let error) = result else {
            return XCTFail("Expected failure, got \(result)")
        }
        XCTAssertEqual(error as NSError, networkError)
        XCTAssertEqual(api.calls, ["confirm", "retrieve", "retrieve"])
        XCTAssertEqual(clock.sleeps, [1])
    }

    func testDeclinedPaymentFails() async {
        // Given confirmation leaves the intent requires_payment_method with a decline
        api.confirmResults = [.success(ServerDrivenIntentFixtures.paymentIntent(status: "requires_payment_method", lastPaymentError: ["type": "invalid_request_error", "code": "payment_method_provider_decline"]))]

        // When the payment is confirmed
        let result = await confirm(makeHandler())

        // Then it fails with STPPaymentHandler's payment error and the decline code
        assertFailed(result, code: .paymentErrorCode)
    }

    // MARK: - Decisions

    func testDecide() {
        let spec = ServerDrivenConfirmSpec(nextActions: [.redirectToURL], retrieval: .retrieve, processing: .poll, requiresAction: .cancel, pollSeconds: 5)
        let cases: [(STPPaymentIntentStatus, Bool, ServerDrivenPaymentHandler.Decision)] = [
            (.succeeded, false, .succeed),
            (.requiresCapture, true, .succeed),
            (.requiresConfirmation, false, .succeed),
            (.canceled, true, .cancel),
            (.requiresPaymentMethod, false, .fail(.paymentFailed)),
            (.unknown, false, .fail(.unexpectedStatus)),
            (.processing, false, .poll),
            (.processing, true, .poll),
            // Before a next action, requires_action means perform it. After, the spec decides.
            (.requiresAction, false, .performNextAction),
            (.requiresAction, true, .cancel),
        ]
        for (status, hasPerformedNextAction, expected) in cases {
            XCTAssertEqual(
                ServerDrivenPaymentHandler.decide(status: status, hasPerformedNextAction: hasPerformedNextAction, spec: spec),
                expected,
                "\(STPPaymentIntentStatus.string(from: status)), hasPerformedNextAction: \(hasPerformedNextAction)"
            )
        }
    }

    func testSpecFromWireFields() throws {
        func spec(processingIsSuccess: Bool, postRedirectPollSeconds: Int) throws -> ServerDrivenConfirmSpec {
            let json = ServerDrivenPaymentMethodFixtures.json {
                $0[jsonDict: "confirm"]?["processing_is_success"] = processingIsSuccess
                $0[jsonDict: "confirm"]?["post_redirect_poll_seconds"] = postRedirectPollSeconds
            }
            return try ServerDrivenPaymentMethodFixtures.serverDrivenPaymentMethod(json).confirmSpec
        }
        XCTAssertEqual(try spec(processingIsSuccess: true, postRedirectPollSeconds: 5), .init(nextActions: [.redirectToURL], retrieval: .retrieve, processing: .succeed, requiresAction: .poll, pollSeconds: 5))
        XCTAssertEqual(try spec(processingIsSuccess: false, postRedirectPollSeconds: 0), .init(nextActions: [.redirectToURL], retrieval: .retrieve, processing: .poll, requiresAction: .cancel, pollSeconds: 0))
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

extension ServerDrivenPaymentHandlerTests: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
    }
}

// MARK: - PaymentSheet routing

@MainActor
final class ServerDrivenPaymentHandlerRoutingTests: APIStubbedTestCase {
    /// PaymentSheet doesn't retain the STPPaymentHandler it's given, so the test does.
    var paymentHandler: STPPaymentHandler?

    func testOnlyServerDrivenPaymentMethodsUseServerDrivenPaymentHandler() throws {
        // Given confirmation returns a processing DemoPay intent and a succeeded Cash App Pay intent
        stub { $0.url?.pathComponents.last == "confirm" } response: { request in
            let isServerDriven = RequestBodyTestHelpers.formEncodedBodyParams(from: request)["payment_method_data[type]"] == "demo_pay"
            let json = isServerDriven
                ? ServerDrivenIntentFixtures.json(status: "processing", paymentMethodType: "demo_pay")
                : ServerDrivenIntentFixtures.json(status: "succeeded", paymentMethodType: "cashapp")
            return HTTPStubsResponse(jsonObject: json, statusCode: 200, headers: nil)
        }
        let serverDriven = try ServerDrivenPaymentMethodFixtures.serverDrivenPaymentMethod()
        STPAnalyticsClient.sharedClient._testLogHistory = []

        // When PaymentSheet confirms a server-driven payment method
        let serverDrivenResult = confirm(paymentMethodType: .serverDriven(serverDriven))

        // Then ServerDrivenPaymentHandler confirms it, so its processing intent completes per the spec
        // (STPPaymentHandler fails a processing intent of a type it doesn't know)
        guard case .completed = serverDrivenResult else {
            return XCTFail("Expected completed, got \(serverDrivenResult)")
        }
        // ...and logs the real type and the handler
        let serverDrivenConfirmStarted = confirmStartedEvents()
        XCTAssertEqual(serverDrivenConfirmStarted.count, 1)
        XCTAssertEqual(serverDrivenConfirmStarted.first?["payment_method_type"] as? String, "demo_pay")
        XCTAssertEqual(serverDrivenConfirmStarted.first?["handler"] as? String, "server_driven")

        // When PaymentSheet confirms a native payment method
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

    private func confirm(paymentMethodType: PaymentSheet.PaymentMethodType) -> PaymentSheetResult {
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive()
        configuration.apiClient = stubbedAPIClient()
        configuration.apiClient.publishableKey = "pk_test_123"
        let paymentIntent = STPPaymentIntent.decodedObject(fromAPIResponse: ServerDrivenIntentFixtures.json(status: "requires_payment_method", paymentMethodType: nil))!
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

    private func confirmStartedEvents() -> [[String: Any]] {
        return STPAnalyticsClient.sharedClient._testLogHistory.filter { $0["event"] as? String == STPAnalyticEvent.paymentHandlerConfirmStarted.rawValue }
    }
}

extension ServerDrivenPaymentHandlerRoutingTests: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
    }
}

// MARK: - Fakes

enum ServerDrivenIntentFixtures {
    static let clientSecret = "pi_123_secret_456"
    static let redirectURL = URL(string: "https://hooks.stripe.com/redirect/authenticate/src_123")!
    static let returnURL = URL(string: "payments-example://stripe-redirect")!

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

    static func paymentIntent(status: String, nextAction: [String: Any]? = nil, lastPaymentError: [String: Any]? = nil) -> STPPaymentIntent {
        return STPPaymentIntent.decodedObject(fromAPIResponse: json(status: status, nextAction: nextAction, lastPaymentError: lastPaymentError))!
    }

    static func redirectIntent() -> STPPaymentIntent {
        return paymentIntent(status: "requires_action", nextAction: [
            "type": "redirect_to_url",
            "redirect_to_url": ["url": redirectURL.absoluteString, "return_url": returnURL.absoluteString],
        ])
    }
}

final class StubServerDrivenPaymentAPI: ServerDrivenPaymentAPI {
    var confirmResults: [Result<STPPaymentIntent, Error>] = []
    /// Served in order for both retrieve and refresh.
    var fetchResults: [Result<STPPaymentIntent, Error>] = []
    var calls: [String] = []

    func confirm(_ params: STPPaymentIntentConfirmParams) async throws -> STPPaymentIntent {
        calls.append("confirm")
        return try confirmResults.removeFirst().get()
    }

    func retrieve(clientSecret: String, timeout: TimeInterval) async throws -> STPPaymentIntent {
        calls.append("retrieve")
        return try fetchResults.removeFirst().get()
    }

    func refresh(clientSecret: String) async throws -> STPPaymentIntent {
        calls.append("refresh")
        return try fetchResults.removeFirst().get()
    }
}

final class FakeServerDrivenRedirectPresenter: ServerDrivenRedirectPresenting {
    var result: ServerDrivenRedirectResult = .returned(.returnURLCallback)
    var redirects: [(url: URL, returnURL: URL?)] = []

    func redirect(
        to url: URL,
        returnURL: URL?,
        useWebAuthSession: Bool,
        authenticationContext: STPAuthenticationContext,
        didOpen: @escaping (ServerDrivenRedirectType) -> Void
    ) async -> ServerDrivenRedirectResult {
        redirects.append((url, returnURL))
        didOpen(.safariViewController)
        return result
    }
}

/// A clock whose `sleep` advances time instantly.
final class FakeServerDrivenPaymentClock {
    var now = Date(timeIntervalSince1970: 1_000_000)
    var sleeps: [TimeInterval] = []

    var clock: ServerDrivenPaymentClock {
        return ServerDrivenPaymentClock(
            now: { [unowned self] in now },
            sleep: { [unowned self] seconds in
                sleeps.append(seconds)
                now.addTimeInterval(seconds)
            }
        )
    }
}

extension ServerDrivenPaymentHandler.State {
    var name: String {
        switch self {
        case .confirm: return "confirm"
        case .evaluate: return "evaluate"
        case .performNextAction: return "performNextAction"
        case .wait: return "wait"
        case .fetch: return "fetch"
        case .finished: return "finished"
        }
    }
}
