//
//  STPCustomerContextTest.m
//  Stripe
//
//  Created by Ben Guo on 5/4/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <Stripe/Stripe.h>
#import "STPAPIClient+Private.h"
#import "STPEphemeralKeyManager.h"
#import "STPFixtures.h"

@interface STPCustomerContext (Testing)

@property (nonatomic) STPCustomer *customer;
@property (nonatomic) NSDate *customerRetrievedDate;

- (instancetype)initWithKeyManager:(STPEphemeralKeyManager *)keyManager;

@end

@interface STPCustomerContextTest : XCTestCase

@end

@implementation STPCustomerContextTest

- (id)mockKeyManagerWithKey:(STPEphemeralKey *)ephemeralKey {
    id mockKeyManager = OCMClassMock([STPEphemeralKeyManager class]);
    OCMStub([mockKeyManager getCustomerKey:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        STPEphemeralKeyCompletionBlock completion;
        [invocation getArgument:&completion atIndex:2];
        completion(ephemeralKey, nil);
    });
    return mockKeyManager;
}

- (id)mockKeyManagerWithError:(NSError *)error {
    id mockKeyManager = OCMClassMock([STPEphemeralKeyManager class]);
    OCMStub([mockKeyManager getCustomerKey:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        STPEphemeralKeyCompletionBlock completion;
        [invocation getArgument:&completion atIndex:2];
        completion(nil, error);
    });
    return mockKeyManager;
}

