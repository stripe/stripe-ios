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
#import "STPFixtures.h"

@interface STPCustomerContext (Testing)

@property (nonatomic) NSDate *customerRetrievedDate;

- (instancetype)initWithCustomerId:(NSString *)customerId
                       keyProvider:(nonnull id<STPResourceKeyProvider>)keyProvider
                         apiClient:(STPAPIClient *)apiClient;

@end

@interface STPCustomerContextTest : XCTestCase

@end

@implementation STPCustomerContextTest

- (STPResourceKey *)buildResourceKey {
    return [self buildResourceKeyExpiring:NO];
}

- (STPResourceKey *)buildResourceKeyExpiring:(BOOL)expiring {
    NSTimeInterval interval = expiring ? 10 : 100;
    NSDictionary *resourceKeyResponse = @{
                                          @"contents": @"rk_123",
                                          @"expires": @([[NSDate dateWithTimeIntervalSinceNow:interval] timeIntervalSince1970])
                                          };
    return [STPResourceKey decodedObjectFromAPIResponse:resourceKeyResponse];
}

- (void)testInitRetrievesResourceKeyAndCustomer {
    NSString *expectedCustomerID = @"cus_123";
    id mockKeyProvider = OCMProtocolMock(@protocol(STPResourceKeyProvider));
    XCTestExpectation *retrieveKeyExp = [self expectationWithDescription:@"retrieveKey"];
    OCMStub([mockKeyProvider retrieveKey:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        STPResourceKeyCompletionBlock completion;
        [invocation getArgument:&completion atIndex:2];
        completion([self buildResourceKey], nil);
        [retrieveKeyExp fulfill];
    });
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    STPCustomer *expectedCustomer = [STPFixtures customerWithSingleCardTokenSource];
    XCTestExpectation *retrieveCustomerExp = [self expectationWithDescription:@"retrieveCustomer"];
    OCMStub([mockAPIClient retrieveCustomerWithId:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        NSString *customerID;
        STPCustomerCompletionBlock completion;
        [invocation getArgument:&customerID atIndex:2];
        [invocation getArgument:&completion atIndex:3];
        XCTAssertEqualObjects(customerID, expectedCustomerID);
        completion(expectedCustomer, nil);
        [retrieveCustomerExp fulfill];
    });
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithCustomerId:expectedCustomerID
                                                                 keyProvider:mockKeyProvider
                                                                   apiClient:mockAPIClient];
    XCTAssertNotNil(sut);

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testEnterForegroundRefreshesResourceKeyIfExpiring {
    id mockKeyProvider = OCMProtocolMock(@protocol(STPResourceKeyProvider));
    XCTestExpectation *exp = [self expectationWithDescription:@"retrieveKey"];
    exp.expectedFulfillmentCount = 2; // retrieveKey should be called twice
    OCMStub([mockKeyProvider retrieveKey:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        STPResourceKeyCompletionBlock completion;
        [invocation getArgument:&completion atIndex:2];
        // returning an expiring resource key
        completion([self buildResourceKeyExpiring:YES], nil);
        [exp fulfill];
    });
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithCustomerId:@"cus_123"
                                                                 keyProvider:mockKeyProvider
                                                                   apiClient:mockAPIClient];
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
        completion([self buildResourceKeyExpiring:NO], nil);
        [exp fulfill];
    });
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithCustomerId:@"cus_123"
                                                                 keyProvider:mockKeyProvider
                                                                   apiClient:mockAPIClient];
    XCTAssertNotNil(sut);
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification object:nil];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testRetrieveCustomerUsesCachedCustomerIfNotExpired {
    id mockKeyProvider = OCMProtocolMock(@protocol(STPResourceKeyProvider));
    OCMStub([mockKeyProvider retrieveKey:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        STPResourceKeyCompletionBlock completion;
        [invocation getArgument:&completion atIndex:2];
        completion([self buildResourceKey], nil);
    });
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    STPCustomer *expectedCustomer = [STPFixtures customerWithSingleCardTokenSource];
    XCTestExpectation *retrieveCustomerExp = [self expectationWithDescription:@"retrieveCustomer"];
    // apiClient.retrieveCustomer should be called once, when the context is initialized.
    // when sut.retrieveCustomer is called below, the cached customer will be used.
    retrieveCustomerExp.expectedFulfillmentCount = 1; 
    OCMStub([mockAPIClient retrieveCustomerWithId:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        STPCustomerCompletionBlock completion;
        [invocation getArgument:&completion atIndex:3];
        completion(expectedCustomer, nil);
        [retrieveCustomerExp fulfill];
    });
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithCustomerId:@"cus_123"
                                                                 keyProvider:mockKeyProvider
                                                                   apiClient:mockAPIClient];
    XCTestExpectation *exp = [self expectationWithDescription:@"retrieveCustomer"];
    [sut retrieveCustomer:^(STPCustomer *customer, __unused NSError *error) {
        XCTAssertEqualObjects(customer, expectedCustomer);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testRetrieveCustomerDoesNotUseCachedCustomerIfExpired {
    id mockKeyProvider = OCMProtocolMock(@protocol(STPResourceKeyProvider));
    OCMStub([mockKeyProvider retrieveKey:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        STPResourceKeyCompletionBlock completion;
        [invocation getArgument:&completion atIndex:2];
        completion([self buildResourceKey], nil);
    });
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    STPCustomer *expectedCustomer = [STPFixtures customerWithSingleCardTokenSource];
    XCTestExpectation *retrieveCustomerExp = [self expectationWithDescription:@"retrieveCustomer"];
    // apiClient.retrieveCustomer should be called twice:
    // - when the context is initialized,
    // - when sut.retrieveCustomer is called below, as the cached customer has expired.
    retrieveCustomerExp.expectedFulfillmentCount = 2;
    OCMStub([mockAPIClient retrieveCustomerWithId:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        STPCustomerCompletionBlock completion;
        [invocation getArgument:&completion atIndex:3];
        completion(expectedCustomer, nil);
        [retrieveCustomerExp fulfill];
    });
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithCustomerId:@"cus_123"
                                                                 keyProvider:mockKeyProvider
                                                                   apiClient:mockAPIClient];
    sut.customerRetrievedDate = [NSDate dateWithTimeIntervalSinceNow:-(sut.cachedCustomerMaxAge+10)];
    XCTestExpectation *exp = [self expectationWithDescription:@"retrieveCustomer"];
    [sut retrieveCustomer:^(STPCustomer *customer, __unused NSError *error) {
        XCTAssertEqualObjects(customer, expectedCustomer);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testAttachSourceToCustomerCallsUpdateCustomerWithCorrectParams {
    NSString *expectedCustomerID = @"cus_123";
    id mockKeyProvider = OCMProtocolMock(@protocol(STPResourceKeyProvider));
    OCMStub([mockKeyProvider retrieveKey:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        STPResourceKeyCompletionBlock completion;
        [invocation getArgument:&completion atIndex:2];
        completion([self buildResourceKey], nil);
    });
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    STPSource *expectedSource = [STPFixtures cardSource];
    XCTestExpectation *exp = [self expectationWithDescription:@"updateCustomer"];
    OCMStub([mockAPIClient updateCustomerWithId:[OCMArg any] addingSource:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        NSString *customerID;
        NSString *sourceID;
        STPCustomerCompletionBlock completion;
        [invocation getArgument:&customerID atIndex:2];
        [invocation getArgument:&sourceID atIndex:3];
        [invocation getArgument:&completion atIndex:4];
        XCTAssertEqualObjects(customerID, expectedCustomerID);
        XCTAssertEqualObjects(sourceID, expectedSource.stripeID);
        completion([STPFixtures customerWithSingleCardTokenSource], nil);
        [exp fulfill];
    });
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithCustomerId:expectedCustomerID
                                                                 keyProvider:mockKeyProvider
                                                                   apiClient:mockAPIClient];
    [sut attachSourceToCustomer:expectedSource completion:^(NSError *error) {
        XCTAssertNil(error);
    }];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testSelectDefaultCustomerSourceCallsUpdateCustomerWithCorrectParams {
    NSString *expectedCustomerID = @"cus_123";
    id mockKeyProvider = OCMProtocolMock(@protocol(STPResourceKeyProvider));
    OCMStub([mockKeyProvider retrieveKey:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        STPResourceKeyCompletionBlock completion;
        [invocation getArgument:&completion atIndex:2];
        completion([self buildResourceKey], nil);
    });
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    STPSource *expectedSource = [STPFixtures cardSource];
    XCTestExpectation *exp = [self expectationWithDescription:@"updateCustomer"];
    OCMStub([mockAPIClient updateCustomerWithId:[OCMArg any] parameters:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        NSString *customerID;
        NSDictionary *parameters;
        STPCustomerCompletionBlock completion;
        [invocation getArgument:&customerID atIndex:2];
        [invocation getArgument:&parameters atIndex:3];
        [invocation getArgument:&completion atIndex:4];
        XCTAssertEqualObjects(customerID, expectedCustomerID);
        NSDictionary *expectedParams = @{@"default_source": expectedSource.stripeID};
        XCTAssertEqualObjects(parameters, expectedParams);
        completion([STPFixtures customerWithSingleCardTokenSource], nil);
        [exp fulfill];
    });
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithCustomerId:expectedCustomerID
                                                                 keyProvider:mockKeyProvider
                                                                   apiClient:mockAPIClient];
    [sut selectDefaultCustomerSource:expectedSource completion:^(NSError *error) {
        XCTAssertNil(error);
    }];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testRetrieveResourceKeyErrorForwardedToRetrieveCustomer {
    id mockKeyProvider = OCMProtocolMock(@protocol(STPResourceKeyProvider));
    NSError *expectedError = [NSError errorWithDomain:@"foo" code:123 userInfo:nil];
    OCMStub([mockKeyProvider retrieveKey:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        STPResourceKeyCompletionBlock completion;
        [invocation getArgument:&completion atIndex:2];
        completion(nil, expectedError);
    });
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    OCMReject([mockAPIClient retrieveCustomerWithId:[OCMArg any] completion:[OCMArg any]]);
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithCustomerId:@"cus_123"
                                                                 keyProvider:mockKeyProvider
                                                                   apiClient:mockAPIClient];
    [sut retrieveCustomer:^(STPCustomer *customer, NSError *error) {
        XCTAssertNil(customer);
        XCTAssertEqualObjects(error, expectedError);
    }];
}

@end
