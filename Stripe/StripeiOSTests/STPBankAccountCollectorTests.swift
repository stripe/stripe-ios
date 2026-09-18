//
//  STPBankAccountCollectorTests.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 7/7/25.
//

import OHHTTPStubs
import OHHTTPStubsSwift
@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
import StripeCoreTestUtils
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable import StripePaymentsTestUtils
@testable@_spi(STP) import StripePaymentsUI
import UIKit
import XCTest

final class STPBankAccountCollectorTests: APIStubbedTestCase {

    // MARK: - Tests

    func testDefaultInitialization() {
        let collector = STPBankAccountCollector()
        XCTAssertTrue(collector.apiClient === STPAPIClient.shared)
        XCTAssertEqual(collector.style, .automatic)
    }

    func testCustomInitialization() {
        let apiClient = stubbedAPIClient()
        let collector = STPBankAccountCollector(apiClient: apiClient, style: .alwaysDark)
        XCTAssertTrue(collector.apiClient === apiClient)
        XCTAssertEqual(collector.style, .alwaysDark)
    }

    func testUserInterfaceStyleMapping() {
        XCTAssertEqual(STPBankAccountCollectorUserInterfaceStyle.automatic.asFinancialConnectionsConfigurationStyle, .automatic)
        XCTAssertEqual(STPBankAccountCollectorUserInterfaceStyle.alwaysLight.asFinancialConnectionsConfigurationStyle, .alwaysLight)
        XCTAssertEqual(STPBankAccountCollectorUserInterfaceStyle.alwaysDark.asFinancialConnectionsConfigurationStyle, .alwaysDark)
    }

    func testCollectBankAccountForPaymentInvalidSecretReturnsError() {
        let collector = STPBankAccountCollector(apiClient: stubbedAPIClient())
        let expectation = expectation(description: "completion")

        collector.collectBankAccountForPayment(
            clientSecret: "invalid_secret", // Does not contain pi_..._secret_...
            params: makeParams(),
            from: UIViewController()
        ) { intent, error in
            XCTAssertNil(intent)
            let nsError = error as NSError?
            XCTAssertNotNil(nsError)
            XCTAssertEqual(nsError?.domain, "STPBankAccountCollectorErrorDomain")
            XCTAssertEqual(nsError?.code, STPCollectBankAccountError.invalidClientSecret.rawValue)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0)
    }

    func testCollectBankAccountForSetupInvalidSecretReturnsError() {
        let collector = STPBankAccountCollector(apiClient: stubbedAPIClient())
        let expectation = expectation(description: "completion")

        collector.collectBankAccountForSetup(
            clientSecret: "invalid_secret", // Does not contain seti_..._secret_...
            params: makeParams(),
            from: UIViewController()
        ) { intent, error in
            XCTAssertNil(intent)
            let nsError = error as NSError?
            XCTAssertNotNil(nsError)
            XCTAssertEqual(nsError?.domain, "STPBankAccountCollectorErrorDomain")
            XCTAssertEqual(nsError?.code, STPCollectBankAccountError.invalidClientSecret.rawValue)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0)
    }

    func testCollectBankAccountForPaymentSucceeds() {
        let paymentIntentID = "pi_123"
        let clientSecret = "\(paymentIntentID)_secret_abc"

        // Set up stubs for network interactions
        stubCreateLinkAccountSession(
            paymentIntentID: paymentIntentID,
            expectedAdditionalBillingDetails: [:]
        )
        stubAttachLinkAccountSession(paymentIntentID: paymentIntentID)

        let collector = STPBankAccountCollector(apiClient: stubbedAPIClient())
        let expectation = expectation(description: "completion")

        collector.collectBankAccountForPayment(
            clientSecret: clientSecret,
            params: makeParams(),
            from: UIViewController()
        ) { intent, error in
            XCTAssertNil(error)
            XCTAssertEqual(intent?.stripeId, paymentIntentID)
            XCTAssertEqual(intent?.status, .succeeded)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0)
    }

