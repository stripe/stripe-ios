//
//  STPCustomerContextTest.swift
//  StripeiOS Tests
//
//  Created by David Estes on 9/20/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import StripeCoreTestUtils
@testable import Stripe
import OHHTTPStubs

class MockEphemeralKeyManager: STPEphemeralKeyManagerProtocol {
    var ephemeralKey: STPEphemeralKey?
    var error: Error?
    
    init(key: STPEphemeralKey?, error: Error?) {
        self.ephemeralKey = key
        self.error = error
    }
    
    func getOrCreateKey(_ completion: @escaping STPEphemeralKeyCompletionBlock) {
        completion(ephemeralKey, error)
    }
}

class STPCustomerContextTests: APIStubbedTestCase {
    func stubRetrieveCustomers(key: STPEphemeralKey,
                               returningCustomerJSON: [AnyHashable: Any],
                               expectedCount: Int,
                               apiClient: STPAPIClient) {
        let exp = expectation(description: "retrieveCustomer")
        exp.expectedFulfillmentCount = expectedCount
        
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/customers") ?? false && urlRequest.httpMethod == "GET"
        } response: { urlRequest in
            DispatchQueue.main.async {
                // Fulfill after response is sent
                exp.fulfill()
            }
            return HTTPStubsResponse(jsonObject: returningCustomerJSON, statusCode: 200, headers: nil)
        }
    }
    
    func stubListPaymentMethods(key: STPEphemeralKey,
                                paymentMethodJSONs: [[AnyHashable: Any]],
                               expectedCount: Int,
                               apiClient: STPAPIClient) {
        let exp = expectation(description: "listPaymentMethod")
        exp.expectedFulfillmentCount = expectedCount
        stub { urlRequest in
            if urlRequest.url?.absoluteString.contains("/payment_methods") ?? false && urlRequest.httpMethod == "GET" {
                // Check to make sure we pass the ephemeral key correctly
                let keyFromHeader = urlRequest.allHTTPHeaderFields!["Authorization"]?.replacingOccurrences(of: "Bearer ", with: "")
                XCTAssertEqual(keyFromHeader, key.secret)
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
            var pmList = try! JSONSerialization.jsonObject(with: paymentMethodsJSON.data(using: .utf8)!, options: []) as! [AnyHashable: Any]
            pmList["data"] = paymentMethodJSONs
            DispatchQueue.main.async {
                // Fulfill after response is sent
                exp.fulfill()
            }
            return HTTPStubsResponse(jsonObject: pmList, statusCode: 200, headers: nil)
        }
    }
    
    func testGetOrCreateKeyErrorForwardedToRetrieveCustomer() {
        let exp = expectation(description: "retrieveCustomer")
        let expectedError = NSError(domain: "test", code: 123, userInfo: nil)
        let apiClient = stubbedAPIClient()
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/customers") ?? false
        } response: { urlRequest in
            XCTFail("Retrieve customer should not be called")
            return HTTPStubsResponse(error: NSError(domain: "test", code: 100, userInfo: nil))
        }
        let ekm = MockEphemeralKeyManager(key: nil, error: expectedError)
        let sut = STPCustomerContext(keyManager: ekm, apiClient: apiClient)
        sut.retrieveCustomer { customer, error in
            XCTAssertNil(customer)
            XCTAssertEqual((error as NSError?)?.domain, expectedError.domain)
            exp.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testInitRetrievesResourceKeyAndCustomerAndPaymentMethods() {
        let customerKey = STPFixtures.ephemeralKey()
        let expectedCustomerJSON = STPFixtures.customerWithSingleCardTokenSourceJSON()
        let apiClient = stubbedAPIClient()
        stubRetrieveCustomers(key: customerKey, returningCustomerJSON: expectedCustomerJSON, expectedCount: 1, apiClient: apiClient)
        stubListPaymentMethods(key: customerKey, paymentMethodJSONs: [], expectedCount: 1, apiClient: apiClient)

        let ekm = MockEphemeralKeyManager(key: customerKey, error: nil)
        let sut = STPCustomerContext(keyManager: ekm, apiClient: apiClient)
        XCTAssertNotNil(sut)
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testRetrieveCustomerUsesCachedCustomerIfNotExpired() {
        let customerKey = STPFixtures.ephemeralKey()
        let expectedCustomer = STPFixtures.customerWithSingleCardTokenSource()
        let expectedCustomerJSON = STPFixtures.customerWithSingleCardTokenSourceJSON()
        let apiClient = stubbedAPIClient()
        
        // apiClient.retrieveCustomer should be called once, when the context is initialized.
        // When sut.retrieveCustomer is called below, the cached customer will be used.
        stubRetrieveCustomers(key: customerKey, returningCustomerJSON: expectedCustomerJSON, expectedCount: 1, apiClient: apiClient)
        stubListPaymentMethods(key: customerKey, paymentMethodJSONs: [], expectedCount: 1, apiClient: apiClient)
        let ekm = MockEphemeralKeyManager(key: customerKey, error: nil)
        let sut = STPCustomerContext(keyManager: ekm, apiClient: apiClient)
        // Give the mocked API request a little time to complete and cache the customer, then check cache
        waitForExpectations(timeout: 2, handler: nil)
        let exp2 = expectation(description: "retrieveCustomer again")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + ohhttpDelay) {
            sut.retrieveCustomer { customer, error in
                XCTAssertEqual(customer!.stripeID, expectedCustomer.stripeID)
                exp2.fulfill()
            }
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testRetrieveCustomerDoesNotUseCachedCustomerIfExpired() {
        let customerKey = STPFixtures.ephemeralKey()
        let expectedCustomer = STPFixtures.customerWithSingleCardTokenSource()
        let expectedCustomerJSON = STPFixtures.customerWithSingleCardTokenSourceJSON()
        let apiClient = stubbedAPIClient()
        
        // apiClient.retrieveCustomer should be called twice:
        // - when the context is initialized,
        // - when sut.retrieveCustomer is called below, as the cached customer has expired.
        stubRetrieveCustomers(key: customerKey, returningCustomerJSON: expectedCustomerJSON, expectedCount: 2, apiClient: apiClient)
        stubListPaymentMethods(key: customerKey, paymentMethodJSONs: [], expectedCount: 1, apiClient: apiClient)

        let ekm = MockEphemeralKeyManager(key: customerKey, error: nil)
        let sut = STPCustomerContext(keyManager: ekm, apiClient: apiClient)
        // Give the mocked API request a little time to complete and cache the customer, then reset and check cache
        let exp2 = expectation(description: "retrieveCustomer again")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + ohhttpDelay) {
            sut.customerRetrievedDate = Date(timeIntervalSinceNow: -70)
            sut.retrieveCustomer { customer, error in
                XCTAssertEqual(customer!.stripeID, expectedCustomer.stripeID)
                exp2.fulfill()
            }
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testRetrieveCustomerDoesNotUseCachedCustomerAfterClearingCache() {
        let customerKey = STPFixtures.ephemeralKey()
        let expectedCustomer = STPFixtures.customerWithSingleCardTokenSource()
        let expectedCustomerJSON = STPFixtures.customerWithSingleCardTokenSourceJSON()
        let apiClient = stubbedAPIClient()
        
        // apiClient.retrieveCustomer should be called twice:
        // - when the context is initialized,
        // - when sut.retrieveCustomer is called below, as the cached customer has been cleared.
        stubRetrieveCustomers(key: customerKey, returningCustomerJSON: expectedCustomerJSON, expectedCount: 2, apiClient: apiClient)
        stubListPaymentMethods(key: customerKey, paymentMethodJSONs: [], expectedCount: 1, apiClient: apiClient)

        let ekm = MockEphemeralKeyManager(key: customerKey, error: nil)
        let sut = STPCustomerContext(keyManager: ekm, apiClient: apiClient)
        // Give the mocked API request a little time to complete and cache the customer, then reset and check cache
        let exp2 = expectation(description: "retrieveCustomer again")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + ohhttpDelay) {
            sut.clearCache()
            sut.retrieveCustomer { customer, error in
                XCTAssertEqual(customer!.stripeID, expectedCustomer.stripeID)
                exp2.fulfill()
            }
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testRetrievePaymentMethodsUsesCacheIfNotExpired() {
        let customerKey = STPFixtures.ephemeralKey()
        let expectedCustomerJSON = STPFixtures.customerWithSingleCardTokenSourceJSON()
        let expectedPaymentMethods = [STPFixtures.paymentMethod()]
        let expectedPaymentMethodsJSON = [STPFixtures.paymentMethodJSON()]
        let apiClient = stubbedAPIClient()
        
        // apiClient.listPaymentMethods should be called once, when the context is initialized.
        // When sut.listPaymentMethods is called below, the cached list will be used.
        stubRetrieveCustomers(key: customerKey, returningCustomerJSON: expectedCustomerJSON, expectedCount: 1, apiClient: apiClient)
        stubListPaymentMethods(key: customerKey, paymentMethodJSONs: expectedPaymentMethodsJSON, expectedCount: 1, apiClient: apiClient)

        let ekm = MockEphemeralKeyManager(key: customerKey, error: nil)
        let sut = STPCustomerContext(keyManager: ekm, apiClient: apiClient)
        // Give the mocked API request a little time to complete and cache the customer, then check cache
        let exp2 = expectation(description: "listPaymentMethods")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + ohhttpDelay) {
            sut.listPaymentMethodsForCustomer { paymentMethods, error in
                XCTAssertEqual(paymentMethods!.count, expectedPaymentMethods.count)
                exp2.fulfill()
            }
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testRetrievePaymentMethodsDoesNotUseCacheIfExpired() {
        let customerKey = STPFixtures.ephemeralKey()
        let expectedCustomerJSON = STPFixtures.customerWithSingleCardTokenSourceJSON()
        let expectedPaymentMethods = [STPFixtures.paymentMethod()]
        let expectedPaymentMethodsJSON = [STPFixtures.paymentMethodJSON()]
        let apiClient = stubbedAPIClient()
        
        // apiClient.listPaymentMethods should be called twice:
        // - when the context is initialized,
        // - when sut.listPaymentMethods is called below, as the cached list has expired.
        stubRetrieveCustomers(key: customerKey, returningCustomerJSON: expectedCustomerJSON, expectedCount: 1, apiClient: apiClient)
        stubListPaymentMethods(key: customerKey, paymentMethodJSONs: expectedPaymentMethodsJSON, expectedCount: 2, apiClient: apiClient)

        let ekm = MockEphemeralKeyManager(key: customerKey, error: nil)
        let sut = STPCustomerContext(keyManager: ekm, apiClient: apiClient)
        // Give the mocked API request a little time to complete and cache the customer, then check cache
        let exp2 = expectation(description: "listPaymentMethods")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + ohhttpDelay) {
            sut.paymentMethodsRetrievedDate = Date(timeIntervalSinceNow: -70)
            sut.listPaymentMethodsForCustomer { paymentMethods, error in
                XCTAssertEqual(paymentMethods!.count, expectedPaymentMethods.count)
                exp2.fulfill()
            }
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testRetrievePaymentMethodsDoesNotUseCacheAfterClearingCache() {
        let customerKey = STPFixtures.ephemeralKey()
        let expectedCustomerJSON = STPFixtures.customerWithSingleCardTokenSourceJSON()
        let expectedPaymentMethods = [STPFixtures.paymentMethod()]
        let expectedPaymentMethodsJSON = [STPFixtures.paymentMethodJSON()]
        let apiClient = stubbedAPIClient()
        
        // apiClient.listPaymentMethods should be called twice:
        // - when the context is initialized,
        // - when sut.listPaymentMethods is called below, as the cached list has been cleared
        stubRetrieveCustomers(key: customerKey, returningCustomerJSON: expectedCustomerJSON, expectedCount: 1, apiClient: apiClient)
        stubListPaymentMethods(key: customerKey, paymentMethodJSONs: expectedPaymentMethodsJSON, expectedCount: 2, apiClient: apiClient)

        let ekm = MockEphemeralKeyManager(key: customerKey, error: nil)
        let sut = STPCustomerContext(keyManager: ekm, apiClient: apiClient)
        // Give the mocked API request a little time to complete and cache the customer, then check cache
        let exp2 = expectation(description: "listPaymentMethods")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + ohhttpDelay) {
            sut.clearCache()
            sut.listPaymentMethodsForCustomer { paymentMethods, error in
                XCTAssertEqual(paymentMethods!.count, expectedPaymentMethods.count)
                exp2.fulfill()
            }
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testSetCustomerShippingCallsAPIClientCorrectly() {
        let address = STPFixtures.address()
        let customerKey = STPFixtures.ephemeralKey()
        let expectedCustomerJSON = STPFixtures.customerWithSingleCardTokenSourceJSON()
        let apiClient = stubbedAPIClient()
        
        stubRetrieveCustomers(key: customerKey, returningCustomerJSON: expectedCustomerJSON, expectedCount: 1, apiClient: apiClient)
        stubListPaymentMethods(key: customerKey, paymentMethodJSONs: [], expectedCount: 1, apiClient: apiClient)
        
        let exp = expectation(description: "updateCustomer")
        stub { urlRequest in
            if urlRequest.url?.absoluteString.contains("/customers") ?? false && urlRequest.httpMethod == "POST" {
                let state = urlRequest.queryItems?.first(where: { item in
                    item.name == "shipping[address][state]"
                })!
                XCTAssertEqual(state?.value, address.state)
                return true
            }
            return false
        } response: { urlRequest in
            exp.fulfill()
            return HTTPStubsResponse(jsonObject: expectedCustomerJSON, statusCode: 200, headers: nil)
        }
        
        let ekm = MockEphemeralKeyManager(key: customerKey, error: nil)
        let sut = STPCustomerContext(keyManager: ekm, apiClient: apiClient)
        let exp2 = expectation(description: "updateCustomerWithShipping")
        sut.updateCustomer(withShippingAddress: address) { error in
            XCTAssertNil(error)
            exp2.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testAttachPaymentMethodCallsAPIClientCorrectly() {
        let customerKey = STPFixtures.ephemeralKey()
        let expectedCustomerJSON = STPFixtures.customerWithSingleCardTokenSourceJSON()
        let apiClient = stubbedAPIClient()
        let expectedPaymentMethod = STPFixtures.paymentMethod()
        let expectedPaymentMethodJSON = STPFixtures.paymentMethodJSON()
        let expectedPaymentMethods = [STPFixtures.paymentMethod()]

        stubRetrieveCustomers(key: customerKey, returningCustomerJSON: expectedCustomerJSON, expectedCount: 1, apiClient: apiClient)
        stubListPaymentMethods(key: customerKey, paymentMethodJSONs: [], expectedCount: 1, apiClient: apiClient)

        let exp = expectation(description: "payment method attach")
        // We're attaching 2 payment methods:
        exp.expectedFulfillmentCount = 2
        stub { urlRequest in
            if urlRequest.url?.absoluteString.contains("/payment_method") ?? false && urlRequest.httpMethod == "POST" {
                return true
            }
            return false
        } response: { urlRequest in
            exp.fulfill()
            return HTTPStubsResponse(jsonObject: expectedPaymentMethodJSON, statusCode: 200, headers: nil)
        }
        
        let ekm = MockEphemeralKeyManager(key: customerKey, error: nil)
        let sut = STPCustomerContext(keyManager: ekm, apiClient: apiClient)
        let exp2 = expectation(description: "CustomerContext attachPaymentMethod")
        sut.attachPaymentMethod(toCustomer: expectedPaymentMethods.first!) { error in
            XCTAssertNil(error)
            exp2.fulfill()
        }
        
        let exp3 = expectation(description: "CustomerContext attachPaymentMethod with ID")
        sut.attachPaymentMethodToCustomer(paymentMethodId: expectedPaymentMethod.stripeId) { error in
            XCTAssertNil(error)
            exp3.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testDetachPaymentMethodCallsAPIClientCorrectly() {
        let customerKey = STPFixtures.ephemeralKey()
        let expectedCustomerJSON = STPFixtures.customerWithSingleCardTokenSourceJSON()
        let apiClient = stubbedAPIClient()
        let expectedPaymentMethod = STPFixtures.paymentMethod()
        let expectedPaymentMethodJSON = STPFixtures.paymentMethodJSON()
        let expectedPaymentMethods = [STPFixtures.paymentMethod()]

        stubRetrieveCustomers(key: customerKey, returningCustomerJSON: expectedCustomerJSON, expectedCount: 1, apiClient: apiClient)
        stubListPaymentMethods(key: customerKey, paymentMethodJSONs: [], expectedCount: 1, apiClient: apiClient)

        let exp = expectation(description: "payment method detach")
        // We're detaching 2 payment methods:
        exp.expectedFulfillmentCount = 2
        stub { urlRequest in
            if urlRequest.url?.absoluteString.contains("/payment_method") ?? false && urlRequest.httpMethod == "POST" {
                return true
            }
            return false
        } response: { urlRequest in
            exp.fulfill()
            return HTTPStubsResponse(jsonObject: expectedPaymentMethodJSON, statusCode: 200, headers: nil)
        }
        
        let ekm = MockEphemeralKeyManager(key: customerKey, error: nil)
        let sut = STPCustomerContext(keyManager: ekm, apiClient: apiClient)
        let exp2 = expectation(description: "CustomerContext detachPaymentMethod")
        sut.detachPaymentMethod(fromCustomer: expectedPaymentMethods.first!) { error in
            XCTAssertNil(error)
            exp2.fulfill()
        }
        
        let exp3 = expectation(description: "CustomerContext detachPaymentMethod with ID")
        sut.detachPaymentMethodFromCustomer(paymentMethodId: expectedPaymentMethod.stripeId) { error in
            XCTAssertNil(error)
            exp3.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testFiltersApplePayPaymentMethodsByDefault() {
        let customerKey = STPFixtures.ephemeralKey()
        let expectedCustomerJSON = STPFixtures.customerWithSingleCardTokenSourceJSON()
        let expectedPaymentMethodsJSON = [STPFixtures.paymentMethodJSON(), STPFixtures.applePayPaymentMethodJSON()]
        let apiClient = stubbedAPIClient()
        
        stubRetrieveCustomers(key: customerKey, returningCustomerJSON: expectedCustomerJSON, expectedCount: 1, apiClient: apiClient)
        stubListPaymentMethods(key: customerKey, paymentMethodJSONs: expectedPaymentMethodsJSON, expectedCount: 1, apiClient: apiClient)

        let ekm = MockEphemeralKeyManager(key: customerKey, error: nil)
        let sut = STPCustomerContext(keyManager: ekm, apiClient: apiClient)
        // Give the mocked API request a little time to complete and cache the customer, then check cache
        let exp2 = expectation(description: "listPaymentMethods")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + ohhttpDelay) {
            sut.listPaymentMethodsForCustomer { paymentMethods, error in
                // Apple Pay should be filtered out
                XCTAssertEqual(paymentMethods!.count, 1)
                exp2.fulfill()
            }
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testIncludesApplePayPaymentMethods() {
        let customerKey = STPFixtures.ephemeralKey()
        let expectedCustomerJSON = STPFixtures.customerWithSingleCardTokenSourceJSON()
        let expectedPaymentMethodsJSON = [STPFixtures.paymentMethodJSON(), STPFixtures.applePayPaymentMethodJSON()]
        let apiClient = stubbedAPIClient()
        
        stubRetrieveCustomers(key: customerKey, returningCustomerJSON: expectedCustomerJSON, expectedCount: 1, apiClient: apiClient)
        stubListPaymentMethods(key: customerKey, paymentMethodJSONs: expectedPaymentMethodsJSON, expectedCount: 1, apiClient: apiClient)

        let ekm = MockEphemeralKeyManager(key: customerKey, error: nil)
        let sut = STPCustomerContext(keyManager: ekm, apiClient: apiClient)
        sut.includeApplePayPaymentMethods = true
        // Give the mocked API request a little time to complete and cache the customer, then check cache
        let exp2 = expectation(description: "listPaymentMethods")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + ohhttpDelay) {
            sut.listPaymentMethodsForCustomer { paymentMethods, error in
                // Apple Pay should be included
                XCTAssertEqual(paymentMethods!.count, 2)
                exp2.fulfill()
            }
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testFiltersApplePaySourcesByDefault() {
        let customerKey = STPFixtures.ephemeralKey()
        let expectedCustomerJSON = STPFixtures.customerWithCardAndApplePaySourcesJSON()
        let expectedPaymentMethods = [STPFixtures.paymentMethod(), STPFixtures.applePayPaymentMethod()]
        let expectedPaymentMethodsJSON = [STPFixtures.paymentMethodJSON(), STPFixtures.applePayPaymentMethodJSON()]
        let apiClient = stubbedAPIClient()
        
        stubRetrieveCustomers(key: customerKey, returningCustomerJSON: expectedCustomerJSON, expectedCount: 1, apiClient: apiClient)
        stubListPaymentMethods(key: customerKey, paymentMethodJSONs: expectedPaymentMethodsJSON, expectedCount: 1, apiClient: apiClient)

        let ekm = MockEphemeralKeyManager(key: customerKey, error: nil)
        let sut = STPCustomerContext(keyManager: ekm, apiClient: apiClient)
        // Give the mocked API request a little time to complete and cache the customer, then check cache
        let exp = expectation(description: "retrieveCustomer")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + ohhttpDelay) {
            sut.retrieveCustomer { customer, error in
                // Apple Pay should be filtered out
                XCTAssertEqual(customer!.sources.count, 1)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testIncludeApplePaySources() {
        let customerKey = STPFixtures.ephemeralKey()
        let expectedCustomerJSON = STPFixtures.customerWithCardAndApplePaySourcesJSON()
        let expectedPaymentMethodsJSON = [STPFixtures.paymentMethodJSON(), STPFixtures.applePayPaymentMethodJSON()]
        let apiClient = stubbedAPIClient()
        
        stubRetrieveCustomers(key: customerKey, returningCustomerJSON: expectedCustomerJSON, expectedCount: 1, apiClient: apiClient)
        stubListPaymentMethods(key: customerKey, paymentMethodJSONs: expectedPaymentMethodsJSON, expectedCount: 1, apiClient: apiClient)

        let ekm = MockEphemeralKeyManager(key: customerKey, error: nil)
        let sut = STPCustomerContext(keyManager: ekm, apiClient: apiClient)
        sut.includeApplePayPaymentMethods = true
        // Give the mocked API request a little time to complete and cache the customer, then check cache
        let exp = expectation(description: "retrieveCustomer")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + ohhttpDelay) {
            sut.retrieveCustomer { customer, error in
                // Apple Pay should be filtered out
                XCTAssertEqual(customer!.sources.count, 2)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    let ohhttpDelay = 0.1
}

