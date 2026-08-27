//
//  CheckoutConfirmationTests.swift
//  StripePaymentSheetTests
//

import OHHTTPStubs
import OHHTTPStubsSwift
@testable @_spi(STP) import StripeCore
import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripePaymentsTestUtils
import UIKit
import XCTest

@MainActor
final class CheckoutConfirmationTests: APIStubbedTestCase {

    // MARK: - Coordinator

    func testConfirmCommitsReturnedSessionAndMapsSuccess() async throws {
        // Given an open Checkout Session whose confirmation succeeds
        let checkout = try await makeCheckout()
        stubConfirmation()

        // When the coordinator confirms the selected payment method
        let result = await checkout.confirm(makePaymentMethodFlow(for: checkout))

        // Then it maps the result and commits the returned Checkout Session
        guard case .completed(let paymentStatus) = result else {
            XCTFail("Expected confirmation to complete, got \(result)")
            return
        }
        XCTAssertEqual(paymentStatus, .paid)
        XCTAssertEqual(checkout.session.status, .complete(.paid))
    }

    func testCanceledConfirmationCommitsReturnedSession() async throws {
        // Given Stripe returns an updated session whose PaymentIntent was canceled
        let checkout = try await makeCheckout()
        stubConfirmation(responseJSON: makeConfirmedSessionJSON(paymentIntentStatus: "canceled"))

        // When confirmation is canceled
        let result = await checkout.confirm(makePaymentMethodFlow(for: checkout))

        // Then the coordinator still commits the returned Checkout Session
        guard case .canceled = result else {
            XCTFail("Expected confirmation to be canceled, got \(result)")
            return
        }
        XCTAssertEqual(checkout.session.status, .complete(.paid))
    }

    func testFailedConfirmationCommitsReturnedSession() async throws {
        // Given Stripe returns an updated session whose PaymentIntent failed
        let checkout = try await makeCheckout()
        stubConfirmation(responseJSON: makeConfirmedSessionJSON(paymentIntentStatus: "requires_payment_method"))

        // When confirmation fails
        let result = await checkout.confirm(makePaymentMethodFlow(for: checkout))

        // Then the coordinator still commits the returned Checkout Session
        guard case .failed = result else {
            XCTFail("Expected confirmation to fail, got \(result)")
            return
        }
        XCTAssertEqual(checkout.session.status, .complete(.paid))
    }

    func testConfirmRejectsDuplicateConfirmation() async throws {
        // Given a confirmation that remains in progress long enough to start another
        let checkout = try await makeCheckout()
        stubConfirmation(responseTime: 0.5)
        let firstConfirmation = Task { @MainActor in
            await checkout.confirm(makePaymentMethodFlow(for: checkout))
        }

        try await waitUntil {
            checkout.confirmationInProgress && checkout.pendingOperations.count == 1
        }

        // When another confirmation starts
        let duplicateResult = await checkout.confirm(makePaymentMethodFlow(for: checkout))

        // Then the duplicate fails without disturbing the first confirmation
        guard case .failed(let error) = duplicateResult else {
            XCTFail("Expected duplicate confirmation to fail, got \(duplicateResult)")
            return
        }
        XCTAssertTrue(error.nonGenericDescription.contains("second confirmation"))
        assertSucceeded(await firstConfirmation.value)
    }

    func testSessionUpdateQueuedDuringConfirmationWaitsForConfirmation() async throws {
        // Given an in-progress confirmation
        let checkout = try await makeCheckout()
        stubConfirmation(responseTime: 0.5)
        let confirmation = Task { @MainActor in
            await checkout.confirm(makePaymentMethodFlow(for: checkout))
        }

        try await waitUntil {
            checkout.confirmationInProgress && checkout.pendingOperations.count == 1
        }

        // When a session update is queued behind it
        var updateExecuted = false
        let update = Task { @MainActor in
            await checkout.enqueueSessionUpdate {
                updateExecuted = true
            }
        }
        try await waitUntil { checkout.pendingOperations.count == 2 }

        // Then the update waits until confirmation has finished
        XCTAssertFalse(updateExecuted)
        assertSucceeded(await confirmation.value)
        await update.value
        XCTAssertTrue(updateExecuted)
        XCTAssertTrue(checkout.pendingOperations.isEmpty)
    }

