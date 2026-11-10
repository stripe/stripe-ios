//
//  CheckoutConnectStubbedTests.swift
//  StripePaymentSheetTests
//

import OHHTTPStubs
import OHHTTPStubsSwift
import PassKit
@testable @_spi(InternalOnlyAPI) import StripeCore
import StripeCoreTestUtils
@testable @_spi(InternalOnlyAPI) import StripePayments
@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
import StripePaymentsObjcTestUtils
@testable @_spi(InternalOnlyAPI) import StripePaymentsTestUtils
import UIKit
import XCTest

/// Verifies which credentials Checkout uses for Connect charge types.
///
/// - Direct charges: the merchant sets `apiClient.stripeAccount` to the connected account that owns the Session,
///   so every request must send `Stripe-Account`.
/// - Destination charges and separate charges and transfers: the platform owns the Session, so requests must not
///   send `Stripe-Account`, and the client must not send Connect parameters; the backend applies them from the Session.
@MainActor
final class CheckoutConnectStubbedTests: APIStubbedTestCase {
    private static let connectedAccount = "acct_connected_123"
    private static let sessionId = "cs_test_123"
    private static let paymentIntentId = "pi_1Cl15wIl4IdHmuTbCWrpJXN6"
    private static let paymentIntentClientSecret = "pi_1Cl15wIl4IdHmuTbCWrpJXN6_secret_EkKtQ7Sg75hLDFKqFG8DtWcaK"

    private let recorder = RequestRecorder()

    override func setUp() {
        super.setUp()
        HTTPStubs.onStubActivation { [recorder] request, _, _ in
            recorder.append(request)
        }
        addTeardownBlock {
            HTTPStubs.onStubActivation(nil)
        }
    }

    // MARK: - Direct charges

    func testDirectChargeSendsConnectedAccountOnEveryRequestThroughAuthenticationAndPolling() async throws {
        // Given a Checkout Session owned by a connected account
        let checkout = try await makeCheckout(stripeAccount: Self.connectedAccount)
        // ...and a Session update
        try await checkout.applyPromotionCode("SAVE10")
        // ...and /confirm requires an action whose PaymentIntent is complete once retrieved
        stubConfirm { _ in Self.confirmResponseJSON(requiresAction: true) }
        stubPaymentIntentRetrieval(status: "succeeded")
        stubPoll()

        // When the customer pays with a new card
        let result = await checkout.confirm(source: .merchant) { makeNewCardFlow(for: checkout) }

        // Then confirmation completes
        guard case .completed(.paid) = result else {
            return XCTFail("Expected confirmation to complete, got \(result)")
        }
        // ...and init, update, confirm, PaymentIntent retrieval, and polling all use the connected account
        XCTAssertEqual(recordedEndpoints(), [
            "POST /v1/checkout_client/cs_test_123/init",
            "POST /v1/checkout_client/cs_test_123/update",
            "POST /v1/checkout_client/cs_test_123/confirm",
            "GET /v1/payment_intents/pi_1Cl15wIl4IdHmuTbCWrpJXN6",
            "GET /v1/checkout_client/cs_test_123/poll",
        ])
        assertAllRequests(stripeAccount: Self.connectedAccount)
    }

    func testDirectChargeCanceledAuthenticationThenRetryKeepsConnectedAccount() async throws {
        // Given a connected-account Session where the first attempt requires authentication
        let checkout = try await makeCheckout(stripeAccount: Self.connectedAccount)
        var confirmCount = 0
        stubConfirm { _ in
            confirmCount += 1
            return Self.confirmResponseJSON(requiresAction: confirmCount == 1)
        }
        // ...and the customer cancels authentication
        stubPaymentIntentRetrieval(status: "canceled")

        // When the customer confirms
        let firstResult = await checkout.confirm(source: .merchant) { makeNewCardFlow(for: checkout) }

        // Then the attempt is canceled and the Session remains open
        guard case .canceled = firstResult else {
            return XCTFail("Expected the first attempt to be canceled, got \(firstResult)")
        }
        XCTAssertEqual(checkout.session.status, .open)

        // When the customer retries with a saved card
        stubPoll()
        let retryResult = await checkout.confirm(source: .merchant) { makeSavedCardFlow(for: checkout) }

        // Then the retry completes
        guard case .completed(.paid) = retryResult else {
            return XCTFail("Expected the retry to complete, got \(retryResult)")
        }
        XCTAssertEqual(confirmCount, 2)
        // ...and every request in both attempts uses the connected account
        XCTAssertEqual(recordedEndpoints(), [
            "POST /v1/checkout_client/cs_test_123/init",
            "POST /v1/checkout_client/cs_test_123/confirm",
            "GET /v1/payment_intents/pi_1Cl15wIl4IdHmuTbCWrpJXN6",
            "POST /v1/checkout_client/cs_test_123/confirm",
            "GET /v1/checkout_client/cs_test_123/poll",
        ])
        assertAllRequests(stripeAccount: Self.connectedAccount)
    }

