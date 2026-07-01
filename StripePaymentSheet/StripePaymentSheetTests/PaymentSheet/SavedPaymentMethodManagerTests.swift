//
//  SavedPaymentMethodManagerTests.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/3/24.
//

import Foundation
import OHHTTPStubs
import OHHTTPStubsSwift
import StripeCoreTestUtils
@_spi(STP) @testable import StripePayments
@_spi(STP)@testable import StripePaymentSheet
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

        let sut = SavedPaymentMethodManager(configuration: configuration, elementsSession: ._testCardValue(), intent: ._testValue())
        let updatedPaymentMethod = try await sut.update(paymentMethod: paymentMethod,
                           with: STPPaymentMethodUpdateParams())

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

        let sut = SavedPaymentMethodManager(configuration: configuration, elementsSession: elementsSession, intent: ._testValue())
        let updatedPaymentMethod = try await sut.update(paymentMethod: paymentMethod,
                           with: STPPaymentMethodUpdateParams())

        XCTAssertEqual("pm_123card", updatedPaymentMethod.stripeId)
        await fulfillment(of: [expectation], timeout: 5.0)
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

        let sut = SavedPaymentMethodManager(configuration: configuration, elementsSession: ._testCardValue(), intent: ._testValue())
        let updatedPaymentMethod = try await sut.update(paymentMethod: paymentMethod,
                                                        with: STPPaymentMethodUpdateParams())

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
        let sut = SavedPaymentMethodManager(
            configuration: configuration,
            elementsSession: ._testValue(paymentMethodTypes: ["card"]),
            intent: .checkout(Checkout(session: checkoutSession))
        )

        let card = STPPaymentMethodCardParams()
        card.expMonth = 12
        card.expYear = 2030
        let billing = STPPaymentMethodBillingDetails()
        billing.name = "Jane Doe"
        billing.email = "jane@example.com"
        let updateParams = STPPaymentMethodUpdateParams(card: card, billingDetails: billing)

        let updatedPaymentMethod = try await sut.update(paymentMethod: paymentMethod, with: updateParams)

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
        let sut = SavedPaymentMethodManager(
            configuration: configuration,
            elementsSession: ._testValue(paymentMethodTypes: ["card"]),
            intent: .checkout(Checkout(session: checkoutSession))
        )

        let card = STPPaymentMethodCardParams()
        card.expMonth = 1
        card.expYear = 2040
        let updateParams = STPPaymentMethodUpdateParams(card: card, billingDetails: nil)

        let updatedPaymentMethod = try await sut.update(paymentMethod: paymentMethod, with: updateParams)

        XCTAssertEqual("pm_123card", updatedPaymentMethod.stripeId)
        await fulfillment(of: [expectation], timeout: 5.0)

        let body = try XCTUnwrap(capturedBody.value)
        XCTAssertTrue(body.contains("payment_method_to_update%5Bexpiry_details%5D%5Bexp_month%5D=1"))
        XCTAssertTrue(body.contains("payment_method_to_update%5Bexpiry_details%5D%5Bexp_year%5D=2040"))
        XCTAssertFalse(body.contains("payment_method_to_update%5Bbilling_details%5D"))
    }

    func testUpdatePaymentMethod_checkoutSession_missingBillingAndExpiry_throws() async {
        let checkoutSession = makeCheckoutSession(id: "cs_test_checkout_session")
        let sut = SavedPaymentMethodManager(
            configuration: configuration,
            elementsSession: ._testValue(paymentMethodTypes: ["card"]),
            intent: .checkout(Checkout(session: checkoutSession))
        )

        do {
            _ = try await sut.update(paymentMethod: paymentMethod, with: STPPaymentMethodUpdateParams())
            XCTFail("Expected error")
        } catch {}
    }

    // MARK: Detach tests
    func testDetachPaymentMethod_legacy() {
        var configuration = configuration
        configuration.customer = .init(id: "cus_test123", ephemeralKeySecret: ephemeralKey)

        let expectation = stubDetachPaymentMethod(paymentMethod: STPPaymentMethod.stubbedPaymentMethod(),
                                                  ephemeralKey: ephemeralKey)

        let sut = SavedPaymentMethodManager(configuration: configuration, elementsSession: ._testValue(paymentMethodTypes: ["card"]), intent: ._testValue())
        sut.detach(paymentMethod: paymentMethod)

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

        let sut = SavedPaymentMethodManager(configuration: configuration, elementsSession: elementsSession, intent: ._testValue())
        sut.detach(paymentMethod: paymentMethod)

        wait(for: [listPaymentMethodsExpectation, detachExpectation], timeout: 5.0)
    }

    func testDetachPaymentMethod_checkoutSession() {
        let checkoutSessionId = "cs_test_checkout_session"
        let detachExpectation = stubCheckoutSessionDetachPaymentMethod(
            checkoutSessionId: checkoutSessionId,
            paymentMethodId: paymentMethod.stripeId
        )

        let checkoutSessionJSON: [String: Any] = [
            "session_id": checkoutSessionId,
            "livemode": false,
            "mode": "payment",
            "payment_status": "unpaid",
            "payment_method_types": ["card"],
        ]
        let checkoutSession = STPCheckoutSession.decodedObject(fromAPIResponse: checkoutSessionJSON)!

        let sut = SavedPaymentMethodManager(
            configuration: configuration,
            elementsSession: ._testValue(paymentMethodTypes: ["card"]),
            intent: .checkout(Checkout(session: checkoutSession))
        )
        sut.detach(paymentMethod: paymentMethod)

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

    func makeCheckoutSession(id: String) -> STPCheckoutSession {
        let json: [String: Any] = [
            "session_id": id,
            "livemode": false,
            "mode": "payment",
            "payment_status": "unpaid",
            "payment_method_types": ["card"],
            "elements_session": [
                "session_id": "es_test",
                "payment_method_preference": ["ordered_payment_method_types": ["card"]],
            ],
        ]
        return STPCheckoutSession.decodedObject(fromAPIResponse: json)!
    }

    func stubCheckoutSessionUpdatePaymentMethod(
        checkoutSessionId: String,
        paymentMethodId: String
    ) -> (XCTestExpectation, CapturedBody) {
        let exp = expectation(description: "POST payment_pages/\(checkoutSessionId) updates payment method")
        let captured = CapturedBody()

        let responseJSON: [String: Any] = [
            "session_id": checkoutSessionId,
            "livemode": false,
            "mode": "payment",
            "payment_status": "unpaid",
            "payment_method_types": ["card"],
            "customer": [
                "id": "cus_test123",
                "payment_methods": [STPPaymentMethod.paymentMethodJson],
            ],
        ]

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
                jsonObject: [
                    "session_id": checkoutSessionId,
                    "livemode": false,
                    "mode": "payment",
                    "payment_status": "unpaid",
                    "payment_method_types": ["card"],
                ],
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