    func testConfirmRejectsClosedSessionWithoutCallingConfirmAPI() async throws {
        // Given a Checkout Session that is already complete
        let checkout = try await CheckoutController(
            configuration: CheckoutTestHelpers.makeConfiguration(apiResponse: CheckoutTestHelpers.makeClosedSession())
        )
        let confirmRequest = expectation(description: "Confirmation API is not called")
        confirmRequest.isInverted = true
        stub { request in
            request.url?.path.hasSuffix("/confirm") == true
        } response: { _ in
            confirmRequest.fulfill()
            return HTTPStubsResponse(jsonObject: Self.confirmedSessionJSON, statusCode: 200, headers: nil)
        }

        // When confirmation is attempted
        let result = await checkout.confirm(makePaymentMethodFlow(for: checkout))

        // Then it fails validation before making an API request
        guard case .failed(let error) = result else {
            XCTFail("Expected confirmation of a closed session to fail, got \(result)")
            return
        }
        XCTAssertTrue(error.nonGenericDescription.contains("no longer open"))
        await fulfillment(of: [confirmRequest], timeout: 0.1)
    }

    func testOpenConfirmResponsePollsBeforeCompleting() async throws {
        // Given /confirm returns an open Session and polling observes completion
        let checkout = try await makeCheckout()
        let poller = TestCheckoutSessionPoller(outcome: .completed)
        let responseJSON = makeConfirmedSessionJSON(status: "open", paymentStatus: "unpaid")

        // When the Checkout Session is confirmed
        let result = await confirmCheckoutSession(
            checkout,
            responseJSON: responseJSON,
            poller: poller
        )

        // Then it polls and returns the Session completed by the client Intent
        guard case .completed(let response) = result else {
            return XCTFail("Expected confirmation to complete, got \(result)")
        }
        XCTAssertEqual(poller.checkoutSessionIds, [checkout.session.id])
        XCTAssertEqual(response.status, .complete(.paid))
        XCTAssertEqual(response.paymentStatus, .paid)
    }

    func testTimedOutPollingStillCompletes() async throws {
        // Given /confirm returns an open Session and polling times out
        let checkout = try await makeCheckout()
        let poller = TestCheckoutSessionPoller(outcome: .timedOut)
        let responseJSON = makeConfirmedSessionJSON(status: "open", paymentStatus: "unpaid")

        // When the Checkout Session is confirmed
        let result = await confirmCheckoutSession(
            checkout,
            responseJSON: responseJSON,
            poller: poller
        )

        // Then confirmation still finishes from the client-completed Intent
        guard case .completed(let response) = result else {
            return XCTFail("Expected confirmation to complete, got \(result)")
        }
        XCTAssertEqual(response.status, .complete(.paid))
        XCTAssertEqual(response.paymentStatus, .paid)
    }

    func testProcessingPaymentIntentCompletesSessionAndPreservesPaymentStatus() async throws {
        // Given a SEPA Debit payment that is client-complete while the bank transfer continues asynchronously
        let checkout = try await makeCheckout()
        let poller = TestCheckoutSessionPoller(outcome: .completed)
        var responseJSON = makeConfirmedSessionJSON(
            paymentIntentStatus: "processing",
            status: "open",
            paymentStatus: "unpaid"
        )
        var paymentIntentJSON = responseJSON["payment_intent"] as! [String: Any]
        paymentIntentJSON["payment_method"] = STPTestUtils.jsonNamed("SEPADebitPaymentMethod")!
        responseJSON["payment_intent"] = paymentIntentJSON

        // When the Checkout Session is confirmed
        let result = await confirmCheckoutSession(
            checkout,
            responseJSON: responseJSON,
            poller: poller
        )

        // Then the Session is complete, but remains unpaid until the asynchronous payment succeeds
        guard case .completed(let response) = result else {
            return XCTFail("Expected confirmation to complete, got \(result)")
        }
        XCTAssertEqual(response.status, .complete(.unpaid))
        XCTAssertEqual(response.paymentStatus, .unpaid)
    }

