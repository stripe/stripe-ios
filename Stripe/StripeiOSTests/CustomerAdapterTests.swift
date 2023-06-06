//
//  CustomerAdapterTests.swift
//  StripePaymentSheetTests
//

import Foundation
import OHHTTPStubs
import OHHTTPStubsSwift
@_spi(STP) @testable import StripeCore
import StripeCoreTestUtils
@_spi(STP) @_spi(PrivateBetaCustomerSheet) @testable import StripePayments
@_spi(STP) @_spi(PrivateBetaCustomerSheet) @testable import StripePaymentSheet
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
        paymentMethodJSONs: [[AnyHashable: Any]],
        expectedCount: Int,
        apiClient: STPAPIClient
    ) {
        let exp = expectation(description: "listPaymentMethod")
        exp.expectedFulfillmentCount = expectedCount
        stub { urlRequest in
            if urlRequest.url?.absoluteString.contains("/payment_methods") ?? false
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
            }
            DispatchQueue.main.async {
                // Fulfill after response is sent
                exp.fulfill()
            }
            return HTTPStubsResponse(jsonObject: pmList, statusCode: 200, headers: nil)
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
        await waitForExpectations(timeout: 2)
    }

    let exampleKey = CustomerEphemeralKey(customerId: "abc123", ephemeralKeySecret: "ek_123")

    func testFetchPMs() async throws {
        let expectedPaymentMethods = [STPFixtures.paymentMethod()]
        let expectedPaymentMethodsJSON = [STPFixtures.paymentMethodJSON()]
        let apiClient = stubbedAPIClient()
        // Expect 1 call per PM: cards
        stubListPaymentMethods(key: exampleKey, paymentMethodJSONs: expectedPaymentMethodsJSON, expectedCount: 1, apiClient: apiClient)
        let ekm = MockEphemeralKeyEndpoint(exampleKey)
        let sut = StripeCustomerAdapter(customerEphemeralKeyProvider: ekm.getEphemeralKey, apiClient: apiClient)
        let pms = try await sut.fetchPaymentMethods()

        XCTAssertEqual(pms.count, 1)
        XCTAssertEqual(pms[0].stripeId, expectedPaymentMethods[0].stripeId)
        await waitForExpectations(timeout: 2)
    }

    func testAttachPM() async throws {
        let expectedPaymentMethods = [STPFixtures.paymentMethod()]
        let expectedPaymentMethodsJSON = [STPFixtures.paymentMethodJSON()]
        let apiClient = stubbedAPIClient()
        // Expect 1 call per PM: cards
        stubListPaymentMethods(key: exampleKey, paymentMethodJSONs: expectedPaymentMethodsJSON, expectedCount: 1, apiClient: apiClient)
        let ekm = MockEphemeralKeyEndpoint(exampleKey)
        let sut = StripeCustomerAdapter(customerEphemeralKeyProvider: ekm.getEphemeralKey, apiClient: apiClient)
        let pms = try await sut.fetchPaymentMethods()

        XCTAssertEqual(pms.count, 1)
        XCTAssertEqual(pms[0].stripeId, expectedPaymentMethods[0].stripeId)

        await waitForExpectations(timeout: 2)
    }

    func testAttachPaymentMethodCallsAPIClientCorrectly() async {
        let customerKey = STPFixtures.ephemeralKey()
        let expectedCustomerJSON = STPFixtures.customerWithSingleCardTokenSourceJSON()
        let apiClient = stubbedAPIClient()
        let expectedPaymentMethod = STPFixtures.paymentMethod()
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

        await waitForExpectations(timeout: 2, handler: nil)
    }

    func testDetachPaymentMethodCallsAPIClientCorrectly() async {
        let customerKey = STPFixtures.ephemeralKey()
        let expectedCustomerJSON = STPFixtures.customerWithSingleCardTokenSourceJSON()
        let apiClient = stubbedAPIClient()
        let expectedPaymentMethod = STPFixtures.paymentMethod()
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

        await waitForExpectations(timeout: 2, handler: nil)
    }

}