    func testDirectChargeFailedPollRetrievesSessionWithConnectedAccount() async throws {
        // Given a connected-account Session whose confirmation fails asynchronously
        let checkout = try await makeCheckout(stripeAccount: Self.connectedAccount)
        stubConfirm { _ in Self.confirmResponseJSON(requiresAction: false) }
        stubPoll(confirmationStatus: "failed", status: "open", paymentStatus: "unpaid")
        stub { request in
            request.url?.path == "/v1/checkout_client/\(Self.sessionId)/retrieve"
        } response: { _ in
            HTTPStubsResponse(jsonObject: Self.openSessionJSON(), statusCode: 200, headers: nil)
        }

        // When the customer confirms
        let result = await checkout.confirm(source: .merchant) { makeSavedCardFlow(for: checkout) }

        // Then confirmation fails after retrieving the latest Session
        guard case .failed = result else {
            return XCTFail("Expected confirmation to fail, got \(result)")
        }
        XCTAssertEqual(recordedEndpoints(), [
            "POST /v1/checkout_client/cs_test_123/init",
            "POST /v1/checkout_client/cs_test_123/confirm",
            "GET /v1/checkout_client/cs_test_123/poll",
            "GET /v1/checkout_client/cs_test_123/retrieve",
        ])
        // ...and the retrieval also uses the connected account
        assertAllRequests(stripeAccount: Self.connectedAccount)
    }

    func testDirectChargeApplePayTokenizesAndConfirmsWithConnectedAccount() async throws {
        // Given a connected-account Session using Apple Pay
        let checkout = try await makeCheckout(stripeAccount: Self.connectedAccount)
        stub(condition: isPath("/v1/tokens")) { _ in
            HTTPStubsResponse(
                jsonObject: ["id": "tok_apple_pay", "object": "token", "type": "card", "created": 1234567890, "livemode": false],
                statusCode: 200,
                headers: nil
            )
        }
        stubConfirm { _ in Self.confirmResponseJSON(requiresAction: false) }
        stubPoll()
        // ...with the same confirmation handler and API client that Payment Element's Apple Pay flow uses
        let authorizationController = MockPKPaymentAuthorizationController()
        let context = CheckoutApplePayContext(
            checkoutSession: checkout.session,
            applePayConfirmationParameters: .makeMock(apiClient: checkout.apiClient) { [checkout] requestParameters in
                await CheckoutElementsController.confirmCheckoutSession(
                    with: requestParameters,
                    apiClient: checkout.apiClient,
                    authenticationContext: self,
                    paymentHandler: checkout.paymentHandler
                )
            },
            authorizationController: authorizationController,
            checkoutWalletUpdater: MockCheckoutSessionWalletUpdater()
        )

        // When Apple Pay authorizes the payment
        let resultTask = Task { await context.presentApplePay() }
        let authorized = expectation(description: "Apple Pay authorization succeeds")
        context.paymentAuthorizationController(authorizationController, didAuthorizePayment: STPFixtures.simulatorApplePayPayment()) { result in
            XCTAssertEqual(result.status, .success)
            authorized.fulfill()
        }
        await fulfillment(of: [authorized], timeout: 5)
        context.paymentAuthorizationControllerDidFinish(authorizationController)

        // Then Apple Pay completes
        let result = await resultTask.value
        XCTAssertEqual(result.paymentSheetResult, .completed)
        // ...and tokenization and confirmation use the connected account
        XCTAssertEqual(recordedEndpoints(), [
            "POST /v1/checkout_client/cs_test_123/init",
            "POST /v1/tokens",
            "POST /v1/checkout_client/cs_test_123/confirm",
            "GET /v1/checkout_client/cs_test_123/poll",
        ])
        assertAllRequests(stripeAccount: Self.connectedAccount)
    }