    func testRequiresCapturePaymentIntentPreservesSessionStatuses() async throws {
        // Given a manually captured card payment that has been authorized but not captured
        let checkout = try await makeCheckout()
        let poller = TestCheckoutSessionPoller(outcome: .completed)
        let responseJSON = makeConfirmedSessionJSON(
            paymentIntentStatus: "requires_capture",
            status: "open",
            paymentStatus: "unpaid"
        )

        // When the Checkout Session is confirmed
        let result = await confirmCheckoutSession(
            checkout,
            responseJSON: responseJSON,
            poller: poller
        )

        // Then confirmation preserves the Session fields returned by /confirm
        guard case .completed(let response) = result else {
            return XCTFail("Expected confirmation to complete, got \(result)")
        }
        XCTAssertEqual(response.status, .open)
        XCTAssertEqual(response.paymentStatus, .unpaid)
    }

    func testMicrodepositVerificationPaymentIntentPreservesSessionStatuses() async throws {
        // Given a US bank account payment where the customer must verify microdeposits out of band
        let checkout = try await makeCheckout()
        let poller = TestCheckoutSessionPoller(outcome: .completed)
        var responseJSON = makeConfirmedSessionJSON(
            paymentIntentStatus: "requires_action",
            status: "open",
            paymentStatus: "unpaid"
        )
        var paymentIntentJSON = responseJSON["payment_intent"] as! [String: Any]
        paymentIntentJSON["next_action"] = [
            "type": "verify_with_microdeposits",
            "verify_with_microdeposits": [
                "arrival_date": 1_800_000_000,
                "hosted_verification_url": "https://payments.stripe.com/microdeposit/test",
                "microdeposit_type": "descriptor_code",
            ],
        ]
        responseJSON["payment_intent"] = paymentIntentJSON

        // When the Checkout Session is confirmed
        let result = await confirmCheckoutSession(
            checkout,
            responseJSON: responseJSON,
            poller: poller
        )

        // Then confirmation preserves the open and unpaid Session returned by /confirm
        guard case .completed(let response) = result else {
            return XCTFail("Expected confirmation to complete, got \(result)")
        }
        XCTAssertEqual(response.status, .open)
        XCTAssertEqual(response.paymentStatus, .unpaid)
    }

    func testSucceededSetupIntentCompletesSessionAndPreservesPaymentStatus() async throws {
        // Given a card successfully saved for future payments with a SetupIntent
        let checkout = try await makeCheckout()
        let poller = TestCheckoutSessionPoller(outcome: .completed)
        var responseJSON = makeConfirmedSessionJSON(status: "open", paymentStatus: "no_payment_required")
        var setupIntentJSON = STPTestUtils.jsonNamed("SetupIntent")!
        setupIntentJSON["status"] = "succeeded"
        setupIntentJSON["payment_method"] = STPTestUtils.jsonNamed("CardPaymentMethod")!
        responseJSON["payment_intent"] = nil
        responseJSON["setup_intent"] = setupIntentJSON

        // When the Checkout Session is confirmed
        let result = await confirmCheckoutSession(
            checkout,
            responseJSON: responseJSON,
            poller: poller
        )

        // Then the Session is complete and still requires no payment
        guard case .completed(let response) = result else {
            return XCTFail("Expected confirmation to complete, got \(result)")
        }
        XCTAssertEqual(response.status, .complete(.noPaymentRequired))
        XCTAssertEqual(response.paymentStatus, .noPaymentRequired)
    }

    func testRequiresPaymentMethodPollOutcomeRetrievesLatestSession() async throws {
        // Given polling observes a payment failure
        let checkout = try await makeCheckout()
        let poller = TestCheckoutSessionPoller(outcome: .requiresPaymentMethod)
        let confirmJSON = makeConfirmedSessionJSON(status: "open", paymentStatus: "unpaid")
        let latestSessionJSON = makeConfirmedSessionJSON(
            paymentIntentStatus: "requires_payment_method",
            status: "open",
            paymentStatus: "unpaid"
        )
        let retrieve = stubRetrieveCheckoutSession(responseJSON: latestSessionJSON)

        // When the Checkout Session is confirmed
        let result = await confirmCheckoutSession(
            checkout,
            responseJSON: confirmJSON,
            poller: poller
        )

        // Then the latest Session is returned with the payment failure
        guard case .failed(_, let response) = result else {
            return XCTFail("Expected confirmation to fail, got \(result)")
        }
        XCTAssertEqual(response?.paymentIntent?.status, .requiresPaymentMethod)
        await fulfillment(of: [retrieve], timeout: 1)
    }

