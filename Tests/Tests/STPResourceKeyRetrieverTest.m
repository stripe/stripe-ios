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

@property (nonatomic) STP

@end

@interface STPResourceKeyRetrieverTest : XCTestCase

@end

@implementation STPResourceKeyRetrieverTest

- (void)testEnterForegroundRefreshesResourceKeyIfExpiring {
    id mockKeyProvider = OCMProtocolMock(@protocol(STPResourceKeyProvider));
    XCTestExpectation *exp = [self expectationWithDescription:@"retrieveKey"];
    exp.expectedFulfillmentCount = 2; // retrieveKey should be called twice
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
    XCTestExpectation *exp = [self expectationWithDescription:@"retrieveKey"];
    exp.expectedFulfillmentCount = 1; // retrieveKey should be called once
    OCMStub([mockKeyProvider retrieveKey:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        STPResourceKeyCompletionBlock completion;
        [invocation getArgument:&completion atIndex:2];
        // resource key will not expire
        completion([STPFixtures resourceKey], nil);
        [exp fulfill];
    });
    STPResourceKeyRetriever *sut = [[STPResourceKeyRetriever alloc] initWithKeyProvider:mockKeyProvider];
    XCTAssertNotNil(sut);
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification object:nil];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

@end