- (void)testGetCustomerKeyErrorForwardedToRetrieveCustomer {
    NSError *expectedError = [NSError errorWithDomain:@"foo" code:123 userInfo:nil];
    id mockKeyManager = [self mockKeyManagerWithError:expectedError];
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    OCMReject([mockAPIClient retrieveCustomerUsingKey:[OCMArg any] completion:[OCMArg any]]);
    XCTestExpectation *exp = [self expectationWithDescription:@"retrieveCustomer"];
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithKeyManager:mockKeyManager];
    [sut retrieveCustomer:^(STPCustomer *customer, NSError *error) {
        XCTAssertNil(customer);
        XCTAssertEqualObjects(error, expectedError);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testInitRetrievesResourceKeyAndCustomer {
    STPEphemeralKey *customerKey = [STPFixtures ephemeralKey];
    id mockKeyManager = [self mockKeyManagerWithKey:customerKey];
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    STPCustomer *expectedCustomer = [STPFixtures customerWithSingleCardTokenSource];
    XCTestExpectation *exp = [self expectationWithDescription:@"retrieveCustomer"];
    OCMStub([mockAPIClient retrieveCustomerUsingKey:[OCMArg isEqual:customerKey]
                                         completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        STPCustomerCompletionBlock completion;
        [invocation getArgument:&completion atIndex:3];
        completion(expectedCustomer, nil);
        [exp fulfill];
    });
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithKeyManager:mockKeyManager];
    XCTAssertNotNil(sut);

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testRetrieveCustomerUsesCachedCustomerIfNotExpired {
    STPEphemeralKey *customerKey = [STPFixtures ephemeralKey];
    id mockKeyManager = [self mockKeyManagerWithKey:customerKey];
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    STPCustomer *expectedCustomer = [STPFixtures customerWithSingleCardTokenSource];
    XCTestExpectation *exp = [self expectationWithDescription:@"retrieveCustomerWithId"];
    // apiClient.retrieveCustomer should be called once, when the context is initialized.
    // when sut.retrieveCustomer is called below, the cached customer will be used.
    exp.expectedFulfillmentCount = 1; 
    OCMStub([mockAPIClient retrieveCustomerUsingKey:[OCMArg isEqual:customerKey]
                                         completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        STPCustomerCompletionBlock completion;
        [invocation getArgument:&completion atIndex:3];
        completion(expectedCustomer, nil);
        [exp fulfill];
    });
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithKeyManager:mockKeyManager];
    XCTestExpectation *exp2 = [self expectationWithDescription:@"retrieveCustomer"];
    [sut retrieveCustomer:^(STPCustomer *customer, __unused NSError *error) {
        XCTAssertEqualObjects(customer, expectedCustomer);
        [exp2 fulfill];
    }];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testRetrieveCustomerDoesNotUseCachedCustomerIfExpired {
    STPEphemeralKey *customerKey = [STPFixtures ephemeralKey];
    id mockKeyManager = [self mockKeyManagerWithKey:customerKey];
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    STPCustomer *expectedCustomer = [STPFixtures customerWithSingleCardTokenSource];
    XCTestExpectation *retrieveCustomerExp = [self expectationWithDescription:@"retrieveCustomer"];
    // apiClient.retrieveCustomer should be called twice:
    // - when the context is initialized,
    // - when sut.retrieveCustomer is called below, as the cached customer has expired.
    retrieveCustomerExp.expectedFulfillmentCount = 2;
    OCMStub([mockAPIClient retrieveCustomerUsingKey:[OCMArg isEqual:customerKey]
                                         completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        STPCustomerCompletionBlock completion;
        [invocation getArgument:&completion atIndex:3];
        completion(expectedCustomer, nil);
        [retrieveCustomerExp fulfill];
    });
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithKeyManager:mockKeyManager];
    sut.customerRetrievedDate = [NSDate dateWithTimeIntervalSinceNow:-(sut.cachedCustomerMaxAge+10)];
    XCTestExpectation *exp = [self expectationWithDescription:@"retrieveCustomer"];
    [sut retrieveCustomer:^(STPCustomer *customer, __unused NSError *error) {
        XCTAssertEqualObjects(customer, expectedCustomer);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testAttachSourceToCustomerCallsAPIClientCorrectly {
    STPEphemeralKey *customerKey = [STPFixtures ephemeralKey];
    id mockKeyManager = [self mockKeyManagerWithKey:customerKey];
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    STPSource *expectedSource = [STPFixtures cardSource];
    XCTestExpectation *exp = [self expectationWithDescription:@"addSource"];
    OCMStub([mockAPIClient addSource:[OCMArg isEqual:expectedSource.stripeID]
                  toCustomerUsingKey:[OCMArg isEqual:customerKey]
                          completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        STPCustomerCompletionBlock completion;
        [invocation getArgument:&completion atIndex:4];
        completion([STPFixtures customerWithSingleCardTokenSource], nil);
        [exp fulfill];
    });
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithKeyManager:mockKeyManager];
    sut.customer = [STPFixtures customerWithSingleCardTokenSource];
    XCTestExpectation *exp2 = [self expectationWithDescription:@"attachSource"];
    [sut attachSourceToCustomer:expectedSource completion:^(NSError *error) {
        // attaching a source should clear the cached customer
        XCTAssertNil(sut.customer); 
        XCTAssertNil(error);
        [exp2 fulfill];
    }];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testSelectDefaultCustomerSourceCallsAPIClientCorrectly {
    STPEphemeralKey *customerKey = [STPFixtures ephemeralKey];
    id mockKeyManager = [self mockKeyManagerWithKey:customerKey];
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    STPSource *expectedSource = [STPFixtures cardSource];
    XCTestExpectation *exp = [self expectationWithDescription:@"updateCustomer"];
    NSDictionary *expectedParams = @{@"default_source": expectedSource.stripeID};
    OCMStub([mockAPIClient updateCustomerWithParameters:[OCMArg isEqual:expectedParams]
                                               usingKey:[OCMArg isEqual:customerKey]
                                             completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        STPCustomerCompletionBlock completion;
        [invocation getArgument:&completion atIndex:4];
        completion([STPFixtures customerWithSingleCardTokenSource], nil);
        [exp fulfill];
    });
    XCTestExpectation *exp2 = [self expectationWithDescription:@"selectDefaultSource"];
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithKeyManager:mockKeyManager];
    [sut selectDefaultCustomerSource:expectedSource completion:^(NSError *error) {
        XCTAssertNil(error);
        [exp2 fulfill];
    }];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

@end
