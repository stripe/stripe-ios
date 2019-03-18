//
//  STPEphemeralKeyManagerTest.m
//  Stripe
//
//  Created by Ben Guo on 5/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Stripe/Stripe.h>
#import "NSError+Stripe.h"
#import "STPEphemeralKey.h"
#import "STPEphemeralKeyManager.h"
#import "STPFixtures.h"

@interface STPEphemeralKeyManager (Testing)
@property (nonatomic) STPEphemeralKey *ephemeralKey;
@property (nonatomic) NSDate *lastEagerKeyRefresh;
@end

@interface STPEphemeralKeyManagerTest : XCTestCase

@property (nonatomic) NSString *apiVersion;

@end

@implementation STPEphemeralKeyManagerTest

- (void)setUp {
    [super setUp];
    self.apiVersion = @"2015-03-03";
}

- (id)mockKeyProviderWithKeyResponse:(NSDictionary *)keyResponse {
    XCTestExpectation *exp = [self expectationWithDescription:@"createCustomerKey"];
    id mockKeyProvider = OCMProtocolMock(@protocol(STPEphemeralKeyProvider));
    OCMStub([mockKeyProvider createCustomerKeyWithAPIVersion:[OCMArg isEqual:self.apiVersion]
                                                  completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        [invocation retainArguments]; // avoids https://github.com/erikdoe/ocmock/issues/147
        STPJSONResponseCompletionBlock completion;
        [invocation getArgument:&completion atIndex:3];
        completion(keyResponse, nil);
        [exp fulfill];
    });
    return mockKeyProvider;
}

