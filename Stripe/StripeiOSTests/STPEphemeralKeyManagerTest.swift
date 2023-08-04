//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPEphemeralKeyManagerTest.m
//  Stripe
//
//  Created by Ben Guo on 5/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@testable import Stripe

class FakeEphemeralKeyProvider: NSObject, STPCustomerEphemeralKeyProvider {
    var response: [AnyHashable: Any]?
    var expectation: XCTestExpectation?

    init(response: [AnyHashable: Any]?, expectation: XCTestExpectation?) {
        self.response = response
        self.expectation = expectation
    }

    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping StripePayments.STPJSONResponseCompletionBlock) {
        completion(response!, nil)
        expectation?.fulfill()
    }
}

class FailingEphemeralKeyProvider: NSObject, STPCustomerEphemeralKeyProvider {
    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping StripePayments.STPJSONResponseCompletionBlock) {
        XCTFail("createCustomerKey should not be called")
    }
}

class DelayingEphemeralKeyProvider: NSObject, STPCustomerEphemeralKeyProvider {
    var response: [AnyHashable: Any]
    var expectation: XCTestExpectation

    init(response: [AnyHashable: Any], expectation: XCTestExpectation) {
        self.response = response
        self.expectation = expectation
    }

    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping StripePayments.STPJSONResponseCompletionBlock) {
        expectation.fulfill()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
            completion(self.response, nil)
        })
    }
}

class STPEphemeralKeyManagerTest: XCTestCase {
    let apiVersion = "2015-03-03"

    override func setUp() {
        super.setUp()
    }

    func mockKeyProvider(withKeyResponse keyResponse: [AnyHashable: Any]?) -> Any? {
        let exp = expectation(description: "createCustomerKey")
        let mockKeyProvider = FakeEphemeralKeyProvider(response: keyResponse, expectation: exp)
        return mockKeyProvider
    }

    func testgetOrCreateKeyCreatesNewKeyAfterInit() {
        let expectedKey = STPFixtures.ephemeralKey()
        let keyResponse = expectedKey.allResponseFields
        let mockKeyProvider = self.mockKeyProvider(withKeyResponse: keyResponse)
        let sut = STPEphemeralKeyManager(keyProvider: mockKeyProvider, apiVersion: apiVersion, performsEagerFetching: true)
        let exp = expectation(description: "getOrCreateKey")
        sut.getOrCreateKey({ resourceKey, error in
            XCTAssertEqual(resourceKey, expectedKey)
            XCTAssertNil(error)
            exp.fulfill()
        })
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testgetOrCreateKeyUsesStoredKeyIfNotExpiring() {
        let mockKeyProvider = FailingEphemeralKeyProvider()
        let sut = STPEphemeralKeyManager(keyProvider: mockKeyProvider, apiVersion: apiVersion, performsEagerFetching: true)
        let expectedKey = STPFixtures.ephemeralKey()
        sut.ephemeralKey = expectedKey
        let exp = expectation(description: "getOrCreateKey")
        sut.getOrCreateKey({ resourceKey, error in
            XCTAssertEqual(resourceKey, expectedKey)
            XCTAssertNil(error)
            exp.fulfill()
        })
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testgetOrCreateKeyCreatesNewKeyIfExpiring() {
        let expectedKey = STPFixtures.ephemeralKey()
        let keyResponse = expectedKey.allResponseFields
        let mockKeyProvider = self.mockKeyProvider(withKeyResponse: keyResponse)
        let sut = STPEphemeralKeyManager(keyProvider: mockKeyProvider, apiVersion: apiVersion, performsEagerFetching: true)
        sut.ephemeralKey = STPFixtures.expiringEphemeralKey()
        let exp = expectation(description: "retrieve")
        sut.getOrCreateKey({ resourceKey, error in
            XCTAssertEqual(resourceKey, expectedKey)
            XCTAssertNil(error)
            exp.fulfill()
        })
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testgetOrCreateKeyCoalescesRepeatCalls() {
        let expectedKey = STPFixtures.ephemeralKey()
        let keyResponse = expectedKey.allResponseFields
        let createExp = expectation(description: "createKey")
        createExp.assertForOverFulfill = true

        let mockKeyProvider = DelayingEphemeralKeyProvider(response: keyResponse, expectation: createExp)
        let sut = STPEphemeralKeyManager(keyProvider: mockKeyProvider, apiVersion: apiVersion, performsEagerFetching: true)
        let getExp1 = expectation(description: "getOrCreateKey")
        sut.getOrCreateKey({ ephemeralKey, error in
            XCTAssertEqual(ephemeralKey, expectedKey)
            XCTAssertNil(error)
            getExp1.fulfill()
        })
        let getExp2 = expectation(description: "getOrCreateKey")
        sut.getOrCreateKey({ ephemeralKey, error in
            XCTAssertEqual(ephemeralKey, expectedKey)
            XCTAssertNil(error)
            getExp2.fulfill()
        })

        waitForExpectations(timeout: 2, handler: nil)
    }

    func testEnterForegroundRefreshesResourceKeyIfExpiring() {
        let key = STPFixtures.expiringEphemeralKey()
        let keyResponse = key.allResponseFields
        let mockKeyProvider = self.mockKeyProvider(withKeyResponse: keyResponse)
        let sut = STPEphemeralKeyManager(keyProvider: mockKeyProvider, apiVersion: apiVersion, performsEagerFetching: true)
        XCTAssertNotNil(sut)
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)

        waitForExpectations(timeout: 2, handler: nil)
    }

    func testEnterForegroundDoesNotRefreshResourceKeyIfNotExpiring() {
        let mockKeyProvider = FailingEphemeralKeyProvider()
        let sut = STPEphemeralKeyManager(keyProvider: mockKeyProvider, apiVersion: apiVersion, performsEagerFetching: true)
        sut.ephemeralKey = STPFixtures.ephemeralKey()
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    func testThrottlingEnterForegroundRefreshes() {
        let mockKeyProvider = FailingEphemeralKeyProvider()
        let sut = STPEphemeralKeyManager(keyProvider: mockKeyProvider, apiVersion: apiVersion, performsEagerFetching: true)
        sut.ephemeralKey = STPFixtures.expiringEphemeralKey()
        sut.lastEagerKeyRefresh = Date(timeIntervalSinceNow: -60)
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
    }
}
