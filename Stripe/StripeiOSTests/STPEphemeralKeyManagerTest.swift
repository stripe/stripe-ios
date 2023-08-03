//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPEphemeralKeyManagerTest.swift
//  Stripe
//
//  Created by Ben Guo on 5/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import Stripe

extension STPEphemeralKeyManager {
    var ephemeralKey: STPEphemeralKey?
    var lastEagerKeyRefresh: Date?
}

class STPEphemeralKeyManagerTest: XCTestCase {
    var apiVersion: String?

    override func setUp() {
        super.setUp()
        apiVersion = "2015-03-03"
    }

    func mockKeyProvider(withKeyResponse keyResponse: [AnyHashable : Any]?) -> Any? {
        let exp = expectation(description: "createCustomerKey")
        let mockKeyProvider = OCMProtocolMock(STPEphemeralKeyProvider)
        OCMStub(
            mockKeyProvider?.createCustomerKey(
                        withAPIVersion: (OCMArg == apiVersion),
                        completion: OCMArg.any())).andDo(
            { invocation in
                        var completion: STPJSONResponseCompletionBlock
                        invocation?.getArgument(&completion, atIndex: 3)
                        completion(keyResponse, nil)
                        exp.fulfill()
                    })
        return mockKeyProvider
    }

    func testgetOrCreateKeyCreatesNewKeyAfterInit() {
        let expectedKey = STPFixtures.ephemeralKey()
        let keyResponse = expectedKey.allResponseFields()
        let mockKeyProvider = self.mockKeyProvider(withKeyResponse: keyResponse)
        let sut = STPEphemeralKeyManager(keyProvider: mockKeyProvider, apiVersion: apiVersion, performsEagerFetching: true)
        let exp = expectation(description: "getOrCreateKey")
        sut.getOrCreateKey({ resourceKey, error in
            XCTAssertEqual(resourceKey, expectedKey)
            XCTAssertNil(error)
            exp.fulfill()
        })
        waitForExpectations(timeout: 2, handler: nil)
        mockKeyProvider?.stopMocking()
    }

    func testgetOrCreateKeyUsesStoredKeyIfNotExpiring() {
        let mockKeyProvider = OCMProtocolMock(STPEphemeralKeyProvider)
        OCMReject(mockKeyProvider?.createCustomerKey(withAPIVersion: OCMArg.any(), completion: OCMArg.any()))
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
        mockKeyProvider?.stopMocking()
    }

    func testgetOrCreateKeyCreatesNewKeyIfExpiring() {
        let expectedKey = STPFixtures.ephemeralKey()
        let keyResponse = expectedKey.allResponseFields()
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
        mockKeyProvider?.stopMocking()
    }

    func testgetOrCreateKeyCoalescesRepeatCalls() {
        let expectedKey = STPFixtures.ephemeralKey()
        let keyResponse = expectedKey.allResponseFields()
        let createExp = expectation(description: "createKey")
        createExp.assertForOverFulfill = true
        let mockKeyProvider = OCMProtocolMock(STPEphemeralKeyProvider)
        OCMStub(
            mockKeyProvider?.createCustomerKey(
                        withAPIVersion: (OCMArg == apiVersion),
                        completion: OCMArg.any())).andDo(
            { invocation in
                        var completion: STPJSONResponseCompletionBlock
                        invocation?.getArgument(&completion, atIndex: 3)
                        createExp.fulfill()
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
                            completion(keyResponse, nil)
                        })
                    })
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
        mockKeyProvider?.stopMocking()
    }

    // This test doesn't work becuase assertions in Swift are always fatal
    /*
    - (void)testgetOrCreateKeyThrowsExceptionWhenDecodingFails {
        XCTestExpectation *exp1 = [self expectationWithDescription:@"createCustomerKey"];
        NSDictionary *invalidKeyResponse = @{@"foo": @"bar"};
        id mockKeyProvider = OCMProtocolMock(@protocol(STPEphemeralKeyProvider));
        OCMStub([mockKeyProvider createCustomerKeyWithAPIVersion:[OCMArg isEqual:self.apiVersion]
                                                      completion:[OCMArg any]])
        .andDo(^(NSInvocation *invocation) {
            __unsafe_unretained STPJSONResponseCompletionBlock completion;
            [invocation getArgument:&completion atIndex:3];
            XCTAssertThrows(completion(invalidKeyResponse, nil));
            [exp1 fulfill];
        });
        STPEphemeralKeyManager *sut = [[STPEphemeralKeyManager alloc] initWithKeyProvider:mockKeyProvider apiVersion:self.apiVersion performsEagerFetching:YES];
        XCTestExpectation *exp2 = [self expectationWithDescription:@"retrieve"];
        [sut getOrCreateKey:^(STPEphemeralKey *resourceKey, NSError *error) {
            XCTAssertNil(resourceKey);
            XCTAssertEqualObjects(error, [NSError stp_ephemeralKeyDecodingError]);
            [exp2 fulfill];
        }];
        [self waitForExpectationsWithTimeout:2 handler:nil];
        [mockKeyProvider stopMocking];
    }
     */

    func testEnterForegroundRefreshesResourceKeyIfExpiring() {
        let key = STPFixtures.expiringEphemeralKey()
        let keyResponse = key.allResponseFields()
        let mockKeyProvider = self.mockKeyProvider(withKeyResponse: keyResponse)
        let sut = STPEphemeralKeyManager(keyProvider: mockKeyProvider, apiVersion: apiVersion, performsEagerFetching: true)
        XCTAssertNotNil(Int(sut))
        NotificationCenter.default.post(name: UIApplicationDelegate.willEnterForegroundNotification, object: nil)

        waitForExpectations(timeout: 2, handler: nil)
        mockKeyProvider?.stopMocking()
    }

    func testEnterForegroundDoesNotRefreshResourceKeyIfNotExpiring() {
        let mockKeyProvider = OCMProtocolMock(STPEphemeralKeyProvider)
        OCMReject(mockKeyProvider?.createCustomerKey(withAPIVersion: OCMArg.any(), completion: OCMArg.any()))
        let sut = STPEphemeralKeyManager(keyProvider: mockKeyProvider, apiVersion: apiVersion, performsEagerFetching: true)
        sut.ephemeralKey = STPFixtures.ephemeralKey()
        NotificationCenter.default.post(name: UIApplicationDelegate.willEnterForegroundNotification, object: nil)
        mockKeyProvider?.stopMocking()
    }

    func testThrottlingEnterForegroundRefreshes() {
        let mockKeyProvider = OCMProtocolMock(STPEphemeralKeyProvider)
        OCMReject(mockKeyProvider?.createCustomerKey(withAPIVersion: OCMArg.any(), completion: OCMArg.any()))
        let sut = STPEphemeralKeyManager(keyProvider: mockKeyProvider, apiVersion: apiVersion, performsEagerFetching: true)
        sut.ephemeralKey = STPFixtures.expiringEphemeralKey()
        sut.lastEagerKeyRefresh = Date(timeIntervalSinceNow: -60)
        NotificationCenter.default.post(name: UIApplicationDelegate.willEnterForegroundNotification, object: nil)
        mockKeyProvider?.stopMocking()
    }
}