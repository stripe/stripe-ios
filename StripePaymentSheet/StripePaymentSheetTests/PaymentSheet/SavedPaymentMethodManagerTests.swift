//
//  SavedPaymentMethodManagerTests.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/3/24.
//

import Foundation
import OHHTTPStubs
import OHHTTPStubsSwift
@_spi(STP) @testable import StripeCore
import StripeCoreTestUtils
@_spi(STP) @testable import StripePayments
@_spi(STP)@testable import StripePaymentSheet
@_spi(STP) import StripeUICore
import UIKit
import XCTest

@MainActor
final class SavedPaymentMethodManagerTests: XCTestCase {

    let ephemeralKey = "test-eph-key"
    let paymentMethod = STPPaymentMethod.stubbedPaymentMethod()

    var configuration: PaymentSheet.Configuration {
        let apiClient = APIStubbedTestCase.stubbedAPIClient()
        var configuration = PaymentSheet.Configuration()
        configuration.apiClient = apiClient
        return configuration
    }

    // MARK: Update tests
    func testUpdatePaymentMethod_legacy() async throws {
        let paymentMethod = STPPaymentMethod.stubbedPaymentMethod()
        let expectation = stubUpdatePaymentMethod(paymentMethod: paymentMethod,
                                ephemeralKey: ephemeralKey)
        var configuration = configuration
        configuration.customer = .init(id: "cus_test123", ephemeralKeySecret: ephemeralKey)

        let sut = CustomerProvider(customer: configuration.customer)
        let updatedPaymentMethod = try await sut.update(
            paymentMethod: paymentMethod,
            with: STPPaymentMethodUpdateParams(),
            elementsSession: ._testCardValue(),
            apiClient: configuration.apiClient
        )

        XCTAssertEqual("pm_123card", updatedPaymentMethod.stripeId)
        await fulfillment(of: [expectation], timeout: 5.0)
    }

    func testUpdatePaymentMethod_customerSessions() async throws {
        let paymentMethod = STPPaymentMethod.stubbedPaymentMethod()
        let expectation = stubUpdatePaymentMethod(paymentMethod: paymentMethod,
                                ephemeralKey: "ek_12345")
        var configuration = configuration
        configuration.customer = .init(id: "cus_test123", customerSessionClientSecret: "cuss_test")

        let elementsSession: STPElementsSession = ._testValue(paymentMethodTypes: ["card"], customerSessionData: [
            "mobile_payment_element": [
                "enabled": true,
                "features": ["payment_method_save": "enabled",
                             "payment_method_remove": "enabled",
                            ],
            ],
            "customer_sheet": [
                "enabled": false
            ],
        ])

        let sut = CustomerProvider(customer: configuration.customer)
        let updatedPaymentMethod = try await sut.update(
            paymentMethod: paymentMethod,
            with: STPPaymentMethodUpdateParams(),
            elementsSession: elementsSession,
            apiClient: configuration.apiClient
        )

        XCTAssertEqual("pm_123card", updatedPaymentMethod.stripeId)
        await fulfillment(of: [expectation], timeout: 5.0)
    }