    func testInvalidPollOutcomeRetrievesLatestSession() async throws {
        // Given polling observes an invalid or expired state
        let checkout = try await makeCheckout()
        let poller = TestCheckoutSessionPoller(outcome: .invalidOrExpired)
        let confirmJSON = makeConfirmedSessionJSON(status: "open", paymentStatus: "unpaid")
        let latestSessionJSON = makeConfirmedSessionJSON(status: "expired", paymentStatus: "unpaid")
        let retrieve = stubRetrieveCheckoutSession(responseJSON: latestSessionJSON)

        // When the Checkout Session is confirmed
        let result = await confirmCheckoutSession(
            checkout,
            responseJSON: confirmJSON,
            poller: poller
        )

        // Then the latest Session is returned with an unexpected confirmation error
        guard case .failed(let error, let response) = result else {
            return XCTFail("Expected confirmation to fail, got \(result)")
        }
        XCTAssertEqual(response?.status, .expired)
        XCTAssertTrue(error.nonGenericDescription.contains("invalid or expired"))
        await fulfillment(of: [retrieve], timeout: 1)
    }

    func testRequiresApprovalConfirmResponseFailsWithoutPolling() async throws {
        // Given /confirm routes to unsupported manual approval
        let checkout = try await makeCheckout()
        let poller = TestCheckoutSessionPoller(outcome: .completed)
        var responseJSON = makeConfirmedSessionJSON()
        responseJSON["submission_attempt"] = ["state": "requires_approval"]

        // When the Checkout Session is confirmed
        let result = await confirmCheckoutSession(
            checkout,
            responseJSON: responseJSON,
            poller: poller
        )

        // Then it fails before polling
        guard case .failed(let error, _) = result else {
            return XCTFail("Expected confirmation to fail, got \(result)")
        }
        XCTAssertTrue(error.nonGenericDescription.contains("manual approval"))
        XCTAssertTrue(poller.checkoutSessionIds.isEmpty)
    }

    func testFailedSubmissionAttemptFailsWithoutPolling() async throws {
        // Given /confirm reports a failed submission attempt
        let checkout = try await makeCheckout()
        let poller = TestCheckoutSessionPoller(outcome: .completed)
        var responseJSON = makeConfirmedSessionJSON()
        responseJSON["submission_attempt"] = ["state": "failed"]

        // When the Checkout Session is confirmed
        let result = await confirmCheckoutSession(
            checkout,
            responseJSON: responseJSON,
            poller: poller
        )

        // Then it fails before polling
        guard case .failed = result else {
            return XCTFail("Expected confirmation to fail, got \(result)")
        }
        XCTAssertTrue(poller.checkoutSessionIds.isEmpty)
    }

    func testOrchestrationConfirmResponseFailsWithoutPolling() async throws {
        // Given /confirm routes to the unsupported orchestration interface
        let checkout = try await makeCheckout()
        let poller = TestCheckoutSessionPoller(outcome: .completed)
        var responseJSON = makeConfirmedSessionJSON()
        responseJSON["route_to_orchestration_interface"] = true

        // When the Checkout Session is confirmed
        let result = await confirmCheckoutSession(
            checkout,
            responseJSON: responseJSON,
            poller: poller
        )

        // Then it fails before polling
        guard case .failed(let error, _) = result else {
            return XCTFail("Expected confirmation to fail, got \(result)")
        }
        XCTAssertTrue(error.nonGenericDescription.contains("orchestration"))
        XCTAssertTrue(poller.checkoutSessionIds.isEmpty)
    }

    // MARK: - Payment Method

    func testNewPaymentMethodSelectedSendsSaveAndAlwaysAllowRedisplay() async throws {
        try await assertNewPaymentMethodConfirmation(
            session: CheckoutTestHelpers.makeSession().withCustomer(),
            paymentMethodType: .stripe(.card),
            checkboxState: .selected,
            expectedAllowRedisplay: "always",
            expectedSavePaymentMethod: true
        )
    }

