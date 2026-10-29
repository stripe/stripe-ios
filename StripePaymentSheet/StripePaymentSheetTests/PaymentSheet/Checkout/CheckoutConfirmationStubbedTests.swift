//
//  CheckoutConfirmationStubbedTests.swift
//  StripePaymentSheetTests
//

import OHHTTPStubs
import OHHTTPStubsSwift
@testable @_spi(InternalOnlyAPI) import StripeCore
import StripeCoreTestUtils
@testable @_spi(InternalOnlyAPI) import StripePayments
@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
@testable @_spi(InternalOnlyAPI) import StripePaymentsTestUtils
import UIKit
import XCTest

@MainActor
final class CheckoutConfirmationStubbedTests: APIStubbedTestCase {

    private var confirmationEvents: [[String: Any]] {
        STPAnalyticsClient.sharedClient._testLogHistory.filter {
            ($0["event"] as? String)?.hasPrefix("checkout_elements.confirm.") == true
        }
    }

    // MARK: - Coordinator

    func testSavedSEPARequiresMandateBeforeConfirmingWithoutPresentingPaymentElement() async throws {
        try await assertSavedSEPAMandate(accept: true)
    }

    func testDismissingSavedSEPAMandateCancelsWithoutConfirming() async throws {
        try await assertSavedSEPAMandate(accept: false)
    }

    func testSavedSEPADoesNotRepeatMandateAfterContinuingFromSheet() async throws {
        // Given a saved SEPA method whose mandate was accepted in the sheet
        let checkout = try await makeSavedSEPACheckout()
        let flowController = checkout.getPaymentElement().paymentSheetFlowController
        flowController.flowControllerViewControllerShouldClose(flowController.viewController, didCancel: false)
        flowController.updatePaymentOption()
        XCTAssertTrue(flowController.didPresentAndContinue)
        XCTAssertTrue(checkout.getPaymentElement().paymentOptionSourceOfTruthIsFlowController)
        let confirmRequested = stubConfirmationExpecting(
            sessionId: checkout.session.id,
            clientSecret: checkout.clientSecret,
            savePaymentMethod: nil,
            expectedPaymentMethodType: "sepa_debit",
            expectedPaymentMethodID: STPPaymentMethod._testSEPA().stripeId
        )

        // When the merchant confirms, no additional mandate UI is needed
        let result = await checkout.confirm(from: UIViewController())

        // Then Checkout confirms directly
        assertSucceeded(result)
        await fulfillment(of: [confirmRequested], timeout: 5)
    }

    func testSavedSEPAMandateTracksEmbeddedWindowAttachment() async throws {
        // Given the merchant obtains both public views and prepares an offscreen hierarchy
        let checkout = try await makeSavedSEPACheckout(displaysMandateText: true)
        let element = checkout.getPaymentElement()
        _ = element.view
        let embeddedView = element.uiView
        let presenter = UIViewController()
        guard case .paymentMethod(let parameters, _) = checkout.makeConfirmationFlow(
            for: element,
            presentingViewController: presenter
        ) else {
            return XCTFail("Expected a payment method confirmation flow")
        }
        XCTAssertTrue(checkout.requiresSEPAMandate(for: parameters.option))
        presenter.view.addSubview(embeddedView)
        XCTAssertNil(embeddedView.window)
        XCTAssertTrue(checkout.requiresSEPAMandate(for: parameters.option))

        // When the hierarchy reaches a window
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        XCTAssertNotNil(embeddedView.window)
        XCTAssertFalse(checkout.requiresSEPAMandate(for: parameters.option))

        // ...and the merchant removes the embedded view before confirming
        embeddedView.removeFromSuperview()
        XCTAssertNil(embeddedView.window)
        let confirmRequested = stubConfirmationExpecting(
            sessionId: checkout.session.id,
            clientSecret: checkout.clientSecret,
            savePaymentMethod: nil,
            expectedPaymentMethodType: "sepa_debit",
            expectedPaymentMethodID: STPPaymentMethod._testSEPA().stripeId
        )
        let result = await checkout.confirm(from: presenter)

        // Then the earlier attachment still avoids an extra mandate sheet
        assertSucceeded(result)
        XCTAssertNil(presenter.presentedViewController)
        await fulfillment(of: [confirmRequested], timeout: 5)
    }

    func testDisablingMandateTextSkipsConfirmationMandate() async throws {
        // Given the merchant opts to display mandates themselves
        let checkout = try await makeSavedSEPACheckout(displaysMandateText: false)
        let presenter = UIViewController()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        defer {
            presenter.dismiss(animated: false)
            window.isHidden = true
        }
        let flow = try XCTUnwrap(checkout.makeConfirmationFlow(
            for: checkout.getPaymentElement(),
            presentingViewController: presenter
        ))
        stubConfirmation()

        // When confirming without accessing the view, sheet, or mandate text
        var didComplete = false
        let confirmation = Task {
            let result = await checkout.confirm(flow)
            didComplete = true
            return result
        }

        // Then confirmation completes without a mandate sheet
        try await waitUntil { didComplete || presenter.presentedViewController != nil }
        if let mandate = presenter.presentedViewController?.children.first as? SepaMandateViewController {
            // Dismiss an unexpected mandate so a regression fails without leaving confirmation suspended.
            try await waitUntil { presenter.presentedViewController?.isBeingPresented == false }
            mandate.didTapOrSwipeToDismiss()
        }
        assertSucceeded(await confirmation.value)
        XCTAssertNil(presenter.presentedViewController)
    }

    private func makeSavedSEPACheckout(displaysMandateText: Bool? = nil) async throws -> CheckoutController {
        let session = CheckoutTestHelpers.makeSession([
            "id": "cs_test_123",
            "integration_currency": "eur",
            "presentment_currency": "eur",
            "items": CheckoutTestHelpers.makeOneTimePriceCheckoutItems(currency: "eur"),
            "ordered_payment_method_types_and_wallets": ["sepa_debit"],
            "customer": [
                "id": "cus_saved_sepa",
                "payment_methods": [STPPaymentMethod._testSEPA().allResponseFields],
            ],
        ])
        var configuration = PaymentElement.Configuration()
        if let displaysMandateText {
            configuration.displaysMandateText = displaysMandateText
        }
        return try await CheckoutController(configuration: CheckoutTestHelpers.makeConfiguration(
            apiResponse: session,
            paymentElementConfiguration: configuration
        ))
    }