    // MARK: - Destination charges and separate charges and transfers

    func testPlatformOwnedSessionOmitsStripeAccountAndConnectParameters() async throws {
        for (description, makeFlow) in [
            ("new card", makeNewCardFlow(for:)),
            ("saved card", makeSavedCardFlow(for:)),
        ] {
            HTTPStubs.removeAllStubs()
            APIStubbedTestCase.stubAllOutgoingRequests()
            recorder.removeAll()

            // Given a platform-owned Session, as used for destination charges and separate charges and transfers
            let checkout = try await makeCheckout(stripeAccount: nil)
            var confirmParams: [String: String] = [:]
            stubConfirm { request in
                confirmParams = RequestBodyTestHelpers.formEncodedBodyParams(from: request)
                return Self.confirmResponseJSON(requiresAction: true)
            }
            stubPaymentIntentRetrieval(status: "succeeded")
            stubPoll()

            // When the customer pays
            let result = await checkout.confirm(source: .merchant) { makeFlow(checkout) }

            // Then confirmation completes
            guard case .completed(.paid) = result else {
                return XCTFail("Expected \(description) confirmation to complete, got \(result)")
            }
            // ...and no request uses a connected account
            XCTAssertEqual(recordedEndpoints(), [
                "POST /v1/checkout_client/cs_test_123/init",
                "POST /v1/checkout_client/cs_test_123/confirm",
                "GET /v1/payment_intents/pi_1Cl15wIl4IdHmuTbCWrpJXN6",
                "GET /v1/checkout_client/cs_test_123/poll",
            ], description)
            assertAllRequests(stripeAccount: nil)
            // ...and /confirm leaves fees, transfers, and settlement merchant to the Session
            XCTAssertFalse(confirmParams.isEmpty, description)
            let connectParameters = confirmParams.keys.filter { key in
                ["on_behalf_of", "transfer_data", "transfer_group", "application_fee"].contains { key.contains($0) }
            }
            XCTAssertEqual(connectParameters, [], description)
        }
    }

    // MARK: - Helpers

    private func makeCheckout(stripeAccount: String?) async throws -> CheckoutElementsController {
        let configuration = CheckoutTestHelpers.makeConfiguration(
            apiResponse: try CheckoutClientAPIResponse.decode(fromAPIResponse: Self.openSessionJSON())
        )
        // The API client is shared by reference, so set the account before initialization sends /init.
        configuration.apiClient.stripeAccount = stripeAccount
        let checkout = try await CheckoutElementsController(configuration: configuration)
        XCTAssertIdentical(checkout.paymentHandler.apiClient, configuration.apiClient)
        XCTAssertIdentical(checkout.getPaymentElement().embeddedPaymentElement.configuration.apiClient, configuration.apiClient)
        return checkout
    }

    private func makeNewCardFlow(for checkout: CheckoutElementsController) -> CheckoutElementsController.CheckoutConfirmationFlow {
        let confirmParams = IntentConfirmParams(type: .stripe(.card))
        let card = STPPaymentMethodCardParams()
        card.number = "4000002500003155"
        card.cvc = "123"
        card.expMonth = 12
        card.expYear = 32
        confirmParams.paymentMethodParams.card = card
        return makePaymentMethodFlow(for: checkout, option: .new(confirmParams))
    }

    private func makeSavedCardFlow(for checkout: CheckoutElementsController) -> CheckoutElementsController.CheckoutConfirmationFlow {
        makePaymentMethodFlow(for: checkout, option: .saved(STPPaymentMethod._testCard(), nil))
    }

