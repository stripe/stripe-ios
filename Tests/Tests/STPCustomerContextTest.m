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
#import "STPCustomerContext+Private.h"
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

- (void)stubRetrieveCustomerUsingKey:(STPEphemeralKey *)key
                   returningCustomer:(STPCustomer *)customer
                       expectedCount:(NSInteger)count {
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    [self stubRetrieveCustomerUsingKey:key
                     returningCustomer:customer
                         expectedCount:count
                         mockAPIClient:mockAPIClient];
}

- (void)stubRetrieveCustomerUsingKey:(STPEphemeralKey *)key
                   returningCustomer:(STPCustomer *)customer
                       expectedCount:(NSInteger)count
                       mockAPIClient:(id)mockAPIClient
{
    XCTestExpectation *exp = [self expectationWithDescription:@"retrieveCustomer"];
    exp.expectedFulfillmentCount = count;
    OCMStub([mockAPIClient retrieveCustomerUsingKey:[OCMArg isEqual:key]
                                         completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        STPCustomerCompletionBlock completion;
        [invocation getArgument:&completion atIndex:3];
        completion(customer, nil);
        [exp fulfill];
    });
}

- (void)testGetCustomerKeyErrorForwardedToRetrieveCustomer {
    NSError *expectedError = [NSError errorWithDomain:@"foo" code:123 userInfo:nil];
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    OCMReject([mockAPIClient retrieveCustomerUsingKey:[OCMArg any] completion:[OCMArg any]]);
    id mockKeyManager = [self mockKeyManagerWithError:expectedError];
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
    STPCustomer *expectedCustomer = [STPFixtures customerWithSingleCardTokenSource];
    [self stubRetrieveCustomerUsingKey:customerKey
                     returningCustomer:expectedCustomer
                         expectedCount:1];
    id mockKeyManager = [self mockKeyManagerWithKey:customerKey];
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithKeyManager:mockKeyManager];
    XCTAssertNotNil(sut);

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testRetrieveCustomerUsesCachedCustomerIfNotExpired {
    STPEphemeralKey *customerKey = [STPFixtures ephemeralKey];
    STPCustomer *expectedCustomer = [STPFixtures customerWithSingleCardTokenSource];
    // apiClient.retrieveCustomer should be called once, when the context is initialized.
    // When sut.retrieveCustomer is called below, the cached customer will be used.
    [self stubRetrieveCustomerUsingKey:customerKey
                     returningCustomer:expectedCustomer
                         expectedCount:1];
    id mockKeyManager = [self mockKeyManagerWithKey:customerKey];
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
    STPCustomer *expectedCustomer = [STPFixtures customerWithSingleCardTokenSource];
    // apiClient.retrieveCustomer should be called twice:
    // - when the context is initialized,
    // - when sut.retrieveCustomer is called below, as the cached customer has expired.
    [self stubRetrieveCustomerUsingKey:customerKey
                     returningCustomer:expectedCustomer
                         expectedCount:2];
    id mockKeyManager = [self mockKeyManagerWithKey:customerKey];
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithKeyManager:mockKeyManager];
    sut.customerRetrievedDate = [NSDate dateWithTimeIntervalSinceNow:-70];
    XCTestExpectation *exp = [self expectationWithDescription:@"retrieveCustomer"];
    [sut retrieveCustomer:^(STPCustomer *customer, __unused NSError *error) {
        XCTAssertEqualObjects(customer, expectedCustomer);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testRetrieveCustomerDoesNotUseCachedCustomerAfterClearingCache {
    STPEphemeralKey *customerKey = [STPFixtures ephemeralKey];
    STPCustomer *expectedCustomer = [STPFixtures customerWithSingleCardTokenSource];
    // apiClient.retrieveCustomer should be called twice:
    // - when the context is initialized,
    // - when sut.retrieveCustomer is called below, as the cached customer has been cleared
    [self stubRetrieveCustomerUsingKey:customerKey
                     returningCustomer:expectedCustomer
                         expectedCount:2];
    id mockKeyManager = [self mockKeyManagerWithKey:customerKey];
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithKeyManager:mockKeyManager];
    [sut clearCachedCustomer];
    XCTestExpectation *exp = [self expectationWithDescription:@"retrieveCustomer"];
    [sut retrieveCustomer:^(STPCustomer *customer, __unused NSError *error) {
        XCTAssertEqualObjects(customer, expectedCustomer);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testAttachSourceToCustomerCallsAPIClientCorrectly {
    STPEphemeralKey *customerKey = [STPFixtures ephemeralKey];
    STPCustomer *expectedCustomer = [STPFixtures customerWithSingleCardTokenSource];
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    [self stubRetrieveCustomerUsingKey:customerKey
                     returningCustomer:expectedCustomer
                         expectedCount:1
                         mockAPIClient:mockAPIClient];
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
    id mockKeyManager = [self mockKeyManagerWithKey:customerKey];
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
    STPCustomer *expectedCustomer = [STPFixtures customerWithSingleCardTokenSource];
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    [self stubRetrieveCustomerUsingKey:customerKey
                     returningCustomer:expectedCustomer
                         expectedCount:1
                         mockAPIClient:mockAPIClient];
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
    id mockKeyManager = [self mockKeyManagerWithKey:customerKey];
    XCTestExpectation *exp2 = [self expectationWithDescription:@"selectDefaultSource"];
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithKeyManager:mockKeyManager];
    [sut selectDefaultCustomerSource:expectedSource completion:^(NSError *error) {
        XCTAssertNil(error);
        [exp2 fulfill];
    }];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testSetCustomerShippingCallsAPIClientCorrectly {
    STPAddress *address = [STPFixtures address];
    STPEphemeralKey *customerKey = [STPFixtures ephemeralKey];
    id mockKeyManager = [self mockKeyManagerWithKey:customerKey];
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    XCTestExpectation *exp = [self expectationWithDescription:@"updateCustomer"];
    NSDictionary *expectedParams = @{
                                     @"shipping": @{
                                             @"address": @{
                                                     @"city": address.city,
                                                     @"country": address.country,
                                                     @"line1": address.line1,
                                                     @"line2": address.line2,
                                                     @"postal_code": address.postalCode,
                                                     @"state": address.state
                                                     },
                                             @"name": address.name,
                                             @"phone": address.phone,
                                             }
                                     };
    OCMStub([mockAPIClient updateCustomerWithParameters:[OCMArg isEqual:expectedParams]
                                               usingKey:[OCMArg isEqual:customerKey]
                                             completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        STPCustomerCompletionBlock completion;
        [invocation getArgument:&completion atIndex:4];
        completion([STPFixtures customerWithSingleCardTokenSource], nil);
        [exp fulfill];
    });
    XCTestExpectation *exp2 = [self expectationWithDescription:@"updateCustomerWithShipping"];
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithKeyManager:mockKeyManager];
    [sut updateCustomerWithShippingAddress:address completion:^(NSError *error) {
        XCTAssertNil(error);
        [exp2 fulfill];
    }];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testDetachSourceFromCustomerCallsAPIClientCorrectly {
    STPEphemeralKey *customerKey = [STPFixtures ephemeralKey];
    STPCustomer *expectedCustomer = [STPFixtures customerWithSingleCardTokenSource];
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    [self stubRetrieveCustomerUsingKey:customerKey
                     returningCustomer:expectedCustomer
                         expectedCount:1
                         mockAPIClient:mockAPIClient];
    STPSource *expectedSource = [STPFixtures cardSource];
    XCTestExpectation *exp = [self expectationWithDescription:@"deleteSource"];
    OCMStub([mockAPIClient deleteSource:[OCMArg isEqual:expectedSource.stripeID]
                   fromCustomerUsingKey:[OCMArg isEqual:customerKey]
                             completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        STPCustomerCompletionBlock completion;
        [invocation getArgument:&completion atIndex:4];
        completion([STPFixtures customerWithSingleCardTokenSource], nil);
        [exp fulfill];
    });
    id mockKeyManager = [self mockKeyManagerWithKey:customerKey];
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithKeyManager:mockKeyManager];
    sut.customer = [STPFixtures customerWithSingleCardTokenSource];
    XCTestExpectation *exp2 = [self expectationWithDescription:@"detachSource"];
    [sut detachSourceFromCustomer:expectedSource completion:^(NSError *error) {
        // detaching a source should clear the cached customer
        XCTAssertNil(sut.customer);
        XCTAssertNil(error);
        [exp2 fulfill];
    }];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

@end