    private func assertSavedSEPAMandate(accept: Bool) async throws {
        // Given a default saved SEPA method and a merchant that hasn't presented PaymentElement
        let checkout = try await makeSavedSEPACheckout()
        XCTAssertEqual(checkout.session.paymentOption?.paymentMethodType, "sepa_debit")
        XCTAssertFalse(checkout.getPaymentElement().paymentSheetFlowController.didPresentAndContinue)

        let presenter = UIViewController()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        defer {
            presenter.dismiss(animated: false)
            window.isHidden = true
        }
        let confirmRequested = expectation(description: "Confirm requested only after mandate acceptance")
        confirmRequested.isInverted = !accept
        var didAcceptMandate = false
        stubConfirmedIntentRetrieval(from: Self.confirmedSessionJSON)
        stub { $0.url?.path.hasSuffix("/confirm") == true } response: { _ in
            XCTAssertTrue(didAcceptMandate)
            confirmRequested.fulfill()
            return HTTPStubsResponse(jsonObject: Self.confirmedSessionJSON, statusCode: 200, headers: nil)
        }

        // When the merchant confirms without opening the sheet
        let confirmation = Task { await checkout.confirm(from: presenter) }

        // Then the mandate is shown before any confirmation request
        try await waitUntil { presenter.presentedViewController?.children.first is SepaMandateViewController }
        let mandate = try XCTUnwrap(presenter.presentedViewController?.children.first as? SepaMandateViewController)
        try await waitUntil { presenter.presentedViewController?.isBeingPresented == false }
        didAcceptMandate = accept
        if accept {
            mandate.completion(true)
        } else {
            mandate.didTapOrSwipeToDismiss()
        }
        let result = await confirmation.value
        if accept {
            assertSucceeded(result)
        } else {
            guard case .canceled = result else {
                return XCTFail("Expected cancellation, got \(result)")
            }
            XCTAssertEqual(checkout.session.status, .open)
        }
        XCTAssertNil(presenter.presentedViewController)
        await fulfillment(of: [confirmRequested], timeout: accept ? 5 : 0.1)
    }

    func testConfirmCommitsReturnedSessionAndMapsSuccess() async throws {
        let previousHistory = STPAnalyticsClient.sharedClient._testLogHistory
        STPAnalyticsClient.sharedClient._testLogHistory = []
        defer { STPAnalyticsClient.sharedClient._testLogHistory = previousHistory }

        // Given an open Checkout Session and a saved payment method
        let checkout = try await makeCheckout()
        let paymentMethod = STPPaymentMethod._testCard()
        let challenge = TestConfirmationChallenge()
        stubConfirmedIntentRetrieval(from: Self.confirmedSessionJSON)
        stub { request in
            request.url?.path.hasSuffix("/confirm") == true
        } response: { request in
            let params = RequestBodyTestHelpers.formEncodedBodyParams(from: request)
            XCTAssertEqual(params["payment_method"], paymentMethod.stripeId)
            XCTAssertFalse(params.keys.contains { $0.hasPrefix("payment_method_data[") })
            return HTTPStubsResponse(jsonObject: Self.confirmedSessionJSON, statusCode: 200, headers: ["Request-Id": "req_confirm_success"])
        }

        // When the coordinator confirms the saved payment method
        let result = await checkout.confirm(
            makePaymentMethodFlow(
                for: checkout,
                option: .saved(paymentMethod, nil),
                confirmationChallenge: challenge
            )
        )

        // Then it maps the result and commits the returned Checkout Session
        guard case .completed(let paymentStatus) = result else {
            XCTFail("Expected confirmation to complete, got \(result)")
            return
        }
        XCTAssertEqual(paymentStatus, .paid)
        XCTAssertEqual(checkout.session.status, .complete(.paid))
        XCTAssertEqual(challenge.completions, 0)

        // ...and analytics records the result, session, and source without a successful request ID
        let events = confirmationEvents
        XCTAssertEqual(events.compactMap { $0["event"] as? String }, [
            "checkout_elements.confirm.started",
            "checkout_elements.confirm.succeeded",
        ])
        let started = try XCTUnwrap(events.first)
        XCTAssertNil(started["duration"])
        XCTAssertNil(started["request_id"])
        let succeeded = try XCTUnwrap(events.last)
        XCTAssertEqual(succeeded["checkout_session_id"] as? String, checkout.session.id)
        XCTAssertEqual(succeeded["invocation_source"] as? String, "merchant")
        XCTAssertEqual(succeeded["selected_lpm"] as? String, "card")
        XCTAssertEqual(succeeded["is_saved_payment_method"] as? Bool, true)
        XCTAssertNil(succeeded["request_id"])
        XCTAssertGreaterThanOrEqual(try XCTUnwrap(succeeded["duration"] as? TimeInterval), 0)
    }

    func testCanceledConfirmationCommitsReturnedSession() async throws {
        let previousHistory = STPAnalyticsClient.sharedClient._testLogHistory
        STPAnalyticsClient.sharedClient._testLogHistory = []
        defer { STPAnalyticsClient.sharedClient._testLogHistory = previousHistory }

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
        XCTAssertEqual(confirmationEvents.compactMap { $0["event"] as? String }, [
            "checkout_elements.confirm.started",
            "checkout_elements.confirm.canceled",
        ])
    }

    func testFailedConfirmationCommitsReturnedSession() async throws {
        // Given confirmation returns a Session but retrieving its Intent fails
        let checkout = try await makeCheckout()
        stubConfirmation()
        stub { request in
            request.httpMethod == "GET" && request.url?.path.hasPrefix("/v1/payment_intents/") == true
        } response: { _ in
            let error = [
                "type": "invalid_request_error",
                "message": "Unable to retrieve the confirmed Intent.",
            ]
            return HTTPStubsResponse(jsonObject: ["error": error], statusCode: 400, headers: nil)
        }

        // When confirmation fails
        let result = await checkout.confirm(makePaymentMethodFlow(for: checkout))

        // Then the coordinator still commits the returned Checkout Session
        guard case .failed(let error) = result else {
            XCTFail("Expected confirmation to fail, got \(result)")
            return
        }
        XCTAssertEqual((error as NSError).userInfo[STPError.errorMessageKey] as? String, "Unable to retrieve the confirmed Intent.")
        XCTAssertEqual(checkout.session.status, .complete(.paid))
    }