    private func makePaymentMethodFlow(
        for checkout: CheckoutElementsController,
        option: CheckoutElementsController.PaymentMethodConfirmationParameters.Option
    ) -> CheckoutElementsController.CheckoutConfirmationFlow {
        let embeddedPaymentElement = checkout.getPaymentElement().embeddedPaymentElement
        return .paymentMethod(
            .init(
                option: option,
                configuration: embeddedPaymentElement.configuration,
                returnURL: checkout.configuration.returnURL,
                nativeSheetPresentation: embeddedPaymentElement.nativeSheetPresentation,
                confirmationChallenge: nil,
                authenticationContext: self,
                // Use the coordinator's handler, as production confirmation does.
                paymentHandler: checkout.paymentHandler,
                attribution: .init(confirmingElement: .paymentElement, configuredElements: checkout.configuration.configuredElements)
            ),
            preconfirmIntegrationShape: .embedded
        )
    }

    private static func openSessionJSON() -> [String: Any] {
        CheckoutTestHelpers.makeSessionJSON(["id": sessionId])
    }

    private static func confirmResponseJSON(requiresAction: Bool) -> [String: Any] {
        CheckoutTestHelpers.makeSessionJSON([
            "id": sessionId,
            "status": "open",
            "payment_status": "unpaid",
            "payment_response": [
                "status": requiresAction ? "requires_action" : "processing",
                "payment_intent": ["id": paymentIntentId, "client_secret": paymentIntentClientSecret],
            ],
        ])
    }

    private func stubConfirm(response: @escaping (URLRequest) -> [String: Any]) {
        stub { request in
            request.url?.path == "/v1/checkout_client/\(Self.sessionId)/confirm"
        } response: { request in
            HTTPStubsResponse(jsonObject: response(request), statusCode: 200, headers: nil)
        }
    }

    private func stubPaymentIntentRetrieval(status: String) {
        var paymentIntentJSON = STPTestUtils.jsonNamed("CheckoutPaymentIntent")!
        paymentIntentJSON["id"] = Self.paymentIntentId
        paymentIntentJSON["client_secret"] = Self.paymentIntentClientSecret
        paymentIntentJSON["status"] = status
        stub { request in
            request.httpMethod == "GET" && request.url?.path == "/v1/payment_intents/\(Self.paymentIntentId)"
        } response: { _ in
            HTTPStubsResponse(jsonObject: paymentIntentJSON, statusCode: 200, headers: nil)
        }
    }

    private func stubPoll(confirmationStatus: String = "succeeded", status: String = "complete", paymentStatus: String = "paid") {
        stub { request in
            request.url?.path == "/v1/checkout_client/\(Self.sessionId)/poll"
        } response: { _ in
            HTTPStubsResponse(
                jsonObject: [
                    "id": Self.sessionId,
                    "confirmation_status": confirmationStatus,
                    "status": status,
                    "payment_status": paymentStatus,
                ],
                statusCode: 200,
                headers: nil
            )
        }
    }

    /// The Stripe API requests made so far, ignoring unrelated asset requests.
    private var apiRequests: [URLRequest] {
        recorder.requests.filter { $0.url?.host == "api.stripe.com" }
    }

    private func recordedEndpoints() -> [String] {
        apiRequests.map { "\($0.httpMethod ?? "") \($0.url?.path ?? "")" }
    }

    private func assertAllRequests(stripeAccount: String?, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertFalse(apiRequests.isEmpty, file: file, line: line)
        for request in apiRequests {
            XCTAssertEqual(
                request.value(forHTTPHeaderField: "Stripe-Account"),
                stripeAccount,
                "Unexpected Stripe-Account for \(request.httpMethod ?? "") \(request.url?.path ?? "")",
                file: file,
                line: line
            )
        }
    }
}

extension CheckoutConnectStubbedTests: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        UIViewController()
    }
}

private final class RequestRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var _requests: [URLRequest] = []

    var requests: [URLRequest] {
        lock.withLock { _requests }
    }

    func append(_ request: URLRequest) {
        lock.withLock { _requests.append(request) }
    }

    func removeAll() {
        lock.withLock { _requests.removeAll() }
    }
}
