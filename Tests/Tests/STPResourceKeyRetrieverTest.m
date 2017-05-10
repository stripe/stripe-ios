//
//  STPResourceKeyRetrieverTest.m
//  Stripe
//
//  Created by Ben Guo on 5/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <Stripe/Stripe.h>
#import "STPFixtures.h"

@interface STPResourceKeyRetriever (Testing)

@property (nonatomic) STPResourceKey *resourceKey;

@end

@interface STPResourceKeyRetrieverTest : XCTestCase

@end

@implementation STPResourceKeyRetrieverTest

- (void)testRetrieveKeyRetrievesNewKeyAfterInit {
    id mockKeyProvider = OCMProtocolMock(@protocol(STPResourceKeyProvider));
    STPResourceKey *expectedKey = [STPFixtures resourceKey];
    OCMStub([mockKeyProvider retrieveKey:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        STPResourceKeyCompletionBlock completion;
        [invocation getArgument:&completion atIndex:2];
        completion(expectedKey, nil);
    });
    STPResourceKeyRetriever *sut = [[STPResourceKeyRetriever alloc] initWithKeyProvider:mockKeyProvider];
    XCTestExpectation *exp = [self expectationWithDescription:@"retrieve"];
    [sut retrieveResourceKey:^(STPResourceKey *resourceKey, NSError *error) {
        XCTAssertEqualObjects(resourceKey, expectedKey);
        XCTAssertNil(error);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testRetrieveKeyUsesStoredKeyIfNotExpiring {
    id mockKeyProvider = OCMProtocolMock(@protocol(STPResourceKeyProvider));
    OCMReject([mockKeyProvider retrieveKey:[OCMArg any]]);
    STPResourceKeyRetriever *sut = [[STPResourceKeyRetriever alloc] initWithKeyProvider:mockKeyProvider];
    STPResourceKey *expectedKey = [STPFixtures resourceKey];
    sut.resourceKey = expectedKey;
    XCTestExpectation *exp = [self expectationWithDescription:@"retrieve"];
    [sut retrieveResourceKey:^(STPResourceKey *resourceKey, NSError *error) {
        XCTAssertEqualObjects(resourceKey, expectedKey);
        XCTAssertNil(error);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testRetrieveKeyRetrievesNewKeyIfExpiring {
    id mockKeyProvider = OCMProtocolMock(@protocol(STPResourceKeyProvider));
    STPResourceKey *expectedKey = [STPFixtures resourceKey];
    OCMStub([mockKeyProvider retrieveKey:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        STPResourceKeyCompletionBlock completion;
        [invocation getArgument:&completion atIndex:2];
        completion(expectedKey, nil);
    });
    STPResourceKeyRetriever *sut = [[STPResourceKeyRetriever alloc] initWithKeyProvider:mockKeyProvider];
    sut.resourceKey = [STPFixtures expiringResourceKey];
    XCTestExpectation *exp = [self expectationWithDescription:@"retrieve"];
    [sut retrieveResourceKey:^(STPResourceKey *resourceKey, NSError *error) {
        XCTAssertEqualObjects(resourceKey, expectedKey);
        XCTAssertNil(error);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testEnterForegroundRefreshesResourceKeyIfExpiring {
    id mockKeyProvider = OCMProtocolMock(@protocol(STPResourceKeyProvider));
    XCTestExpectation *exp = [self expectationWithDescription:@"retrieveKey"];
    OCMStub([mockKeyProvider retrieveKey:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        STPResourceKeyCompletionBlock completion;
        [invocation getArgument:&completion atIndex:2];
        completion([STPFixtures expiringResourceKey], nil);
        [exp fulfill];
    });
    STPResourceKeyRetriever *sut = [[STPResourceKeyRetriever alloc] initWithKeyProvider:mockKeyProvider];
    XCTAssertNotNil(sut);
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification object:nil];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testEnterForegroundDoesNotRefreshResourceKeyIfNotExpiring {
    id mockKeyProvider = OCMProtocolMock(@protocol(STPResourceKeyProvider));
    OCMReject([mockKeyProvider retrieveKey:[OCMArg any]]);
    STPResourceKeyRetriever *sut = [[STPResourceKeyRetriever alloc] initWithKeyProvider:mockKeyProvider];
    sut.resourceKey = [STPFixtures resourceKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification object:nil];
}

@end