    func testNewPaymentMethodDeselectedOmitsSaveAndUsesUnspecifiedAllowRedisplay() async throws {
        try await assertNewPaymentMethodConfirmation(
            session: CheckoutTestHelpers.makeSession().withCustomer(),
            paymentMethodType: .stripe(.card),
            checkboxState: .deselected,
            expectedAllowRedisplay: "unspecified",
            expectedSavePaymentMethod: false
        )
    }

    func testNewPaymentMethodHiddenCheckboxOmitsSaveAndUsesUnspecifiedAllowRedisplay() async throws {
        try await assertNewPaymentMethodConfirmation(
            session: CheckoutTestHelpers.makeSession().withCustomer(),
            paymentMethodType: .stripe(.card),
            checkboxState: .hidden,
            expectedAllowRedisplay: "unspecified",
            expectedSavePaymentMethod: nil
        )
    }

    func testNewPaymentMethodWithSetupFutureUsageDeselectedUsesLimitedAllowRedisplay() async throws {
        try await assertNewPaymentMethodConfirmation(
            session: CheckoutTestHelpers.makeSession([
                "setup_future_usage": "off_session",
            ]).withCustomer(),
            paymentMethodType: .stripe(.card),
            checkboxState: .deselected,
            expectedAllowRedisplay: "limited",
            expectedSavePaymentMethod: false
        )
    }

    func testNewPaymentMethodWithOfferSaveDisabledOmitsSaveAndUsesLimitedAllowRedisplay() async throws {
        try await assertNewPaymentMethodConfirmation(
            session: CheckoutTestHelpers.makeSession([
                "setup_future_usage": "off_session",
                "customer_managed_saved_payment_methods_offer_save": [
                    "enabled": false,
                    "status": "not_accepted",
                ],
            ]).withCustomer(),
            paymentMethodType: .stripe(.card),
            checkboxState: .hidden,
            expectedAllowRedisplay: "limited",
            expectedSavePaymentMethod: nil
        )
    }

    func testNewNonCardPaymentMethodSelectedSendsSaveAndAlwaysAllowRedisplay() async throws {
        try await assertNewPaymentMethodConfirmation(
            session: CheckoutTestHelpers.makeSession([
                "payment_method_types": ["paypal"],
            ]).withCustomer(),
            paymentMethodType: .stripe(.payPal),
            checkboxState: .selected,
            expectedAllowRedisplay: "always",
            expectedSavePaymentMethod: true
        )
    }

    // MARK: - Link

    func testLinkPaymentDetailsCreatesPaymentMethodAndConfirmsCheckoutSession() async throws {
        // Given Link payment details in non-passthrough mode
        let checkout = try await makeCheckout(apiResponse: CheckoutTestHelpers.makeSession().withCustomer())
        let createPaymentMethod = stubCreatePaymentMethod()
        let confirm = stubConfirmationExpecting(sessionId: checkout.session.id, savePaymentMethod: nil)
        let logout = stubLinkLogout(consumerSessionClientSecret: "cs_xxx")
        let configuration = checkout.getPaymentElement().embeddedPaymentElement.configuration
        let flow = CheckoutController.CheckoutConfirmationFlow.link(.init(
            confirmOption: makeLinkConfirmOption(),
            configuration: configuration,
            confirmationChallenge: nil,
            analyticsHelper: ._testValue(),
            authenticationContext: self,
            paymentHandler: STPPaymentHandler(apiClient: configuration.apiClient)
        ))

        // When Checkout confirms with Link
        let result = await checkout.confirm(flow)

        // Then Link creates a PaymentMethod, confirms Checkout, and logs out
        assertSucceeded(result)
        await fulfillment(of: [createPaymentMethod, confirm, logout], timeout: 10)
    }