    func testCollectBankAccountForPaymentWithBillingDetailsSucceeds() {
        let paymentIntentID = "pi_billing_details"
        let clientSecret = "\(paymentIntentID)_secret_abc"
        let expectedBillingDetails = additionalBillingDetails
        stubCreateLinkAccountSession(
            paymentIntentID: paymentIntentID,
            expectedAdditionalBillingDetails: expectedBillingDetails
        )
        stubAttachLinkAccountSession(paymentIntentID: paymentIntentID)

        let collector = STPBankAccountCollector(apiClient: stubbedAPIClient())
        let expectation = expectation(description: "completion")

        collector.collectBankAccountForPayment(
            clientSecret: clientSecret,
            params: makeParamsWithBillingDetails(),
            from: UIViewController()
        ) { intent, error in
            XCTAssertNil(error)
            XCTAssertEqual(intent?.stripeId, paymentIntentID)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0)
    }

    func testCollectBankAccountForPaymentSucceedsAsync() async throws {
        let paymentIntentID = "pi_123"
        let clientSecret = "\(paymentIntentID)_secret_abc"

        // Set up stubs for network interactions
        stubCreateLinkAccountSession(paymentIntentID: paymentIntentID)
        stubAttachLinkAccountSession(paymentIntentID: paymentIntentID)

        let collector = STPBankAccountCollector(apiClient: stubbedAPIClient())

        let intent = try await collector.collectBankAccountForPayment(
            clientSecret: clientSecret,
            params: makeParams(),
            from: UIViewController()
        )
        XCTAssertEqual(intent.stripeId, paymentIntentID)
        XCTAssertEqual(intent.status, .succeeded)
    }