    func testEmbeddedPaymentMethodUpdateUsesCurrentCustomerSessionKey() async throws {
        // Given an Embedded element loaded with the previous Customer Session key
        await AddressSpecProvider.shared.loadAddressSpecs()
        var embeddedConfiguration = EmbeddedPaymentElement.Configuration._testValue_MostPermissive(isApplePayEnabled: false)
        embeddedConfiguration.apiClient = configuration.apiClient
        let customerProvider = CustomerProvider(customer: .init(id: "cus_test", customerSessionClientSecret: "cuss_test"))
        func makeLoadResult(apiKey: String) -> PaymentSheetLoader.LoadResult {
            return .init(
                intent: ._testValue(),
                elementsSession: .elementsSessionWithCustomerSessionForPaymentSheet(apiKey: apiKey),
                savedPaymentMethods: [paymentMethod],
                paymentMethodTypes: [.stripe(.card)],
                paymentMethodMessagingPromotionsHelper: nil,
                paymentMethodOrientation: .vertical,
                customerProvider: customerProvider
            )
        }
        let sut = EmbeddedPaymentElement(
            configuration: embeddedConfiguration,
            loadResult: makeLoadResult(apiKey: "ek_previous"),
            analyticsHelper: ._testValue()
        )
        let updateViewController = UpdatePaymentMethodViewController(
            removeSavedPaymentMethodMessage: nil,
            configuration: .init(
                paymentMethod: paymentMethod,
                appearance: embeddedConfiguration.appearance,
                billingDetailsCollectionConfiguration: .init(address: .never),
                hostedSurface: .paymentSheet,
                canRemove: true,
                canUpdate: true,
                isCBCEligible: false
            )
        )
        // Edit through the existing form so the test exercises Embedded's update delegate.
        var views = [updateViewController.view!]
        var expiryField: UITextField?
        while let view = views.popLast() {
            if let textField = view as? UITextField, textField.accessibilityIdentifier == "MM / YY" {
                expiryField = textField
                break
            }
            views.append(contentsOf: view.subviews)
        }
        let field = try XCTUnwrap(expiryField)
        field.text = "1230"
        field.sendActions(for: .editingChanged)
        XCTAssertNotNil(updateViewController.updateParams)

        // When an accepted load refreshes the Customer Session's key
        sut.loadResult = makeLoadResult(apiKey: "ek_refreshed")
        let requestReceived = expectation(description: "Payment method update uses refreshed credentials")
        let paymentMethodID = paymentMethod.stripeId
        let requestStub = stub { request in
            request.url?.absoluteString.contains("/payment_methods/\(paymentMethodID)") == true && request.httpMethod == "POST"
        } response: { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer ek_refreshed")
            requestReceived.fulfill()
            return HTTPStubsResponse(jsonObject: STPPaymentMethod.paymentMethodJson, statusCode: 200, headers: nil)
        }
        defer { HTTPStubs.removeStub(requestStub) }

        // Then the next saved-method operation uses that key
        let result = await sut.didUpdate(viewController: updateViewController, paymentMethod: paymentMethod)
        guard case .success = result else {
            return XCTFail("Expected the saved payment method update to succeed")
        }
        XCTAssertEqual(sut.savedPaymentMethods.first?.stripeId, paymentMethodID)
        await fulfillment(of: [requestReceived], timeout: 5)
    }

    func testUpdatePaymentMethod_preservesLocalLinkFields() async throws {
        let paymentMethod = STPPaymentMethod.stubbedPaymentMethod()
        paymentMethod.linkPaymentDetails = .card(
            LinkPaymentDetails.Card(
                id: "csmrpd_123",
                displayName: "Visa",
                expMonth: 12,
                expYear: 2030,
                last4: "4242",
                brand: .visa
            )
        )
        paymentMethod.isLinkOrigin = true

        let expectation = stubUpdatePaymentMethod(paymentMethod: paymentMethod,
                                                  ephemeralKey: ephemeralKey)
        var configuration = configuration
        configuration.customer = .init(id: "cus_test123", ephemeralKeySecret: ephemeralKey)

        let sut = CustomerProvider(customer: configuration.customer)
        let updatedPaymentMethod = try await sut.update(
            paymentMethod: paymentMethod,
            with: STPPaymentMethodUpdateParams(),
            elementsSession: ._testCardValue(),
            apiClient: configuration.apiClient
        )

        XCTAssertTrue(updatedPaymentMethod.isLinkOrigin)
        XCTAssertEqual(updatedPaymentMethod.linkPaymentDetailsFormattedString, paymentMethod.linkPaymentDetailsFormattedString)
        await fulfillment(of: [expectation], timeout: 5.0)
    }

    func testUpdatePaymentMethod_checkoutSession() async throws {
        let checkoutSessionId = "cs_test_checkout_session"
        let (expectation, capturedBody) = stubCheckoutSessionUpdatePaymentMethod(
            checkoutSessionId: checkoutSessionId,
            paymentMethodId: paymentMethod.stripeId
        )

        let checkoutSession = makeCheckoutSession(id: checkoutSessionId)
        let sut = CustomerProvider(checkoutSession: checkoutSession.makePublicSession())

        let card = STPPaymentMethodCardParams()
        card.expMonth = 12
        card.expYear = 2030
        let billing = STPPaymentMethodBillingDetails()
        billing.name = "Jane Doe"
        billing.email = "jane@example.com"
        let updateParams = STPPaymentMethodUpdateParams(card: card, billingDetails: billing)

        let updatedPaymentMethod = try await sut.update(
            paymentMethod: paymentMethod,
            with: updateParams,
            elementsSession: ._testValue(paymentMethodTypes: ["card"]),
            apiClient: configuration.apiClient
        )

        XCTAssertEqual("pm_123card", updatedPaymentMethod.stripeId)
        await fulfillment(of: [expectation], timeout: 5.0)

        let body = try XCTUnwrap(capturedBody.value)
        XCTAssertTrue(body.contains("payment_method_to_update%5Bpayment_method_id%5D=\(paymentMethod.stripeId)"))
        XCTAssertTrue(body.contains("payment_method_to_update%5Bbilling_details%5D%5Bname%5D=Jane%20Doe"))
        XCTAssertTrue(body.contains("payment_method_to_update%5Bbilling_details%5D%5Bemail%5D=jane%40example.com"))
        XCTAssertTrue(body.contains("payment_method_to_update%5Bexpiry_details%5D%5Bexp_month%5D=12"))
        XCTAssertTrue(body.contains("payment_method_to_update%5Bexpiry_details%5D%5Bexp_year%5D=2030"))
    }