    func testLinkConfirmationPollsOpenCheckoutSession() async throws {
        // Given Link confirmation returns an open Checkout Session
        let checkout = try await makeCheckout(apiResponse: CheckoutTestHelpers.makeSession().withCustomer())
        var confirmResponseJSON = makeConfirmedSessionJSON(status: "open")
        confirmResponseJSON["session_id"] = checkout.session.id
        let createPaymentMethod = stubCreatePaymentMethod()
        let confirm = stubConfirmationExpecting(
            sessionId: checkout.session.id,
            savePaymentMethod: nil,
            responseJSON: confirmResponseJSON
        )
        let poll = stubPollCheckoutSession(sessionId: checkout.session.id)
        let logout = stubLinkLogout(consumerSessionClientSecret: "cs_xxx")
        let configuration = checkout.getPaymentElement().embeddedPaymentElement.configuration
        let flow = CheckoutController.CheckoutConfirmationFlow.link(.init(
            confirmOption: makeLinkConfirmOption(),
            configuration: configuration,
            confirmationChallenge: nil,
            analyticsHelper: ._testValue(),
            authenticationContext: self,
            paymentHandler: STPPaymentHandler(apiClient: configuration.apiClient)
        ))

        // When Checkout confirms with Link
        let result = await checkout.confirm(flow)

        // Then Link polls until the Checkout Session confirmation is complete
        assertSucceeded(result)
        await fulfillment(of: [createPaymentMethod, confirm, poll, logout], timeout: 10)
    }

    // MARK: - Helpers

    private static var confirmedSessionJSON: [AnyHashable: Any] {
        var json = STPTestUtils.jsonNamed("CheckoutSessionConfirmed")!
        json["session_id"] = "cs_test_123"
        json["client_secret"] = "cs_test_123_secret_abc"
        return json
    }

    private func makeCheckout(
        apiResponse: PaymentPagesAPIResponse = CheckoutTestHelpers.makeOpenSession()
    ) async throws -> CheckoutController {
        try await CheckoutController(configuration: CheckoutTestHelpers.makeConfiguration(apiResponse: apiResponse))
    }

    private func makePaymentMethodFlow(
        for checkout: CheckoutController
    ) -> CheckoutController.CheckoutConfirmationFlow {
        makePaymentMethodFlow(
            for: checkout,
            option: .saved(STPPaymentMethod._testCard(), nil)
        )
    }

    private func makePaymentMethodFlow(
        for checkout: CheckoutController,
        option: CheckoutController.PaymentMethodConfirmationParameters.Option
    ) -> CheckoutController.CheckoutConfirmationFlow {
        let configuration = checkout.getPaymentElement().embeddedPaymentElement.configuration
        let parameters = CheckoutController.PaymentMethodConfirmationParameters(
            option: option,
            configuration: configuration,
            confirmationChallenge: nil,
            authenticationContext: self,
            paymentHandler: STPPaymentHandler(apiClient: configuration.apiClient)
        )
        return .paymentMethod(parameters, preconfirmIntegrationShape: .embedded)
    }

    private func assertNewPaymentMethodConfirmation(
        session: PaymentPagesAPIResponse,
        paymentMethodType: PaymentSheet.PaymentMethodType,
        checkboxState: IntentConfirmParams.SaveForFutureUseCheckboxState,
        expectedAllowRedisplay: String,
        expectedSavePaymentMethod: Bool?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let checkout = try await makeCheckout(apiResponse: session)
        let confirmParams = makeConfirmParams(type: paymentMethodType)
        confirmParams.saveForFutureUseCheckboxState = checkboxState
        let createPaymentMethod = stubCreatePaymentMethod(expectedAllowRedisplay: expectedAllowRedisplay, file: file, line: line)
        let confirm = stubConfirmationExpecting(
            sessionId: checkout.session.id,
            savePaymentMethod: expectedSavePaymentMethod,
            file: file,
            line: line
        )

        let result = await checkout.confirm(
            makePaymentMethodFlow(for: checkout, option: .new(confirmParams))
        )

        assertSucceeded(result, file: file, line: line)
        await fulfillment(of: [createPaymentMethod, confirm], timeout: 10)
    }

    private func makeConfirmParams(type: PaymentSheet.PaymentMethodType) -> IntentConfirmParams {
        let confirmParams = IntentConfirmParams(type: type)
        if type == .stripe(.card) {
            let card = STPPaymentMethodCardParams()
            card.number = "4242424242424242"
            card.cvc = "123"
            card.expMonth = 12
            card.expYear = 32
            confirmParams.paymentMethodParams.card = card
        }
        return confirmParams
    }