    func testCollectBankAccountForPaymentWithReturnURLSucceeds() {
        let paymentIntentID = "pi_456"
        let clientSecret = "\(paymentIntentID)_secret_xyz"
        stubCreateLinkAccountSession(paymentIntentID: paymentIntentID)
        stubAttachLinkAccountSession(paymentIntentID: paymentIntentID)

        let collector = STPBankAccountCollector(apiClient: stubbedAPIClient())
        let exp = expectation(description: "completion")

        collector.collectBankAccountForPayment(
            clientSecret: clientSecret,
            returnURL: "myapp://stripe-return",
            params: makeParams(),
            from: UIViewController()
        ) { intent, error in
            XCTAssertNil(error)
            XCTAssertEqual(intent?.stripeId, paymentIntentID)
            exp.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testCollectBankAccountForSetupSucceeds() {
        let setupIntentID = "seti_456"
        let clientSecret = "\(setupIntentID)_secret_xyz"
        stubCreateLinkAccountSessionForSetupIntent(
            setupIntentID: setupIntentID,
            expectedAdditionalBillingDetails: additionalBillingDetails
        )
        stubAttachLinkAccountSessionToSetupIntent(setupIntentID: setupIntentID)

        let collector = STPBankAccountCollector(apiClient: stubbedAPIClient())
        let exp = expectation(description: "completion")

        collector.collectBankAccountForSetup(
            clientSecret: clientSecret,
            params: makeParamsWithBillingDetails(),
            from: UIViewController()
        ) { intent, error in
            XCTAssertNil(error)
            XCTAssertEqual(intent?.stripeID, setupIntentID)
            XCTAssertEqual(intent?.status, .succeeded)
            exp.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testCollectBankAccountForSetupSucceedsAsync() async throws {
        let setupIntentID = "seti_456"
        let clientSecret = "\(setupIntentID)_secret_xyz"

        // Set up stubs for network interactions
        stubCreateLinkAccountSessionForSetupIntent(setupIntentID: setupIntentID)
        stubAttachLinkAccountSessionToSetupIntent(setupIntentID: setupIntentID)

        let collector = STPBankAccountCollector(apiClient: stubbedAPIClient())

        let intent = try await collector.collectBankAccountForSetup(
            clientSecret: clientSecret,
            params: makeParams(),
            from: UIViewController()
        )
        XCTAssertEqual(intent.stripeID, setupIntentID)
        XCTAssertEqual(intent.status, .succeeded)
    }

    func testCollectBankAccountForDeferredIntentSucceeds() {
        stubCreateLinkAccountSessionForDeferredIntent()

        let collector = STPBankAccountCollector(apiClient: stubbedAPIClient())
        let exp = expectation(description: "completion")

        collector.collectBankAccountForDeferredIntentOrCheckoutSession(
            sessionId: "sess_123",
            returnURL: nil,
            onEvent: nil,
            amount: nil,
            currency: nil,
            onBehalfOf: nil,
            additionalParameters: [:],
            elementsSessionContext: nil,
            from: UIViewController(),
            intentType: .deferred
        ) { result, linkAccountSession, error in
            XCTAssertNil(error)
            if case .completed? = result { } else {
                XCTFail("Result was not completed")
            }
            XCTAssertEqual(linkAccountSession?.stripeID, "las_789")
            exp.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testCollectBankAccountForCheckoutSessionSucceeds() {
        // Checkout Sessions calls the link_account_sessions_for_deferred_payment endpoint, so we stub it
        stubCreateLinkAccountSessionForDeferredIntent()

        let collector = STPBankAccountCollector(apiClient: stubbedAPIClient())
        let exp = expectation(description: "completion")

        collector.collectBankAccountForDeferredIntentOrCheckoutSession(
            sessionId: "sess_456",
            returnURL: "myapp://stripe-return",
            onEvent: nil,
            amount: 1000,
            currency: "usd",
            onBehalfOf: nil,
            additionalParameters: ["hosted_surface": "payment_element"],
            elementsSessionContext: nil,
            from: UIViewController(),
            intentType: .checkoutSession
        ) { result, linkAccountSession, error in
            XCTAssertNil(error)
            if case .completed? = result { } else {
                XCTFail("Result was not completed")
            }
            XCTAssertEqual(linkAccountSession?.stripeID, "las_789")
            exp.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    // MARK: - OnEvent Callback Tests

    func testCollectBankAccountForPaymentWithOnEventCallback() {
        let paymentIntentID = "pi_with_events"
        let clientSecret = "\(paymentIntentID)_secret_events"

        stubCreateLinkAccountSession(paymentIntentID: paymentIntentID)
        stubAttachLinkAccountSession(paymentIntentID: paymentIntentID)

        let collector = STPBankAccountCollector(apiClient: stubbedAPIClient())
        let completionExp = expectation(description: "completion")

        collector.collectBankAccountForPayment(
            clientSecret: clientSecret,
            returnURL: nil,
            params: makeParams(),
            from: UIViewController(),
            onEvent: { _ in
                // Event callback is called - this verifies the API accepts the parameter
                // Note: In test environment, this may not be called due to mocked Financial Connections SDK
            }
        ) { intent, error in
            XCTAssertNil(error)
            XCTAssertEqual(intent?.stripeId, paymentIntentID)
            completionExp.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testCollectBankAccountForSetupWithOnEventCallback() {
        let setupIntentID = "seti_with_events"
        let clientSecret = "\(setupIntentID)_secret_events"

        stubCreateLinkAccountSessionForSetupIntent(setupIntentID: setupIntentID)
        stubAttachLinkAccountSessionToSetupIntent(setupIntentID: setupIntentID)

        let collector = STPBankAccountCollector(apiClient: stubbedAPIClient())
        let completionExp = expectation(description: "completion")

        collector.collectBankAccountForSetup(
            clientSecret: clientSecret,
            returnURL: nil,
            params: makeParams(),
            from: UIViewController(),
            onEvent: { _ in
                // Event callback is called - this verifies the API accepts the parameter
                // Note: In test environment, this may not be called due to mocked Financial Connections SDK
            }
        ) { intent, error in
            XCTAssertNil(error)
            XCTAssertEqual(intent?.stripeID, setupIntentID)
            completionExp.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    // MARK: - Setup Intent with Return URL Tests

    func testCollectBankAccountForSetupWithReturnURLSucceeds() {
        let setupIntentID = "seti_with_return_url"
        let clientSecret = "\(setupIntentID)_secret_return"

        stubCreateLinkAccountSessionForSetupIntent(setupIntentID: setupIntentID)
        stubAttachLinkAccountSessionToSetupIntent(setupIntentID: setupIntentID)

        let collector = STPBankAccountCollector(apiClient: stubbedAPIClient())
        let exp = expectation(description: "completion")

        collector.collectBankAccountForSetup(
            clientSecret: clientSecret,
            returnURL: "myapp://stripe-setup-return",
            params: makeParams(),
            from: UIViewController()
        ) { intent, error in
            XCTAssertNil(error)
            XCTAssertEqual(intent?.stripeID, setupIntentID)
            exp.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    // MARK: - Collect Bank Account Params Tests

    func testUSBankAccountParamsWithBillingDetails() {
        let address = makeAddress()
        let params = STPCollectBankAccountParams.collectUSBankAccountParams(
            with: "Test Customer",
            email: "customer@example.com",
            address: address,
            phone: "+15555550100"
        )

        let billingDetails = params.paymentMethodParams.billingDetails
        XCTAssertEqual(billingDetails?.name, "Test Customer")
        XCTAssertEqual(billingDetails?.email, "customer@example.com")
        XCTAssertEqual(billingDetails?.address, address)
        XCTAssertEqual(billingDetails?.phone, "+15555550100")
        XCTAssertEqual(params.paymentMethodParams.type, .USBankAccount)
    }

    func testInstantDebitsParams() {
        let params = STPCollectBankAccountParams.collectInstantDebitsParams(email: "test@example.com")
        XCTAssertEqual(params.paymentMethodParams.billingDetails?.email, "test@example.com")
        XCTAssertEqual(params.paymentMethodParams.type, STPPaymentMethodType.link)
        // Note: Instant debits uses .link type, not .USBankAccount, so no account type is set
    }

    // MARK: - Error Scenarios Tests

    func testFinancialConnectionsSDKNotLinkedError() {
        // This test verifies that the error type exists and has the correct properties
        let error = STPCollectBankAccountError.financialConnectionsSDKNotLinked
        XCTAssertEqual(error.rawValue, 0)
    }

    func testUnexpectedError() {
        let error = STPCollectBankAccountError.unexpectedError
        XCTAssertEqual(error.rawValue, 2)
    }

    // MARK: - Additional Helper Methods for New Tests

    private func stubRetrievePaymentIntent(paymentIntentID: String) {
        stub(condition:
                isHost("api.stripe.com") &&
                isPath("/v1/payment_intents/\(paymentIntentID)") &&
                isMethodGET()
        ) { _ in
            let response: [String: Any] = [
                "id": paymentIntentID,
                "object": "payment_intent",
                "status": "requires_payment_method",
                "client_secret": "\(paymentIntentID)_secret_cancelled",
            ]
            return HTTPStubsResponse(jsonObject: response, statusCode: 200, headers: nil)
        }
    }

    private func stubRetrieveSetupIntent(setupIntentID: String) {
        stub(condition:
                isHost("api.stripe.com") &&
                isPath("/v1/setup_intents/\(setupIntentID)") &&
                isMethodGET()
        ) { _ in
            let response: [String: Any] = [
                "id": setupIntentID,
                "object": "setup_intent",
                "status": "requires_payment_method",
                "client_secret": "\(setupIntentID)_secret_cancelled",
                "created": 1609459200,
                "payment_method_types": ["us_bank_account"],
                "livemode": false,
            ]
            return HTTPStubsResponse(jsonObject: response, statusCode: 200, headers: nil)
        }
    }

    // MARK: - Helpers

    private var additionalBillingDetails: [String: String] {
        return [
            "payment_method_data[billing_details][address][city]": "Springfield",
            "payment_method_data[billing_details][address][country]": "US",
            "payment_method_data[billing_details][address][line1]": "123 Main Street",
            "payment_method_data[billing_details][address][line2]": "Apt 4",
            "payment_method_data[billing_details][address][postal_code]": "12345",
            "payment_method_data[billing_details][address][state]": "CA",
            "payment_method_data[billing_details][phone]": "+15555550100",
        ]
    }

    private func makeAddress() -> STPPaymentMethodAddress {
        let address = STPPaymentMethodAddress()
        address.city = "Springfield"
        address.country = "US"
        address.line1 = "123 Main Street"
        address.line2 = "Apt 4"
        address.postalCode = "12345"
        address.state = "CA"
        return address
    }

    private func makeParams() -> STPCollectBankAccountParams {
        return STPCollectBankAccountParams.collectUSBankAccountParams(with: "Jane Doe", email: "jane@example.com")
    }

    private func makeParamsWithBillingDetails() -> STPCollectBankAccountParams {
        return STPCollectBankAccountParams.collectUSBankAccountParams(
            with: "Test Customer",
            email: "customer@example.com",
            address: makeAddress(),
            phone: "+15555550100"
        )
    }

    private func stubCreateLinkAccountSession(
        paymentIntentID: String,
        linkAccountSessionID: String = "las_123",
        expectedAdditionalBillingDetails: [String: String]? = nil
    ) {
        stub(condition:
                isHost("api.stripe.com") &&
                isPath("/v1/payment_intents/\(paymentIntentID)/link_account_sessions") &&
                isMethodPOST()
        ) { request in
            if let expectedAdditionalBillingDetails {
                self.assertAdditionalBillingDetails(
                    in: request,
                    equalTo: expectedAdditionalBillingDetails
                )
            }
            let response: [String: Any] = [
                "id": linkAccountSessionID,
                "livemode": false,
                "client_secret": "\(linkAccountSessionID)_secret_456",
            ]
            return HTTPStubsResponse(jsonObject: response, statusCode: 200, headers: nil)
        }
    }

    private func stubAttachLinkAccountSession(paymentIntentID: String, linkAccountSessionID: String = "las_123") {
        stub(condition:
                isHost("api.stripe.com") &&
                isPath("/v1/payment_intents/\(paymentIntentID)/link_account_sessions/\(linkAccountSessionID)/attach") &&
                isMethodPOST()
        ) { _ in
            let response: [String: Any] = [
                "id": paymentIntentID,
                "object": "payment_intent",
                "status": "succeeded",
                "client_secret": "\(paymentIntentID)_secret_abc",
            ]
            return HTTPStubsResponse(jsonObject: response, statusCode: 200, headers: nil)
        }
    }

    private func stubCreateLinkAccountSessionForSetupIntent(
        setupIntentID: String,
        linkAccountSessionID: String = "las_123",
        expectedAdditionalBillingDetails: [String: String]? = nil
    ) {
        stub(condition:
                isHost("api.stripe.com") &&
                isPath("/v1/setup_intents/\(setupIntentID)/link_account_sessions") &&
                isMethodPOST()
        ) { request in
            if let expectedAdditionalBillingDetails {
                self.assertAdditionalBillingDetails(
                    in: request,
                    equalTo: expectedAdditionalBillingDetails
                )
            }
            let response: [String: Any] = [
                "id": linkAccountSessionID,
                "livemode": false,
                "client_secret": "\(linkAccountSessionID)_secret_456",
            ]
            return HTTPStubsResponse(jsonObject: response, statusCode: 200, headers: nil)
        }
    }

    private func stubAttachLinkAccountSessionToSetupIntent(setupIntentID: String, linkAccountSessionID: String = "las_123") {
        stub(condition:
                isHost("api.stripe.com") &&
                isPath("/v1/setup_intents/\(setupIntentID)/link_account_sessions/\(linkAccountSessionID)/attach") &&
                isMethodPOST()
        ) { _ in
            let response: [String: Any] = [
                "id": setupIntentID,
                "object": "setup_intent",
                "status": "succeeded",
                "client_secret": "\(setupIntentID)_secret_def",
                "created": 1609459200,
                "payment_method_types": ["us_bank_account"],
                "livemode": false,
            ]
            return HTTPStubsResponse(jsonObject: response, statusCode: 200, headers: nil)
        }
    }

    private func assertAdditionalBillingDetails(
        in request: URLRequest,
        equalTo expectedBillingDetails: [String: String]
    ) {
        let body = String(data: request.httpBodyOrBodyStream ?? Data(), encoding: .utf8) ?? ""
        let formFields = decodeFormFields(from: body)
        for key in additionalBillingDetails.keys {
            XCTAssertEqual(formFields[key], expectedBillingDetails[key], "Unexpected value for \(key)")
        }
    }

    private func decodeFormFields(from body: String) -> [String: String] {
        var fields: [String: String] = [:]
        for pair in body.split(separator: "&") {
            let parts = pair.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let key = String(parts[0]).removingPercentEncoding ?? String(parts[0])
            let value =
                String(parts[1])
                .replacingOccurrences(of: "+", with: " ")
                .removingPercentEncoding ?? String(parts[1])
            fields[key] = value
        }
        return fields
    }

    private func stubCreateLinkAccountSessionForDeferredIntent() {
        stub(condition:
                isHost("api.stripe.com") &&
                isPath("/v1/connections/link_account_sessions_for_deferred_payment") &&
                isMethodPOST()
        ) { _ in
            let response: [String: Any] = [
                "id": "las_789",
                "livemode": false,
                "client_secret": "las_789_secret_123",
            ]
            return HTTPStubsResponse(jsonObject: response, statusCode: 200, headers: nil)
        }
    }
}