    func testConfirmRejectsDuplicateConfirmation() async throws {
        // Given a confirmation that remains in progress long enough to start another
        let checkout = try await makeCheckout()
        stubConfirmation(responseTime: 0.5)
        let firstFlow = makePaymentMethodFlow(for: checkout)
        let firstConfirmation = Task { @MainActor in
            await checkout.confirm(firstFlow)
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
        let flow = makePaymentMethodFlow(for: checkout)
        let confirmation = Task { @MainActor in
            await checkout.confirm(flow)
        }

        try await waitUntil {
            checkout.confirmationInProgress && checkout.pendingOperations.count == 1
        }

        // When a session update is queued behind it
        var updateExecuted = false
        let update = Task { @MainActor in
            try await checkout.enqueueSessionUpdate {
                updateExecuted = true
            }
        }
        try await waitUntil { checkout.pendingOperations.count == 2 }

        // Then the update waits until confirmation has finished
        XCTAssertFalse(updateExecuted)
        assertSucceeded(await confirmation.value)
        try await update.value
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
        throw XCTSkip("TODO(porter) polling: Enable once polling uses CheckoutClient.")
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

    func testOpenConfirmResponseCompletesFromIntent() async throws {
        // Given /confirm returns an open Session with a succeeded Intent
        let checkout = try await makeCheckout()
        let poller = TestCheckoutSessionPoller(outcome: .completed)
        let responseJSON = makeConfirmedSessionJSON(status: "open", paymentStatus: "unpaid")

        // When the Checkout Session is confirmed
        let result = await confirmCheckoutSession(
            checkout,
            responseJSON: responseJSON,
            poller: poller
        )

        // Then the client-completed Intent establishes the Session status
        guard case .completed(let response) = result else {
            return XCTFail("Expected confirmation to complete, got \(result)")
        }
        XCTAssertTrue(poller.checkoutSessionIds.isEmpty)
        XCTAssertEqual(response.status, .complete(.paid))
        XCTAssertEqual(response.paymentStatus, .paid)
    }

    func testTimedOutPollingStillCompletes() async throws {
        throw XCTSkip("TODO(porter) polling: Enable once polling uses CheckoutClient.")
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

    func testRequiresPaymentMethodPollOutcomeRetrievesLatestSession() async throws {
        throw XCTSkip("TODO(porter) polling: Enable once polling uses CheckoutClient.")
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
        XCTAssertEqual(response?.paymentResponse?.status, "requires_payment_method")
        await fulfillment(of: [retrieve], timeout: 1)
    }

    func testInvalidPollOutcomeRetrievesLatestSession() async throws {
        throw XCTSkip("TODO(porter) polling: Enable once polling uses CheckoutClient.")
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

    func testProcessingPaymentIntentCompletesSessionAndPreservesPaymentStatus() async throws {
        // Given a SEPA Debit payment that is client-complete while the bank transfer continues asynchronously
        let checkout = try await makeCheckout()
        var responseJSON = makeConfirmedSessionJSON(
            paymentIntentStatus: "processing",
            status: "open",
            paymentStatus: "unpaid"
        )
        var paymentIntentJSON = STPTestUtils.jsonNamed("CheckoutPaymentIntent")!
        paymentIntentJSON["payment_method"] = STPTestUtils.jsonNamed("SEPADebitPaymentMethod")!

        // When the Checkout Session is confirmed
        let result = await confirmCheckoutSession(
            checkout,
            responseJSON: responseJSON,
            intentJSON: paymentIntentJSON
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
        let responseJSON = makeConfirmedSessionJSON(
            paymentIntentStatus: "requires_capture",
            status: "open",
            paymentStatus: "unpaid"
        )

        // When the Checkout Session is confirmed
        let result = await confirmCheckoutSession(
            checkout,
            responseJSON: responseJSON
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
        var responseJSON = makeConfirmedSessionJSON(
            paymentIntentStatus: "requires_action",
            status: "open",
            paymentStatus: "unpaid"
        )
        var paymentIntentJSON = STPTestUtils.jsonNamed("CheckoutPaymentIntent")!
        paymentIntentJSON["next_action"] = [
            "type": "verify_with_microdeposits",
            "verify_with_microdeposits": [
                "arrival_date": 1_800_000_000,
                "hosted_verification_url": "https://payments.stripe.com/microdeposit/test",
                "microdeposit_type": "descriptor_code",
            ],
        ]

        // When the Checkout Session is confirmed
        let result = await confirmCheckoutSession(
            checkout,
            responseJSON: responseJSON,
            intentJSON: paymentIntentJSON
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
        var responseJSON = makeConfirmedSessionJSON(status: "open", paymentStatus: "no_payment_required")
        var setupIntentJSON = STPTestUtils.jsonNamed("SetupIntent")!
        setupIntentJSON["status"] = "succeeded"
        setupIntentJSON["payment_method"] = STPTestUtils.jsonNamed("CardPaymentMethod")!
        responseJSON["payment_response"] = [
            "status": "succeeded",
            "setup_intent": ["id": setupIntentJSON["id"]!, "client_secret": setupIntentJSON["client_secret"]!],
        ]

        // When the Checkout Session is confirmed
        let result = await confirmCheckoutSession(
            checkout,
            responseJSON: responseJSON,
            intentJSON: setupIntentJSON
        )

        // Then the Session is complete and still requires no payment
        guard case .completed(let response) = result else {
            return XCTFail("Expected confirmation to complete, got \(result)")
        }
        XCTAssertEqual(response.status, .complete(.noPaymentRequired))
        XCTAssertEqual(response.paymentStatus, .noPaymentRequired)
    }

    func testFailedPaymentResponseFails() async throws {
        // Given CheckoutClient reports a payment that requires another payment method
        let checkout = try await makeCheckout()
        var responseJSON = makeConfirmedSessionJSON(paymentIntentStatus: "requires_payment_method")
        var paymentResponse = responseJSON["payment_response"] as! [String: Any]
        paymentResponse["last_payment_error"] = [
            "type": "card_error",
            "code": "card_declined",
            "decline_code": "insufficient_funds",
            "message": "Your card has insufficient funds.",
        ]
        responseJSON["payment_response"] = paymentResponse

        // When the Checkout Session is confirmed
        let result = await confirmCheckoutSession(
            checkout,
            responseJSON: responseJSON
        )

        // Then confirmation returns the CheckoutClient payment error
        guard case .failed(let error, _) = result else {
            return XCTFail("Expected confirmation to fail, got \(result)")
        }
        XCTAssertEqual(error._stp_error_code, "card_declined")
    }

    func testOrchestrationConfirmResponseFails() async throws {
        // Given /confirm requires an action without an Intent the SDK can handle
        let checkout = try await makeCheckout()
        var responseJSON = makeConfirmedSessionJSON(status: "open", paymentStatus: "unpaid")
        responseJSON.removeValue(forKey: "payment_intent")
        responseJSON.removeValue(forKey: "setup_intent")
        responseJSON["payment_response"] = ["status": "requires_action"]

        // When the Checkout Session is confirmed
        let result = await confirmCheckoutSession(
            checkout,
            responseJSON: responseJSON
        )

        // Then confirmation fails
        guard case .failed(let error, _) = result else {
            return XCTFail("Expected confirmation to fail, got \(result)")
        }
        XCTAssertTrue(error.nonGenericDescription.contains("without a supported Intent"))
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

    func testNewPaymentMethodDeselectedSendsSaveFalseAndUsesUnspecifiedAllowRedisplay() async throws {
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

    func testNewPaymentMethodSendsPaymentElementPaymentUserAgentBuiltFreshOfProductUsage() async throws {
        // Given a global product usage set already polluted with the labels PaymentElement
        // wraps internally (simulating FlowController/EmbeddedPaymentElement self-registration)
        STPAnalyticsClient.sharedClient.productUsage.formUnion([
            "PaymentSheet.FlowController",
            "EmbeddedPaymentElement",
        ])
        // When confirming a new card PaymentMethod through Checkout's PaymentElement
        // Then payment_method_data[payment_user_agent] is built fresh for PaymentElement,
        // exactly, with no leftover labels from the polluted global product usage set
        try await assertNewPaymentMethodConfirmation(
            session: CheckoutTestHelpers.makeSession().withCustomer(),
            paymentMethodType: .stripe(.card),
            checkboxState: .hidden,
            expectedAllowRedisplay: "unspecified",
            expectedSavePaymentMethod: nil,
            expectedPaymentUserAgent: CheckoutController.ConfirmingElement.paymentElement.paymentUserAgent
        )
    }

    func testNewPaymentMethodWithPerMethodSetupFutureUsageDeselectedUsesLimitedAllowRedisplay() async throws {
        try await assertNewPaymentMethodConfirmation(
            session: CheckoutTestHelpers.makeSession([
                "payment_method_options": ["card": ["setup_future_usage": "off_session"]],
                "setup_future_usage_for_payment_method_type": ["card": "off_session"],
            ]).withCustomer(),
            paymentMethodType: .stripe(.card),
            checkboxState: .deselected,
            expectedAllowRedisplay: "limited",
            expectedSavePaymentMethod: false
        )
    }

    func testNewPaymentMethodWithPerMethodSetupFutureUsageAndOfferSaveDisabledOmitsSaveAndUsesLimitedAllowRedisplay()
        async throws
    {
        try await assertNewPaymentMethodConfirmation(
            session: CheckoutTestHelpers.makeSession([
                "payment_method_options": ["card": ["setup_future_usage": "off_session"]],
                "setup_future_usage_for_payment_method_type": ["card": "off_session"],
                "saved_payment_method_options": [
                    "payment_method_save": "disabled"
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
                "ordered_payment_method_types_and_wallets": ["paypal"]
            ]).withCustomer(),
            paymentMethodType: .stripe(.payPal),
            checkboxState: .selected,
            expectedAllowRedisplay: "always",
            expectedSavePaymentMethod: true
        )
    }

    func testNewPaymentMethodDoesNotReceiveCheckoutEmail() async throws {
        // Given a local Checkout email and a new PaymentMethod without a form-collected email
        // When confirming the new PaymentMethod
        // Then inline payment method data omits billing_details[email]
        try await assertNewPaymentMethodConfirmation(
            session: CheckoutTestHelpers.makeSession().withCustomer(),
            paymentMethodType: .stripe(.card),
            checkboxState: .hidden,
            expectedAllowRedisplay: "unspecified",
            expectedSavePaymentMethod: nil,
            checkoutEmail: "checkout@example.com",
            expectedBillingEmail: .omitted
        )
    }

    func testNewPaymentMethodPreservesFormCollectedEmail() async throws {
        // Given different Checkout and form-collected PaymentMethod emails
        // When confirming the new PaymentMethod
        // Then inline payment method data preserves the form-collected email
        try await assertNewPaymentMethodConfirmation(
            session: CheckoutTestHelpers.makeSession().withCustomer(),
            paymentMethodType: .stripe(.card),
            checkboxState: .hidden,
            expectedAllowRedisplay: "unspecified",
            expectedSavePaymentMethod: nil,
            checkoutEmail: "checkout@example.com",
            paymentMethodEmail: "payment-method@example.com",
            expectedBillingEmail: .value("payment-method@example.com")
        )
    }

    // MARK: - Express Checkout

    func testExpressCheckoutButtonsReenableAfterFailedOrCanceledConfirmation() async throws {
        for paymentIntentStatus in ["requires_payment_method", "canceled"] {
            // Given an open Checkout Session with an available Link button
            let session = CheckoutTestHelpers.makeSessionWithWalletTypes(["card", "link"], customerEmail: "jenny@example.com")
            let checkout = try await makeCheckout(apiResponse: session)
            let view = checkout.getExpressCheckoutElement().uiView
            let button = try XCTUnwrap(CheckoutTestHelpers.expressCheckoutButtons(in: view).first)
            var response = session.allResponseFields
            response["payment_response"] = makeConfirmedSessionJSON(paymentIntentStatus: paymentIntentStatus)["payment_response"]
            stubConfirmation(responseJSON: response)

            // When confirmation fails or is canceled
            let result = await checkout.confirm(makePaymentMethodFlow(for: checkout))

            // Then the open checkout remains interactive
            XCTAssertEqual(checkout.session.status, .open)
            XCTAssertTrue(view.isUserInteractionEnabled)
            XCTAssertTrue(button.isEnabled)
            switch (paymentIntentStatus, result) {
            case ("requires_payment_method", .failed), ("canceled", .canceled):
                break
            default:
                XCTFail("Expected \(paymentIntentStatus) confirmation outcome, got \(result)")
            }
        }
    }

    func testExpressCheckoutApplePayRequiresShippingAddressWhenSessionCollectsShipping() async throws {
        // Given a Checkout Session that collects shipping addresses
        let apiResponse = CheckoutTestHelpers.makeSession([
            "shipping_address_collection": ["allowed_countries": ["US"]]
        ])
        var configuration = CheckoutController.Configuration(
            clientSecret: "cs_test_123_secret_abc",
            returnURL: "stripe-ios-test://checkout-return"
        )
        var eceConfiguration = ExpressCheckoutElement.Configuration(completion: { _ in })
        eceConfiguration.applePayConfiguration = .init(merchantId: "merchant.com.test")
        configuration.expressCheckoutElement = eceConfiguration
        let checkout = try await CheckoutController(
            configuration: CheckoutTestHelpers.makeConfiguration(
                apiResponse: apiResponse,
                configuration: configuration
            )
        )

        // When ECE constructs its Apple Pay confirmation flow
        let flow = try checkout.makeExpressCheckoutConfirmationFlow(.applePay, presentationWindow: nil)

        // Then Apple Pay requires a shipping address
        guard case .applePay(let parameters) = flow else {
            XCTFail("Expected an Apple Pay confirmation flow")
            return
        }
        XCTAssertTrue(parameters.shippingAddressRequired)
    }

    // MARK: - Link

    func testExpressCheckoutLinkBuildsWalletConfirmationFlow() async throws {
        // Given Checkout and ECE configuration containing values needed by Link
        var configuration = CheckoutController.Configuration(
            clientSecret: "cs_test_123_secret_abc",
            returnURL: "stripe-ios-test://custom-return"
        )
        configuration.merchantDisplayName = "Test ECE Merchant"
        configuration.userInterfaceStyle = .alwaysDark
        var billingDetails = CheckoutController.Configuration.Defaults.BillingDetails()
        billingDetails.name = "Jenny Rosen"
        billingDetails.address = .init(country: "US", postalCode: "94107")
        configuration.defaults.billingDetails = billingDetails
        configuration.expressCheckoutElement = ExpressCheckoutElement.Configuration(completion: { _ in })
        let checkout = try await CheckoutController(configuration: CheckoutTestHelpers.makeConfiguration(
            apiResponse: CheckoutTestHelpers.makeSession(["customer_email": "jenny@example.com"]),
            configuration: configuration,
            paymentElementConfiguration: nil
        ))
        let presentingViewController = UIViewController()
        let window = UIWindow()
        window.rootViewController = presentingViewController

        // When ECE constructs its Link confirmation flow
        let flow = try checkout.makeExpressCheckoutConfirmationFlow(.link, presentationWindow: window)

        // Then Link receives the ECE and Checkout configuration
        guard case .link(let parameters) = flow else {
            XCTFail("Expected a Link confirmation flow")
            return
        }
        if case .wallet = parameters.confirmOption {
            // Expected: ECE starts Link as a wallet flow.
        } else {
            XCTFail("Expected a Link wallet confirmation option")
        }
        XCTAssertIdentical(parameters.configuration.apiClient, checkout.configuration.apiClient)
        XCTAssertEqual(parameters.configuration.returnURL, "stripe-ios-test://custom-return")
        XCTAssertEqual(parameters.configuration.merchantDisplayName, "Test ECE Merchant")
        XCTAssertEqual(parameters.configuration.style, .alwaysDark)
        XCTAssertEqual(parameters.configuration.defaultBillingDetails.name, "Jenny Rosen")
        XCTAssertEqual(parameters.configuration.defaultBillingDetails.address.country, "US")
        XCTAssertEqual(parameters.configuration.defaultBillingDetails.address.postalCode, "94107")
        XCTAssertEqual(parameters.configuration.defaultBillingDetails.email, "jenny@example.com")
        XCTAssertNil(parameters.nativeSheetPresentation)
        XCTAssertNil(checkout.paymentElement)
        XCTAssertNotNil(parameters.confirmationChallenge)
    }

    func testExpressCheckoutLinkCollectsRequiredBillingAddress() async throws {
        // Given Checkout requires a full billing address and has no email
        var configuration = CheckoutController.Configuration(clientSecret: "cs_test_123_secret_abc", returnURL: "stripe-ios-test://custom-return")
        configuration.expressCheckoutElement = ExpressCheckoutElement.Configuration(completion: { _ in })
        let checkout = try await CheckoutController(configuration: CheckoutTestHelpers.makeConfiguration(
            apiResponse: CheckoutTestHelpers.makeSession(["billing_address_collection": "required"]),
            configuration: configuration
        ))
        let presentingViewController = UIViewController()
        let window = UIWindow()
        window.rootViewController = presentingViewController

        // When ECE constructs the Link confirmation flow
        let flow = try checkout.makeExpressCheckoutConfirmationFlow(.link, presentationWindow: window)

        // Then Link collects the address without forcing email collection
        guard case .link(let parameters) = flow else {
            XCTFail("Expected a Link confirmation flow")
            return
        }
        XCTAssertEqual(parameters.configuration.billingDetailsCollectionConfiguration.email, .automatic)
        XCTAssertEqual(parameters.configuration.billingDetailsCollectionConfiguration.address, .full)
    }

    func testExpressCheckoutLinkRequiresPresentingViewController() async throws {
        // Given an initialized Checkout controller
        let checkout = try await makeCheckout()

        // When ECE cannot resolve a view controller from its presentation window
        // Then constructing the Link confirmation flow throws
        XCTAssertThrowsError(
            try checkout.makeExpressCheckoutConfirmationFlow(.link, presentationWindow: nil)
        ) { error in
            XCTAssertTrue(error.nonGenericDescription.contains("Could not find a presenting view controller"))
        }
    }

    func testLinkPaymentDetailsConfirmsCheckoutSessionWithPaymentMethodData() async throws {
        // Given Link payment details in non-passthrough mode
        // When Checkout confirms with Link
        // Then Link sends payment method data to Checkout confirmation and logs out
        try await assertLinkPaymentDetailsConfirmsCheckoutSession()
    }

    func testLinkConfirmationSendsPaymentElementPaymentUserAgent() async throws {
        try await assertLinkPaymentDetailsConfirmsCheckoutSession(confirmationSource: .paymentElement, checksPaymentUserAgent: true)
    }

    func testLinkConfirmationSendsExpressCheckoutElementPaymentUserAgent() async throws {
        try await assertLinkPaymentDetailsConfirmsCheckoutSession(confirmationSource: .expressCheckoutElement, checksPaymentUserAgent: true)
    }

    private func assertLinkPaymentDetailsConfirmsCheckoutSession(
        confirmationSource: CheckoutController.ConfirmingElement = .paymentElement,
        checksPaymentUserAgent: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        if checksPaymentUserAgent {
            // Given a global product usage set already polluted with the labels PaymentElement
            // wraps internally (simulating FlowController/EmbeddedPaymentElement self-registration)
            STPAnalyticsClient.sharedClient.productUsage.formUnion([
                "PaymentSheet.FlowController",
                "EmbeddedPaymentElement",
            ])
        }
        let checkout = try await makeCheckout(apiResponse: CheckoutTestHelpers.makeSession().withCustomer())
        let confirm = stubConfirmationExpecting(
            sessionId: checkout.session.id,
            clientSecret: checkout.clientSecret,
            savePaymentMethod: nil,
            expectedPaymentMethodType: "link",
            expectedBillingEmail: .value("test@example.com"),
            expectedPaymentUserAgent: checksPaymentUserAgent ? confirmationSource.paymentUserAgent : nil,
            expectedIntegrationSubtype: confirmationSource.rawValue,
            file: file,
            line: line
        )
        let logout = stubLinkLogout(consumerSessionClientSecret: "cs_xxx")
        let configuration = checkout.getPaymentElement().embeddedPaymentElement.configuration
        let flow = CheckoutController.CheckoutConfirmationFlow.link(.init(
            confirmOption: makeLinkConfirmOption(),
            configuration: configuration,
            nativeSheetPresentation: checkout.getPaymentElement().embeddedPaymentElement.nativeSheetPresentation,
            confirmationChallenge: nil,
            analyticsHelper: ._testValue(),
            authenticationContext: self,
            paymentHandler: STPPaymentHandler(apiClient: configuration.apiClient),
            attribution: .init(confirmingElement: confirmationSource, configuredElements: checkout.configuration.configuredElements)
        ))

        let result = await checkout.confirm(flow)

        assertSucceeded(result, file: file, line: line)
        await fulfillment(of: [confirm, logout], timeout: 10)
    }

    func testLinkConfirmationPollsOpenCheckoutSession() async throws {
        throw XCTSkip("TODO(porter) polling: Enable once polling uses CheckoutClient.")
        // Given Link confirmation returns an open Checkout Session
        let checkout = try await makeCheckout(apiResponse: CheckoutTestHelpers.makeSession().withCustomer())
        var confirmResponseJSON = makeConfirmedSessionJSON(status: "open")
        confirmResponseJSON["session_id"] = checkout.session.id
        let confirm = stubConfirmationExpecting(
            sessionId: checkout.session.id,
            clientSecret: checkout.clientSecret,
            savePaymentMethod: nil,
            responseJSON: confirmResponseJSON,
            expectedPaymentMethodType: "link"
        )
        let poll = stubPollCheckoutSession(sessionId: checkout.session.id)
        let logout = stubLinkLogout(consumerSessionClientSecret: "cs_xxx")
        let configuration = checkout.getPaymentElement().embeddedPaymentElement.configuration
        let flow = CheckoutController.CheckoutConfirmationFlow.link(.init(
            confirmOption: makeLinkConfirmOption(),
            configuration: configuration,
            nativeSheetPresentation: checkout.getPaymentElement().embeddedPaymentElement.nativeSheetPresentation,
            confirmationChallenge: nil,
            analyticsHelper: ._testValue(),
            authenticationContext: self,
            paymentHandler: STPPaymentHandler(apiClient: configuration.apiClient),
            attribution: .init(confirmingElement: .paymentElement, configuredElements: checkout.configuration.configuredElements)
        ))

        // When Checkout confirms with Link
        let result = await checkout.confirm(flow)

        // Then Link polls until the Checkout Session confirmation is complete
        assertSucceeded(result)
        await fulfillment(of: [confirm, poll, logout], timeout: 10)
    }

    func testLinkConfirmationCompletesOpenCheckoutSession() async throws {
        // Given Link confirmation returns an open Checkout Session
        let checkout = try await makeCheckout(apiResponse: CheckoutTestHelpers.makeSession().withCustomer())
        var confirmResponseJSON = makeConfirmedSessionJSON(status: "open")
        confirmResponseJSON["id"] = checkout.session.id
        let confirm = stubConfirmationExpecting(
            sessionId: checkout.session.id,
            clientSecret: checkout.clientSecret,
            savePaymentMethod: nil,
            responseJSON: confirmResponseJSON,
            expectedPaymentMethodType: "link"
        )
        let logout = stubLinkLogout(consumerSessionClientSecret: "cs_xxx")
        let configuration = checkout.getPaymentElement().embeddedPaymentElement.configuration
        let flow = CheckoutController.CheckoutConfirmationFlow.link(
            .init(
            confirmOption: makeLinkConfirmOption(),
            configuration: configuration,
            nativeSheetPresentation: checkout.getPaymentElement().embeddedPaymentElement.nativeSheetPresentation,
            confirmationChallenge: nil,
            analyticsHelper: ._testValue(),
            authenticationContext: self,
            paymentHandler: STPPaymentHandler(apiClient: configuration.apiClient),
            attribution: .init(confirmingElement: .paymentElement, configuredElements: checkout.configuration.configuredElements)
            )
        )

        // When Checkout confirms with Link
        let result = await checkout.confirm(flow)

        // Then Link completes confirmation from the returned Intent
        assertSucceeded(result)
        await fulfillment(of: [confirm, logout], timeout: 10)
    }

    // MARK: - Inline payment method request and challenge lifecycle

    func testNewPaymentMethodSendsInlineDataAndCompletesChallengeAfterResponse() async throws {
        let fraudData = FraudDetectionData.shared
        let originalFraudData = (fraudData.guid, fraudData.muid, fraudData.sid, fraudData.sidCreationDate)
        fraudData.guid = "test_guid"
        fraudData.muid = "test_muid"
        fraudData.sid = "test_sid"
        fraudData.sidCreationDate = Date()
        defer {
            (fraudData.guid, fraudData.muid, fraudData.sid, fraudData.sidCreationDate) = originalFraudData
        }

        try await assertChallengeCompletesAfterConfirm(statusCode: 200) { params in
            XCTAssertNil(params["payment_method"])
            XCTAssertEqual(params["payment_method_data[type]"], "card")
            XCTAssertEqual(params["payment_method_data[card][number]"], "4242424242424242")
            XCTAssertNotNil(params["payment_method_data[payment_user_agent]"])
            XCTAssertEqual(params["payment_method_data[guid]"], "test_guid")
            XCTAssertEqual(params["payment_method_data[muid]"], "test_muid")
            XCTAssertEqual(params["payment_method_data[sid]"], "test_sid")
            XCTAssertEqual(params["payment_method_data[client_attribution_metadata][checkout_session_id]"], "cs_test_123")
            XCTAssertEqual(params["client_attribution_metadata[checkout_session_id]"], "cs_test_123")
        }
    }

    func testNewPaymentMethodCompletesChallengeAfterConfirmFailure() async throws {
        let previousHistory = STPAnalyticsClient.sharedClient._testLogHistory
        STPAnalyticsClient.sharedClient._testLogHistory = []
        defer { STPAnalyticsClient.sharedClient._testLogHistory = previousHistory }

        try await assertChallengeCompletesAfterConfirm(statusCode: 400)

        // Confirmation analytics retains the API error fields and failing request ID.
        let events = confirmationEvents
        XCTAssertEqual(events.compactMap { $0["event"] as? String }, [
            "checkout_elements.confirm.started",
            "checkout_elements.confirm.failed",
        ])
        let failed = try XCTUnwrap(events.last)
        XCTAssertEqual(failed["error_type"] as? String, "card_error")
        XCTAssertEqual(failed["error_code"] as? String, "card_declined")
        XCTAssertEqual(failed["request_id"] as? String, "req_confirm_challenge")
    }

    private func assertChallengeCompletesAfterConfirm(
        statusCode: Int,
        inspectRequest: @escaping ([String: String]) -> Void = { _ in }
    ) async throws {
        // Given a new card whose confirmation has a Radar challenge
        let checkout = try await makeCheckout()
        let challenge = TestConfirmationChallenge()
        stubConfirmedIntentRetrieval(from: Self.confirmedSessionJSON)
        stub { request in
            request.url?.path.hasSuffix("/confirm") == true
        } response: { request in
            let params = RequestBodyTestHelpers.formEncodedBodyParams(from: request, omittingEmptyValues: true)
            XCTAssertEqual(params["payment_method_data[radar_options][hcaptcha_token]"], "captcha_token")
            XCTAssertEqual(
                params["payment_method_data[radar_options][ios_verification_object][test_assertion]"],
                "assertion"
            )
            inspectRequest(params)
            // Check before supplying the response, without relying on a response delay.
            XCTAssertEqual(challenge.completions, 0)
            return HTTPStubsResponse(
                jsonObject: statusCode == 200 ? Self.confirmedSessionJSON : ["error": ["type": "card_error", "code": "card_declined", "message": "Declined"]],
                statusCode: Int32(statusCode),
                headers: ["Request-Id": "req_confirm_challenge"]
            )
        }

        // When confirming the new payment method
        let flow = makePaymentMethodFlow(
            for: checkout,
            option: .new(makeConfirmParams(type: .stripe(.card))),
            confirmationChallenge: challenge
        )
        let result = await checkout.confirm(flow)

        // Then cleanup runs once after success or failure, before confirm returns
        if statusCode == 200 {
            assertSucceeded(result)
        } else {
            guard case .failed = result else { return XCTFail("Expected failed confirmation") }
        }
        XCTAssertEqual(challenge.completions, 1)
    }

    private final class TestConfirmationChallenge: CheckoutConfirmationChallenge {
        private let lock = NSLock()
        private var completionCount = 0

        var completions: Int {
            lock.lock()
            defer { lock.unlock() }
            return completionCount
        }

        func makeRadarOptions(for paymentMethodType: STPPaymentMethodType) async -> STPRadarOptions? {
            XCTAssertEqual(paymentMethodType, .card)
            let options = STPRadarOptions(hcaptchaToken: "captcha_token")
            options.iosVerificationObject = ["test_assertion": "assertion"]
            return options
        }

        func complete() async {
            recordCompletion()
        }

        private func recordCompletion() {
            lock.lock()
            defer { lock.unlock() }
            completionCount += 1
        }
    }

    // MARK: - Helpers

    private static var confirmedSessionJSON: [AnyHashable: Any] {
        var json = STPTestUtils.jsonNamed("CheckoutSessionConfirmed")!
        json["id"] = "cs_test_123"
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
        option: CheckoutController.PaymentMethodConfirmationParameters.Option,
        confirmationChallenge: (any CheckoutConfirmationChallenge)? = nil
    ) -> CheckoutController.CheckoutConfirmationFlow {
        let configuration = checkout.getPaymentElement().embeddedPaymentElement.configuration
        let parameters = CheckoutController.PaymentMethodConfirmationParameters(
            option: option,
            configuration: configuration,
            nativeSheetPresentation: checkout.getPaymentElement().embeddedPaymentElement.nativeSheetPresentation,
            confirmationChallenge: confirmationChallenge,
            authenticationContext: self,
            paymentHandler: STPPaymentHandler(apiClient: configuration.apiClient),
            attribution: .init(confirmingElement: .paymentElement, configuredElements: checkout.configuration.configuredElements)
        )
        return .paymentMethod(parameters, preconfirmIntegrationShape: .embedded)
    }

    private func assertNewPaymentMethodConfirmation(
        session: PaymentPagesAPIResponse,
        paymentMethodType: PaymentSheet.PaymentMethodType,
        checkboxState: IntentConfirmParams.SaveForFutureUseCheckboxState,
        expectedAllowRedisplay: String,
        expectedSavePaymentMethod: Bool?,
        checkoutEmail: String? = nil,
        paymentMethodEmail: String? = nil,
        expectedBillingEmail: BillingEmailExpectation? = nil,
        expectedPaymentUserAgent: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let checkout = try await makeCheckout(apiResponse: session)
        if let checkoutEmail {
            try await checkout.updateEmail(checkoutEmail)
        }
        let confirmParams = makeConfirmParams(type: paymentMethodType)
        confirmParams.paymentMethodParams.nonnil_billingDetails.email = paymentMethodEmail
        confirmParams.saveForFutureUseCheckboxState = checkboxState
        let confirm = stubConfirmationExpecting(
            sessionId: checkout.session.id,
            clientSecret: checkout.clientSecret,
            savePaymentMethod: expectedSavePaymentMethod,
            expectedCollectedInformationEmail: checkoutEmail,
            expectedPaymentMethodType: try XCTUnwrap(confirmParams.paymentMethodParams.rawTypeString),
            expectedAllowRedisplay: expectedAllowRedisplay,
            expectedBillingEmail: expectedBillingEmail,
            expectedPaymentUserAgent: expectedPaymentUserAgent,
            file: file,
            line: line
        )

        let result = await checkout.confirm(
            makePaymentMethodFlow(for: checkout, option: .new(confirmParams))
        )

        assertSucceeded(result, file: file, line: line)
        await fulfillment(of: [confirm], timeout: 10)
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
            var paymentResponse = responseJSON["payment_response"] as! [String: Any]
            paymentResponse["status"] = paymentIntentStatus
            responseJSON["payment_response"] = paymentResponse
        }
        if let status {
            responseJSON["status"] = status
        }
        if let paymentStatus {
            responseJSON["payment_status"] = paymentStatus
        }
        return responseJSON
    }

    private func stubConfirmedIntentRetrieval(
        from responseJSON: [AnyHashable: Any],
        intentJSON: [AnyHashable: Any]? = nil
    ) {
        let paymentResponse = responseJSON["payment_response"] as? [String: Any] ?? [:]
        for (key, endpoint, fixture) in [
            ("payment_intent", "payment_intents", "CheckoutPaymentIntent"),
            ("setup_intent", "setup_intents", "SetupIntent"),
        ] {
            guard let reference = paymentResponse[key] as? [String: Any],
                let id = reference["id"] as? String
            else { continue }
            var intent = intentJSON ?? STPTestUtils.jsonNamed(fixture)!
            intent["id"] = id
            intent["client_secret"] = reference["client_secret"]
            intent["status"] = paymentResponse["status"]
            stub { request in
                request.httpMethod == "GET" && request.url?.path == "/v1/\(endpoint)/\(id)"
            } response: { _ in
                HTTPStubsResponse(jsonObject: intent, statusCode: 200, headers: nil)
            }
        }
    }

    private func confirmCheckoutSession(
        _ checkout: CheckoutController,
        responseJSON: [AnyHashable: Any],
        intentJSON: [AnyHashable: Any]? = nil,
        poller: any CheckoutSessionPolling = TestCheckoutSessionPoller(outcome: .completed)
    ) async -> CheckoutController.InternalConfirmResult {
        stubConfirmation(responseJSON: responseJSON, intentJSON: intentJSON)
        let configuration = checkout.getPaymentElement().embeddedPaymentElement.configuration
        let requestParameters = CheckoutSessionConfirmationRequestParameters.createWithPaymentMethodID(
            sessionId: checkout.session.id,
            clientSecret: checkout.clientSecret,
            paymentMethodId: STPPaymentMethod._testCard().stripeId,
            confirmationSource: .paymentElement,
            expectedAmount: checkout.session.amount,
            expectedPaymentMethodType: "card",
            returnURL: configuration.returnURL,
            shipping: STPPaymentIntentShippingDetailsParams(paymentSheetConfiguration: configuration),
            collectedInformation: .init(email: checkout.session.localState.email)
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
        responseTime: TimeInterval = 0,
        intentJSON: [AnyHashable: Any]? = nil
    ) {
        let responseJSON = responseJSON ?? Self.confirmedSessionJSON
        stubConfirmedIntentRetrieval(from: responseJSON, intentJSON: intentJSON)
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
                && request.url?.path.hasSuffix("/checkout_client/cs_test_123/retrieve") == true
        } response: { _ in
            self.stubConfirmedIntentRetrieval(from: responseJSON)
            expectation.fulfill()
            return HTTPStubsResponse(
                jsonObject: (responseJSON as? [String: Any] ?? [:]),
                statusCode: 200,
                headers: nil
            )
        }
        return expectation
    }

    private func stubConfirmationExpecting(
        sessionId: String,
        clientSecret: String,
        savePaymentMethod: Bool?,
        expectedCollectedInformationEmail: String? = nil,
        responseJSON: [AnyHashable: Any]? = nil,
        expectedPaymentMethodType: String,
        expectedPaymentMethodID: String? = nil,
        expectedAllowRedisplay: String? = nil,
        expectedBillingEmail: BillingEmailExpectation? = nil,
        expectedPaymentUserAgent: String? = nil,
        expectedIntegrationSubtype: String = "mobile-payment-element",
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCTestExpectation {
        let expectation = expectation(description: "Checkout Session confirm requested")
        stubConfirmedIntentRetrieval(from: responseJSON ?? Self.confirmedSessionJSON)
        stub { request in
            guard let pathComponents = request.url?.pathComponents else { return false }
            return pathComponents.contains("checkout_client")
                && pathComponents.contains(sessionId)
                && pathComponents.last == "confirm"
        } response: { request in
            let params = RequestBodyTestHelpers.formEncodedBodyParams(
                from: request,
                omittingEmptyValues: true,
                line: line
            )
            XCTAssertEqual(params["client_secret"], clientSecret, file: file, line: line)
            XCTAssertEqual(params["payment_method"], expectedPaymentMethodID, file: file, line: line)
            if expectedPaymentMethodID != nil {
                XCTAssertFalse(params.keys.contains { $0.hasPrefix("payment_method_data[") }, file: file, line: line)
            } else {
                XCTAssertEqual(params["payment_method_data[type]"], expectedPaymentMethodType, file: file, line: line)
                XCTAssertNotNil(params["payment_method_data[payment_user_agent]"], file: file, line: line)
                if let expectedPaymentUserAgent {
                    XCTAssertEqual(params["payment_method_data[payment_user_agent]"], expectedPaymentUserAgent, file: file, line: line)
                }
                XCTAssertEqual(params["payment_method_data[guid]"], FraudDetectionData.shared.guid, file: file, line: line)
                XCTAssertEqual(params["payment_method_data[muid]"], FraudDetectionData.shared.muid, file: file, line: line)
                XCTAssertEqual(params["payment_method_data[sid]"], FraudDetectionData.shared.sid, file: file, line: line)
                XCTAssertEqual(params["payment_method_data[client_attribution_metadata][checkout_session_id]"], sessionId, file: file, line: line)
                if expectedPaymentMethodType == "card" {
                    XCTAssertEqual(params["payment_method_data[card][number]"], "4242424242424242", file: file, line: line)
                }
            }
            XCTAssertEqual(params["expected_payment_method_type"], expectedPaymentMethodType, file: file, line: line)
            XCTAssertEqual(params["client_attribution_metadata[checkout_session_id]"], sessionId, file: file, line: line)
            let metadataPrefixes = expectedPaymentMethodID == nil
                ? ["client_attribution_metadata", "payment_method_data[client_attribution_metadata]"]
                : ["client_attribution_metadata"]
            for prefix in metadataPrefixes {
                XCTAssertEqual(params["\(prefix)[merchant_integration_source]"], "mobile-checkout", file: file, line: line)
                XCTAssertEqual(params["\(prefix)[merchant_integration_subtype]"], expectedIntegrationSubtype, file: file, line: line)
            }
            if let expectedAllowRedisplay {
                XCTAssertEqual(
                    params["payment_method_data[allow_redisplay]"],
                    expectedAllowRedisplay,
                    file: file,
                    line: line
                )
            }
            switch expectedBillingEmail {
            case .omitted:
                XCTAssertNil(params["payment_method_data[billing_details][email]"], file: file, line: line)
            case .value(let email):
                XCTAssertEqual(params["payment_method_data[billing_details][email]"], email, file: file, line: line)
            case nil:
                break
            }
            XCTAssertEqual(
                params["collected_information[save_payment_method]"],
                savePaymentMethod.map(String.init),
                file: file,
                line: line
            )
            if let expectedCollectedInformationEmail {
                XCTAssertEqual(
                    params["collected_information[email]"],
                    expectedCollectedInformationEmail,
                    file: file,
                    line: line
                )
                XCTAssertNil(params["customer_data[email]"], file: file, line: line)
            }
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

    private enum BillingEmailExpectation {
        case omitted
        case value(String)
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

extension CheckoutConfirmationStubbedTests: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        UIViewController()
    }
}

private struct CheckoutConfirmationTestTimeoutError: Error {}

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

private extension CheckoutController {
    func confirm(_ flow: CheckoutConfirmationFlow) async -> ConfirmResult {
        return await confirm(source: .merchant) { flow }
    }
}