    func testUpdatePaymentMethod_checkoutSession_expiryOnly() async throws {
        let checkoutSessionId = "cs_test_checkout_session"
        let (expectation, capturedBody) = stubCheckoutSessionUpdatePaymentMethod(
            checkoutSessionId: checkoutSessionId,
            paymentMethodId: paymentMethod.stripeId
        )

        let checkoutSession = makeCheckoutSession(id: checkoutSessionId)
        let sut = CustomerProvider(checkoutSession: checkoutSession.makePublicSession())

        let card = STPPaymentMethodCardParams()
        card.expMonth = 1
        card.expYear = 2040
        let updateParams = STPPaymentMethodUpdateParams(card: card, billingDetails: nil)

        let updatedPaymentMethod = try await sut.update(
            paymentMethod: paymentMethod,
            with: updateParams,
            elementsSession: ._testValue(paymentMethodTypes: ["card"]),
            apiClient: configuration.apiClient
        )

        XCTAssertEqual("pm_123card", updatedPaymentMethod.stripeId)
        await fulfillment(of: [expectation], timeout: 5.0)

        let body = try XCTUnwrap(capturedBody.value)
        XCTAssertTrue(body.contains("payment_method_to_update%5Bexpiry_details%5D%5Bexp_month%5D=1"))
        XCTAssertTrue(body.contains("payment_method_to_update%5Bexpiry_details%5D%5Bexp_year%5D=2040"))
        XCTAssertFalse(body.contains("payment_method_to_update%5Bbilling_details%5D"))
    }

    func testUpdatePaymentMethod_checkoutSession_missingBillingAndExpiry_throws() async {
        let checkoutSession = makeCheckoutSession(id: "cs_test_checkout_session")
        let sut = CustomerProvider(checkoutSession: checkoutSession.makePublicSession())

        do {
            _ = try await sut.update(
                paymentMethod: paymentMethod,
                with: STPPaymentMethodUpdateParams(),
                elementsSession: ._testValue(paymentMethodTypes: ["card"]),
                apiClient: configuration.apiClient
            )
            XCTFail("Expected error")
        } catch {}
    }

    func testCheckoutUpdateMissingPaymentMethodPreservesErrorAndAnalytics() async throws {
        // Given a successful Checkout update response that omits the requested payment method
        let checkoutSessionID = "cs_test_missing_updated_method"
        let sut = CustomerProvider(checkoutSession: makeCheckoutSession(id: checkoutSessionID).makePublicSession())
        let requestStub = stub { request in
            request.url?.absoluteString.contains("/payment_pages/\(checkoutSessionID)") == true && request.httpMethod == "POST"
        } response: { _ in
            HTTPStubsResponse(jsonObject: CheckoutTestHelpers.makeSessionJSON([
                "session_id": checkoutSessionID,
                "customer": ["id": "cus_test", "payment_methods": []],
            ]), statusCode: 200, headers: nil)
        }
        defer { HTTPStubs.removeStub(requestStub) }
        let analyticsClient = STPAnalyticsClient.sharedClient
        analyticsClient._testLogHistory = []
        defer { analyticsClient._testLogHistory = [] }
        let card = STPPaymentMethodCardParams()
        card.expMonth = 12
        card.expYear = 2030

        // When the response cannot supply the updated method, preserve the PaymentSheet error.
        STPAssertTestUtil.shouldSuppressNextSTPAlert = true
        do {
            _ = try await sut.update(
                paymentMethod: paymentMethod,
                with: STPPaymentMethodUpdateParams(card: card, billingDetails: nil),
                elementsSession: ._testCardValue(),
                apiClient: configuration.apiClient
            )
            XCTFail("Expected an error when the updated payment method is missing")
        } catch PaymentSheetError.unknown(let description) {
            XCTAssertEqual(description, "Checkout session response didn't include the updated payment method.")
        }

        // Then the diagnostic retains the original analytics identity and the requested method's ID.
        let events = analyticsClient._testLogHistory.filter { $0["event"] as? String == "unexpected_error.paymentsheet" }
        XCTAssertEqual(events.count, 1)
        let event = try XCTUnwrap(events.first)
        XCTAssertEqual(event["error_type"] as? String, "StripePaymentSheet.SavedPaymentMethodManager.Error")
        XCTAssertEqual(event["error_code"] as? String, "missingUpdatedPaymentMethod")
        XCTAssertEqual(event["payment_method_id"] as? String, paymentMethod.stripeId)
    }