    private func makeLinkConfirmOption() -> PaymentSheet.LinkConfirmOption {
        .withPaymentDetails(
            brand: .link,
            account: .init(
                email: "test@example.com",
                session: .make(
                    clientSecret: "cs_xxx",
                    emailAddress: "test@example.com",
                    redactedFormattedPhoneNumber: "(***) *** **55",
                    unredactedPhoneNumber: "(555) 555-5555",
                    phoneNumberCountry: "US",
                    verificationSessions: [.init(type: .sms, state: .verified)],
                    supportedPaymentDetailsTypes: [ParsedEnum(.card)],
                    mobileFallbackWebviewParams: nil
                ),
                publishableKey: "pk_xxx",
                displayablePaymentDetails: nil,
                useMobileEndpoints: false,
                canSyncAttestationState: false
            ),
            paymentDetails: .init(
                stripeID: "pd1",
                details: .card(card: .init(
                    expiryYear: 2055,
                    expiryMonth: 12,
                    brand: "visa",
                    networks: ["visa"],
                    last4: "1234",
                    funding: .credit,
                    checks: nil
                )),
                billingAddress: nil,
                billingEmailAddress: "test@example.com",
                nickname: nil,
                isDefault: true
            ),
            confirmationExtras: nil,
            shippingAddress: nil
        )
    }

    private func makeConfirmedSessionJSON(
        paymentIntentStatus: String? = nil,
        status: String? = nil,
        paymentStatus: String? = nil
    ) -> [AnyHashable: Any] {
        var responseJSON = Self.confirmedSessionJSON
        if let paymentIntentStatus {
            var paymentIntent = responseJSON["payment_intent"] as! [String: Any]
            paymentIntent["status"] = paymentIntentStatus
            responseJSON["payment_intent"] = paymentIntent
        }
        if let status {
            responseJSON["status"] = status
        }
        if let paymentStatus {
            responseJSON["payment_status"] = paymentStatus
        }
        return responseJSON
    }

    private func confirmCheckoutSession(
        _ checkout: CheckoutController,
        responseJSON: [AnyHashable: Any],
        poller: TestCheckoutSessionPoller
    ) async -> CheckoutController.InternalConfirmResult {
        stubConfirmation(responseJSON: responseJSON)
        let configuration = checkout.getPaymentElement().embeddedPaymentElement.configuration
        let requestParameters = CheckoutSessionConfirmationRequestParameters(
            checkoutSession: checkout.session,
            paymentMethod: STPPaymentMethod._testCard(),
            configuration: configuration,
            paymentMethodOptions: nil,
            savePaymentMethod: nil,
            clientAttributionMetadata: nil
        )
        return await CheckoutController.confirmCheckoutSession(
            with: requestParameters,
            apiClient: configuration.apiClient,
            authenticationContext: self,
            paymentHandler: STPPaymentHandler(apiClient: configuration.apiClient),
            poller: poller
        )
    }

    private func stubConfirmation(
        responseJSON: [AnyHashable: Any]? = nil,
        responseTime: TimeInterval = 0
    ) {
        let responseJSON = responseJSON ?? Self.confirmedSessionJSON
        stub { request in
            request.url?.path.hasSuffix("/confirm") == true
        } response: { _ in
            HTTPStubsResponse(
                jsonObject: responseJSON,
                statusCode: 200,
                headers: nil
            ).responseTime(responseTime)
        }
    }

    private func stubRetrieveCheckoutSession(
        responseJSON: [AnyHashable: Any]
    ) -> XCTestExpectation {
        let expectation = expectation(description: "Checkout Session retrieved")
        stub { request in
            request.httpMethod == "GET"
                && request.url?.path.hasSuffix("/payment_pages/cs_test_123") == true
        } response: { _ in
            expectation.fulfill()
            return HTTPStubsResponse(jsonObject: responseJSON, statusCode: 200, headers: nil)
        }
        return expectation
    }

