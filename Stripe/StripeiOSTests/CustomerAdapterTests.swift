//
//  CustomerAdapterTests.swift
//  StripePaymentSheetTests
//

import Foundation
import OHHTTPStubs
import OHHTTPStubsSwift
@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripeCore
@testable import StripeCoreTestUtils
@_spi(STP) @testable import StripePayments
@_spi(STP) @_spi(CustomerSessionBetaAccess) @testable import StripePaymentSheet
@_spi(STP) @testable import StripePaymentsTestUtils
import XCTest

enum MockEphemeralKeyEndpoint {
    case customerEphemeralKey(CustomerEphemeralKey)
    case error(Error)

    init(_ error: Error) {
        self = .error(error)
    }

    init(_ customerEphemeralKey: CustomerEphemeralKey) {
        self = .customerEphemeralKey(customerEphemeralKey)
    }

    func getEphemeralKey() async throws -> CustomerEphemeralKey {
        switch self {
        case .customerEphemeralKey(let key):
            return key
        case .error(let error):
            throw error
        }
    }
}

class CustomerAdapterTests: APIStubbedTestCase {

    func stubListPaymentMethods(
        key: CustomerEphemeralKey,
        paymentMethodType: String,
        paymentMethodJSONs: [[AnyHashable: Any]],
        apiClient: STPAPIClient
    ) {
        stub { urlRequest in
            if urlRequest.url?.absoluteString.contains("/payment_methods") ?? false
                && urlRequest.url?.absoluteString.contains("type=\(paymentMethodType)") ?? false
                && urlRequest.httpMethod == "GET"
            {
                // Check to make sure we pass the ephemeral key correctly
                let keyFromHeader = urlRequest.allHTTPHeaderFields!["Authorization"]?
                    .replacingOccurrences(of: "Bearer ", with: "")
                XCTAssertEqual(keyFromHeader, key.ephemeralKeySecret)
                return true
            }
            return false
        } response: { urlRequest in
            let paymentMethodsJSON = """
                {
                  "object": "list",
                  "url": "/v1/payment_methods",
                  "has_more": false,
                  "data": [
                  ]
                }
                """
            var pmList =
            try! JSONSerialization.jsonObject(
                with: paymentMethodsJSON.data(using: .utf8)!,
                options: []
            ) as! [AnyHashable: Any]
            // Only send the example cards for a card request
            if urlRequest.url?.absoluteString.contains("card") ?? false {
                pmList["data"] = paymentMethodJSONs
            } else if urlRequest.url?.absoluteString.contains("us_bank_account") ?? false {
                pmList["data"] = paymentMethodJSONs
            }
            return HTTPStubsResponse(jsonObject: pmList, statusCode: 200, headers: nil)
        }
    }
    func stubElementsSession(
        paymentMethodJSONs: [[AnyHashable: Any]]?
    ) {
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/v1/elements/sessions") ?? false
        } response: { _ in
            let elementsSessionJSON = """
                {
                  "payment_method_preference": {"ordered_payment_method_types": ["card"],
                                                "country_code": "US"
                                               },
                  "ordered_payment_method_types" : ["card"],
                  "session_id": "123",
                  "apple_pay_preference": "enabled",
                  "customer": {"payment_methods": [
                               ],
                               "customer_session": {
                                  "id": "cuss_654321",
                                  "livemode": false,
                                  "api_key": "ek_12345",
                                  "api_key_expiry": 1899787184,
                                  "customer": "cus_12345"
                                }
                              }
                }
                """
            var elementSession = try! JSONSerialization.jsonObject(
                with: elementsSessionJSON.data(using: .utf8)!,
                options: []
            ) as! [AnyHashable: Any]
            if var customer = elementSession["customer"] as? [AnyHashable: Any],
               paymentMethodJSONs != nil {
                customer["payment_methods"] = paymentMethodJSONs
                elementSession["customer"] = customer
            }
            return HTTPStubsResponse(jsonObject: elementSession, statusCode: 200, headers: nil)
        }
    }

    func testGetOrCreateKeyErrorForwardedToFetchPMs() async throws {
        let exp = expectation(description: "fetchPMs")
        let expectedError = NSError(domain: "test", code: 123, userInfo: nil)
        let apiClient = stubbedAPIClient()
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/payment_methods") ?? false
        } response: { _ in
            XCTFail("Retrieve PMs should not be called")
            return HTTPStubsResponse(error: NSError(domain: "test", code: 100, userInfo: nil))
        }
        let ekm = MockEphemeralKeyEndpoint(expectedError)
        let sut = StripeCustomerAdapter(customerEphemeralKeyProvider: ekm.getEphemeralKey, apiClient: apiClient)
        do {
            _ = try await sut.fetchPaymentMethods()
        } catch {
            XCTAssertEqual((error as NSError?)?.domain, expectedError.domain)
            exp.fulfill()
        }
        await fulfillment(of: [exp])
    }

    let exampleKey = CustomerEphemeralKey(customerId: "abc123", ephemeralKeySecret: "ek_123")

    func testFetchPMs() async throws {
        let expectedPaymentMethods = [STPFixtures.paymentMethod()]
        let expectedPaymentMethodsJSON = [STPFixtures.paymentMethodJSON()]
        let apiClient = stubbedAPIClient()
        // Expect 1 call per PM: cards
        stubListPaymentMethods(key: exampleKey, paymentMethodType: "card", paymentMethodJSONs: expectedPaymentMethodsJSON, apiClient: apiClient)
        stubListPaymentMethods(key: exampleKey, paymentMethodType: "us_bank_account", paymentMethodJSONs: [], apiClient: apiClient)
        stubListPaymentMethods(key: exampleKey, paymentMethodType: "sepa_debit", paymentMethodJSONs: [], apiClient: apiClient)

        let ekm = MockEphemeralKeyEndpoint(exampleKey)
        let sut = StripeCustomerAdapter(customerEphemeralKeyProvider: ekm.getEphemeralKey, apiClient: apiClient)
        let pms = try await sut.fetchPaymentMethods()

        XCTAssertEqual(pms.count, 1)
        XCTAssertEqual(pms[0].stripeId, expectedPaymentMethods[0].stripeId)
    }

    func testFetchPM_CardAndUSBankAccount() async throws {
        let expectedPaymentMethods_card = [STPFixtures.paymentMethod()]
        let expectedPaymentMethods_cardJSON = [STPFixtures.paymentMethodJSON()]

        let expectedPaymentMethods_usbank = [STPFixtures.bankAccountPaymentMethod()]
        let expectedPaymentMethods_usbankJSON = [STPFixtures.bankAccountPaymentMethodJSON()]

        let apiClient = stubbedAPIClient()
        stubListPaymentMethods(key: exampleKey, paymentMethodType: "card", paymentMethodJSONs: expectedPaymentMethods_cardJSON, apiClient: apiClient)
        stubListPaymentMethods(key: exampleKey, paymentMethodType: "us_bank_account", paymentMethodJSONs: expectedPaymentMethods_usbankJSON, apiClient: apiClient)
        stubListPaymentMethods(key: exampleKey, paymentMethodType: "sepa_debit", paymentMethodJSONs: [], apiClient: apiClient)

        let ekm = MockEphemeralKeyEndpoint(exampleKey)
        let sut = StripeCustomerAdapter(customerEphemeralKeyProvider: ekm.getEphemeralKey,
                                        setupIntentClientSecretProvider: { return "si_" },
                                        apiClient: apiClient)
        let pms = try await sut.fetchPaymentMethods()
        XCTAssertEqual(pms.count, 2)
        XCTAssertEqual(pms[0].stripeId, expectedPaymentMethods_card[0].stripeId)
        XCTAssertEqual(pms[1].stripeId, expectedPaymentMethods_usbank[0].stripeId)
    }

    func testAttachPM() async throws {
        let expectedPaymentMethods = [STPFixtures.paymentMethod()]
        let expectedPaymentMethodsJSON = [STPFixtures.paymentMethodJSON()]
        let apiClient = stubbedAPIClient()
        // Expect 1 call per PM: cards
        stubListPaymentMethods(key: exampleKey, paymentMethodType: "card", paymentMethodJSONs: expectedPaymentMethodsJSON, apiClient: apiClient)
        stubListPaymentMethods(key: exampleKey, paymentMethodType: "sepa_debit", paymentMethodJSONs: [], apiClient: apiClient)
        stubListPaymentMethods(key: exampleKey, paymentMethodType: "us_bank_account", paymentMethodJSONs: [], apiClient: apiClient)

        let ekm = MockEphemeralKeyEndpoint(exampleKey)
        let sut = StripeCustomerAdapter(customerEphemeralKeyProvider: ekm.getEphemeralKey, apiClient: apiClient)
        let pms = try await sut.fetchPaymentMethods()

        XCTAssertEqual(pms.count, 1)
        XCTAssertEqual(pms[0].stripeId, expectedPaymentMethods[0].stripeId)
    }

    func testAttachPaymentMethodCallsAPIClientCorrectly() async {
        let apiClient = stubbedAPIClient()
        let expectedPaymentMethodJSON = STPFixtures.paymentMethodJSON()
        let expectedPaymentMethods = [STPFixtures.paymentMethod()]

        let exp = expectation(description: "payment method attach")
        // We're attaching 1 payment method:
        exp.expectedFulfillmentCount = 1
        stub { urlRequest in
            if urlRequest.url?.absoluteString.contains("/payment_method") ?? false
                && urlRequest.httpMethod == "POST"
            {
                return true
            }
            return false
        } response: { _ in
            exp.fulfill()
            return HTTPStubsResponse(
                jsonObject: expectedPaymentMethodJSON,
                statusCode: 200,
                headers: nil
            )
        }

        let ekm = MockEphemeralKeyEndpoint(exampleKey)
        let sut = StripeCustomerAdapter(customerEphemeralKeyProvider: ekm.getEphemeralKey, apiClient: apiClient)
        try! await sut.attachPaymentMethod(expectedPaymentMethods.first!.stripeId)
        await fulfillment(of: [exp])
    }

    func testDetachPaymentMethodCallsAPIClientCorrectly() async {
        let apiClient = stubbedAPIClient()
        let expectedPaymentMethodJSON = STPFixtures.paymentMethodJSON()
        let expectedPaymentMethods = [STPFixtures.paymentMethod()]

        let exp = expectation(description: "payment method detach")
        // We're detaching 1 payment method:
        exp.expectedFulfillmentCount = 1
        stub { urlRequest in
            if urlRequest.url?.absoluteString.contains("/payment_method") ?? false
                && urlRequest.httpMethod == "POST"
            {
                return true
            }
            return false
        } response: { _ in
            exp.fulfill()
            return HTTPStubsResponse(
                jsonObject: expectedPaymentMethodJSON,
                statusCode: 200,
                headers: nil
            )
        }

        let ekm = MockEphemeralKeyEndpoint(exampleKey)
        let sut = StripeCustomerAdapter(customerEphemeralKeyProvider: ekm.getEphemeralKey, apiClient: apiClient)
        try! await sut.detachPaymentMethod(paymentMethodId: expectedPaymentMethods.first!.stripeId)
        await fulfillment(of: [exp])
    }

    func testCustomerSheetLoadFiltersSavedApplePayCards() async throws {
        let apiClient = stubbedAPIClient()
        // Given a Customer with a saved card...
        var savedCardJSON = STPFixtures.paymentMethodJSON()
        savedCardJSON["id"] = "pm_saved_card"
        // ...and a saved card that came from Apple Pay...
        var savedApplePayCardJSON = STPFixtures.paymentMethodJSON()
        savedApplePayCardJSON[jsonDict: "card"]?[jsonDict: "wallet"] = ["type": "apple_pay"]
        savedApplePayCardJSON["id"] = "pm_saved_apple_pay_card"

        // ...fetching the customer's payment methods...
        stubListPaymentMethods(key: exampleKey, paymentMethodType: "card", paymentMethodJSONs: [savedCardJSON, savedApplePayCardJSON], apiClient: apiClient)
        stubListPaymentMethods(key: exampleKey, paymentMethodType: "sepa_debit", paymentMethodJSONs: [], apiClient: apiClient)
        stubListPaymentMethods(key: exampleKey, paymentMethodType: "us_bank_account", paymentMethodJSONs: [], apiClient: apiClient)

        let ekm = MockEphemeralKeyEndpoint(exampleKey)
        let sut = StripeCustomerAdapter(customerEphemeralKeyProvider: ekm.getEphemeralKey, apiClient: apiClient)
        let pms = try await sut.fetchPaymentMethods()

        // ...should return the saved card but not the Apple Pay saved card
        XCTAssertEqual(pms.count, 1)
        XCTAssertEqual(pms[0].stripeId, "pm_saved_card")
    }

    func configuration() -> CustomerSheet.Configuration {
        return CustomerSheet.Configuration()
    }
}