    // MARK: Detach tests
    func testDetachPaymentMethod_legacy() {
        var configuration = configuration
        configuration.customer = .init(id: "cus_test123", ephemeralKeySecret: ephemeralKey)

        let expectation = stubDetachPaymentMethod(paymentMethod: STPPaymentMethod.stubbedPaymentMethod(),
                                                  ephemeralKey: ephemeralKey)

        let sut = CustomerProvider(customer: configuration.customer)
        sut.detach(
            paymentMethod: paymentMethod,
            elementsSession: ._testValue(paymentMethodTypes: ["card"]),
            apiClient: configuration.apiClient
        )

        wait(for: [expectation], timeout: 5.0)
    }

    func testDetachPaymentMethod_customerSessions() {
        var configuration = configuration
        configuration.customer = .init(id: "cus_test123", customerSessionClientSecret: "cuss_test")

        let listPaymentMethodsExpectation = stubListPaymentMethods(customerId: configuration.customer!.id,
                                                                   ephemeralKey: "ek_12345")

        let detachExpectation = stubDetachPaymentMethod(paymentMethod: STPPaymentMethod.stubbedPaymentMethod(),
                                                        ephemeralKey: "ek_12345")

        let elementsSession: STPElementsSession = ._testValue(paymentMethodTypes: ["card"],
                                         customerSessionData: [
                                             "mobile_payment_element": [
                                                 "enabled": true,
                                                 "features": ["payment_method_save": "enabled",
                                                              "payment_method_remove": "enabled",
                                                             ],
                                             ],
                                             "customer_sheet": [
                                                 "enabled": false
                                             ],
                                         ])

        let sut = CustomerProvider(customer: configuration.customer)
        sut.detach(
            paymentMethod: paymentMethod,
            elementsSession: elementsSession,
            apiClient: configuration.apiClient
        )

        wait(for: [listPaymentMethodsExpectation, detachExpectation], timeout: 5.0)
    }

    func testDetachPaymentMethod_checkoutSession() {
        let checkoutSessionId = "cs_test_checkout_session"
        let detachExpectation = stubCheckoutSessionDetachPaymentMethod(
            checkoutSessionId: checkoutSessionId,
            paymentMethodId: paymentMethod.stripeId
        )

        let checkoutSession = makeCheckoutSession(id: checkoutSessionId)

        let sut = CustomerProvider(checkoutSession: checkoutSession.makePublicSession())
        sut.detach(
            paymentMethod: paymentMethod,
            elementsSession: ._testValue(paymentMethodTypes: ["card"]),
            apiClient: configuration.apiClient
        )

        wait(for: [detachExpectation], timeout: 5.0)
    }
}

extension SavedPaymentMethodManagerTests {

    // MARK: HTTP Stubs

    func stubRequest(urlContains: String,
                     ephemeralKey: String,
                     httpMethod: String,
                     responseObject: Any) -> XCTestExpectation {
        let exp = expectation(description: "Request \(httpMethod) \(urlContains)")

        stub { urlRequest in
          return urlRequest.url?.absoluteString.contains(urlContains) ?? false
            && urlRequest.allHTTPHeaderFields?["Authorization"] == "Bearer \(ephemeralKey)"
            && urlRequest.httpMethod == httpMethod
        } response: { _ in
            DispatchQueue.main.async {
                exp.fulfill()
            }
            return HTTPStubsResponse(jsonObject: responseObject,
                                     statusCode: 200,
                                     headers: nil)
        }

        return exp
    }

    func stubUpdatePaymentMethod(paymentMethod: STPPaymentMethod, ephemeralKey: String) -> XCTestExpectation {
        return stubRequest(urlContains: "/payment_methods/\(paymentMethod.stripeId)",
                           ephemeralKey: ephemeralKey,
                           httpMethod: "POST",
                           responseObject: STPPaymentMethod.paymentMethodJson)
    }

    func stubDetachPaymentMethod(paymentMethod: STPPaymentMethod, ephemeralKey: String) -> XCTestExpectation {
        return stubRequest(urlContains: "/payment_methods/\(paymentMethod.stripeId)/detach",
                           ephemeralKey: ephemeralKey,
                           httpMethod: "POST",
                           responseObject: [:])
    }