    private func stubConfirmationExpecting(
        sessionId: String,
        savePaymentMethod: Bool?,
        responseJSON: [AnyHashable: Any]? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCTestExpectation {
        let expectation = expectation(description: "Checkout Session confirm requested")
        stub { request in
            guard let pathComponents = request.url?.pathComponents else { return false }
            return pathComponents.contains("payment_pages")
                && pathComponents.contains(sessionId)
                && pathComponents.last == "confirm"
        } response: { request in
            let params = RequestBodyTestHelpers.formEncodedBodyParams(
                from: request,
                omittingEmptyValues: true,
                line: line
            )
            XCTAssertEqual(
                params["save_payment_method"],
                savePaymentMethod.map(String.init),
                file: file,
                line: line
            )
            expectation.fulfill()
            return HTTPStubsResponse(
                jsonObject: responseJSON ?? Self.confirmedSessionJSON,
                statusCode: 200,
                headers: nil
            )
        }
        return expectation
    }

    private func stubPollCheckoutSession(sessionId: String) -> XCTestExpectation {
        let expectation = expectation(description: "Checkout Session polled")
        stub { request in
            request.httpMethod == "GET"
                && request.url?.path.hasSuffix("/payment_pages/\(sessionId)/poll") == true
        } response: { _ in
            expectation.fulfill()
            return HTTPStubsResponse(
                jsonObject: [
                    "session_id": sessionId,
                    "state": "succeeded",
                    "payment_object_status": NSNull(),
                ],
                statusCode: 200,
                headers: nil
            )
        }
        return expectation
    }

    private func stubCreatePaymentMethod(
        expectedAllowRedisplay: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCTestExpectation {
        let expectation = expectation(description: "PaymentMethod creation requested")
        stub { request in
            request.url?.path.hasSuffix("/payment_methods") == true
        } response: { request in
            if let expectedAllowRedisplay {
                let params = RequestBodyTestHelpers.formEncodedBodyParams(
                    from: request,
                    omittingEmptyValues: true,
                    line: line
                )
                XCTAssertEqual(params["allow_redisplay"], expectedAllowRedisplay, file: file, line: line)
            }
            expectation.fulfill()
            return HTTPStubsResponse(
                jsonObject: STPTestUtils.jsonNamed("CardPaymentMethod")!,
                statusCode: 200,
                headers: nil
            )
        }
        return expectation
    }

    private func stubLinkLogout(
        consumerSessionClientSecret: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCTestExpectation {
        let expectation = expectation(description: "Link logout requested")
        stub { request in
            request.url?.path.hasSuffix("/log_out") == true
        } response: { request in
            let params = RequestBodyTestHelpers.formEncodedBodyParams(
                from: request,
                omittingEmptyValues: true,
                line: line
            )
            XCTAssertEqual(
                params["credentials[consumer_session_client_secret]"],
                consumerSessionClientSecret,
                file: file,
                line: line
            )
            XCTAssertEqual(params["request_surface"], "ios_payment_element", file: file, line: line)
            expectation.fulfill()
            return HTTPStubsResponse(jsonObject: [], statusCode: 200, headers: nil)
        }
        return expectation
    }

    private func assertSucceeded(
        _ result: CheckoutController.ConfirmResult,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case .completed(let paymentStatus) = result else {
            XCTFail("Expected confirmation to complete, got \(result)", file: file, line: line)
            return
        }
        XCTAssertEqual(paymentStatus, .paid, file: file, line: line)
    }

    private func waitUntil(
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ condition: () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            if Date() >= deadline {
                XCTFail("Condition not met within \(timeout) seconds", file: file, line: line)
                throw CheckoutConfirmationTestTimeoutError()
            }
            try await Task.sleep(nanoseconds: 1_000_000)
        }
    }
}

extension CheckoutConfirmationTests: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        UIViewController()
    }
}

private final class TestCheckoutSessionPoller: CheckoutSessionPolling {
    let outcome: CheckoutSessionPoller.Outcome
    private(set) var checkoutSessionIds: [String] = []

    init(outcome: CheckoutSessionPoller.Outcome) {
        self.outcome = outcome
    }

    func poll(checkoutSessionId: String) async -> CheckoutSessionPoller.Outcome {
        checkoutSessionIds.append(checkoutSessionId)
        return outcome
    }
}

private struct CheckoutConfirmationTestTimeoutError: Error {}