- (void)testgetOrCreateKeyCreatesNewKeyAfterInit {
    STPEphemeralKey *expectedKey = [STPFixtures ephemeralKey];
    NSDictionary *keyResponse = [expectedKey allResponseFields];
    id mockKeyProvider = [self mockKeyProviderWithKeyResponse:keyResponse];
    STPEphemeralKeyManager *sut = [[STPEphemeralKeyManager alloc] initWithKeyProvider:mockKeyProvider apiVersion:self.apiVersion performsEagerFetching:YES];
    XCTestExpectation *exp = [self expectationWithDescription:@"getOrCreateKey"];
    [sut getOrCreateKey:^(STPEphemeralKey *resourceKey, NSError *error) {
        XCTAssertEqualObjects(resourceKey, expectedKey);
        XCTAssertNil(error);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testgetOrCreateKeyUsesStoredKeyIfNotExpiring {
    id mockKeyProvider = OCMProtocolMock(@protocol(STPEphemeralKeyProvider));
    OCMReject([mockKeyProvider createCustomerKeyWithAPIVersion:[OCMArg any] completion:[OCMArg any]]);
    STPEphemeralKeyManager *sut = [[STPEphemeralKeyManager alloc] initWithKeyProvider:mockKeyProvider apiVersion:self.apiVersion performsEagerFetching:YES];
    STPEphemeralKey *expectedKey = [STPFixtures ephemeralKey];
    sut.ephemeralKey = expectedKey;
    XCTestExpectation *exp = [self expectationWithDescription:@"getOrCreateKey"];
    [sut getOrCreateKey:^(STPEphemeralKey *resourceKey, NSError *error) {
        XCTAssertEqualObjects(resourceKey, expectedKey);
        XCTAssertNil(error);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testgetOrCreateKeyCreatesNewKeyIfExpiring {
    STPEphemeralKey *expectedKey = [STPFixtures ephemeralKey];
    NSDictionary *keyResponse = [expectedKey allResponseFields];
    id mockKeyProvider = [self mockKeyProviderWithKeyResponse:keyResponse];
    STPEphemeralKeyManager *sut = [[STPEphemeralKeyManager alloc] initWithKeyProvider:mockKeyProvider apiVersion:self.apiVersion performsEagerFetching:YES];
    sut.ephemeralKey = [STPFixtures expiringEphemeralKey];
    XCTestExpectation *exp = [self expectationWithDescription:@"retrieve"];
    [sut getOrCreateKey:^(STPEphemeralKey *resourceKey, NSError *error) {
        XCTAssertEqualObjects(resourceKey, expectedKey);
        XCTAssertNil(error);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testgetOrCreateKeyCoalescesRepeatCalls {
    STPEphemeralKey *expectedKey = [STPFixtures ephemeralKey];
    NSDictionary *keyResponse = [expectedKey allResponseFields];
    XCTestExpectation *createExp = [self expectationWithDescription:@"createKey"];
    createExp.assertForOverFulfill = YES;
    id mockKeyProvider = OCMProtocolMock(@protocol(STPEphemeralKeyProvider));
    OCMStub([mockKeyProvider createCustomerKeyWithAPIVersion:[OCMArg isEqual:self.apiVersion]
                                                  completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        [invocation retainArguments]; // avoids https://github.com/erikdoe/ocmock/issues/147
        STPJSONResponseCompletionBlock completion;
        [invocation getArgument:&completion atIndex:3];
        [createExp fulfill];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            completion(keyResponse, nil);
        });
    });
    STPEphemeralKeyManager *sut = [[STPEphemeralKeyManager alloc] initWithKeyProvider:mockKeyProvider apiVersion:self.apiVersion performsEagerFetching:YES];
    XCTestExpectation *getExp1 = [self expectationWithDescription:@"getOrCreateKey"];
    [sut getOrCreateKey:^(STPEphemeralKey *ephemeralKey, NSError *error) {
        XCTAssertEqualObjects(ephemeralKey, expectedKey);
        XCTAssertNil(error);
        [getExp1 fulfill];
    }];
    XCTestExpectation *getExp2 = [self expectationWithDescription:@"getOrCreateKey"];
    [sut getOrCreateKey:^(STPEphemeralKey *ephemeralKey, NSError *error) {
        XCTAssertEqualObjects(ephemeralKey, expectedKey);
        XCTAssertNil(error);
        [getExp2 fulfill];
    }];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testgetOrCreateKeyThrowsExceptionWhenDecodingFails {
    XCTestExpectation *exp1 = [self expectationWithDescription:@"createCustomerKey"];
    NSDictionary *invalidKeyResponse = @{@"foo": @"bar"};
    id mockKeyProvider = OCMProtocolMock(@protocol(STPEphemeralKeyProvider));
    OCMStub([mockKeyProvider createCustomerKeyWithAPIVersion:[OCMArg isEqual:self.apiVersion]
                                                  completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        [invocation retainArguments]; // avoids https://github.com/erikdoe/ocmock/issues/147
        STPJSONResponseCompletionBlock completion;
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
}

- (void)testEnterForegroundRefreshesResourceKeyIfExpiring {
    STPEphemeralKey *key = [STPFixtures expiringEphemeralKey];
    NSDictionary *keyResponse = [key allResponseFields];
    id mockKeyProvider = [self mockKeyProviderWithKeyResponse:keyResponse];
    STPEphemeralKeyManager *sut = [[STPEphemeralKeyManager alloc] initWithKeyProvider:mockKeyProvider apiVersion:self.apiVersion performsEagerFetching:YES];
    XCTAssertNotNil(sut);
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification object:nil];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testEnterForegroundDoesNotRefreshResourceKeyIfNotExpiring {
    id mockKeyProvider = OCMProtocolMock(@protocol(STPEphemeralKeyProvider));
    OCMReject([mockKeyProvider createCustomerKeyWithAPIVersion:[OCMArg any] completion:[OCMArg any]]);
    STPEphemeralKeyManager *sut = [[STPEphemeralKeyManager alloc] initWithKeyProvider:mockKeyProvider apiVersion:self.apiVersion performsEagerFetching:YES];
    sut.ephemeralKey = [STPFixtures ephemeralKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)testThrottlingEnterForegroundRefreshes {
    id mockKeyProvider = OCMProtocolMock(@protocol(STPEphemeralKeyProvider));
    OCMReject([mockKeyProvider createCustomerKeyWithAPIVersion:[OCMArg any] completion:[OCMArg any]]);
    STPEphemeralKeyManager *sut = [[STPEphemeralKeyManager alloc] initWithKeyProvider:mockKeyProvider apiVersion:self.apiVersion performsEagerFetching:YES];
    sut.ephemeralKey = [STPFixtures expiringEphemeralKey];
    sut.lastEagerKeyRefresh = [NSDate dateWithTimeIntervalSinceNow:-60];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification object:nil];
}

@end