    func stubListPaymentMethods(customerId: String, ephemeralKey: String) -> XCTestExpectation {
        return stubRequest(urlContains: "/payment_methods?customer=\(customerId)&type=card",
                           ephemeralKey: ephemeralKey,
                           httpMethod: "GET",
                           responseObject: STPPaymentMethod.paymentMethodsJson)
    }

    func makeCheckoutSession(id: String) -> PaymentPagesAPIResponse {
        CheckoutTestHelpers.makeSession().withSessionId(id)
    }

    func stubCheckoutSessionUpdatePaymentMethod(
        checkoutSessionId: String,
        paymentMethodId: String
    ) -> (XCTestExpectation, CapturedBody) {
        let exp = expectation(description: "POST payment_pages/\(checkoutSessionId) updates payment method")
        let captured = CapturedBody()

        let responseJSON = CheckoutTestHelpers.makeSessionJSON([
            "session_id": checkoutSessionId,
            "customer": [
                "id": "cus_test123",
                "payment_methods": [STPPaymentMethod.paymentMethodJson],
            ],
        ])

        stub { urlRequest in
            guard urlRequest.url?.absoluteString.contains("/payment_pages/\(checkoutSessionId)") == true,
                  urlRequest.httpMethod == "POST",
                  let body = urlRequest.httpBodyOrBodyStream,
                  let bodyString = String(data: body, encoding: .utf8),
                  bodyString.contains("payment_method_to_update%5Bpayment_method_id%5D=\(paymentMethodId)")
            else {
                return false
            }
            captured.value = bodyString
            return true
        } response: { _ in
            DispatchQueue.main.async {
                exp.fulfill()
            }
            return HTTPStubsResponse(jsonObject: responseJSON, statusCode: 200, headers: nil)
        }

        return (exp, captured)
    }

    func stubCheckoutSessionDetachPaymentMethod(
        checkoutSessionId: String,
        paymentMethodId: String
    ) -> XCTestExpectation {
        let exp = expectation(description: "POST payment_pages/\(checkoutSessionId) detaches payment method")

        stub { urlRequest in
            guard urlRequest.url?.absoluteString.contains("/payment_pages/\(checkoutSessionId)") == true,
                  urlRequest.httpMethod == "POST",
                  let body = urlRequest.httpBodyOrBodyStream,
                  let bodyString = String(data: body, encoding: .utf8)
            else {
                return false
            }

            return bodyString.contains("payment_method_to_detach=\(paymentMethodId)")
        } response: { _ in
            DispatchQueue.main.async {
                exp.fulfill()
            }
            return HTTPStubsResponse(
                jsonObject: CheckoutTestHelpers.makeSessionJSON([
                    "session_id": checkoutSessionId,
                ]),
                statusCode: 200,
                headers: nil
            )
        }

        return exp
    }
}

final class CapturedBody {
    var value: String?
}

extension STPPaymentMethod {

    static var paymentMethodJson: [String: Any] {
        return [
            "id": "pm_123card",
            "created": "12345",
            "type": "card",
            "card": [
                "last4": "4242",
                "brand": "visa",
                "fingerprint": "B8XXs2y2JsVBtB9f",
            ],
        ]
    }

    static var usBankAccountJson: [String: Any] {
        return [
            "id": "pm_123",
            "created": "12345",
            "type": "us_bank_account",
            "us_bank_account": [
                "account_holder_type": "individual",
                "account_type": "checking",
                "bank_name": "STRIPE TEST BANK",
                "fingerprint": "ickfX9sbxIyAlbuh",
                "last4": "6789",
                "networks": [
                  "preferred": "ach",
                  "supported": [
                    "ach",
                  ],
                ] as [String: Any],
                "routing_number": "110000000",
            ] as [String: Any],
        ]
    }

    static var paymentMethodsJson: [String: Any] = [
        "data": [
            [
                "id": "pm_123card",
                "type": "card",
                "created": "12345",
                "card": [
                    "last4": "4242",
                    "brand": "visa",
                ],
            ],
            [
                "id": "pm_123mastercard",
                "type": "card",
                "created": "12345",
                "card": [
                    "last4": "5555",
                    "brand": "mastercard",
                ],
            ],
            [
                "id": "pm_123amex",
                "type": "card",
                "created": "12345",
                "card": [
                    "last4": "6789",
                    "brand": "amex",
                ],
            ],
        ],
    ]

    /// Creates a fake payment method for tests
    static func stubbedPaymentMethod() -> STPPaymentMethod {
        return STPPaymentMethod.decodedObject(fromAPIResponse: paymentMethodJson)!
    }
}
