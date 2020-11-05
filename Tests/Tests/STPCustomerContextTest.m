//
//  STPCustomerContextTest.m
//  Stripe
//
//  Created by Ben Guo on 5/4/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
@import Stripe;


#import "STPFixtures.h"

@interface STPCustomerContext (Testing)

@property (nonatomic) STPCustomer *customer;
@property (nonatomic) NSDate *customerRetrievedDate;
@property (nonatomic) NSDate *paymentMethodsRetrievedDate;

- (instancetype)initWithKeyManager:(STPEphemeralKeyManager *)keyManager apiClient:(STPAPIClient *)apiClient;

@end

@interface STPCustomerContextTest : XCTestCase

@end

typedef void (^STPEphemeralKeyCompletionBlock)(STPEphemeralKey * __nullable ephemeralKey, NSError * __nullable error);

@implementation STPCustomerContextTest

- (id)mockKeyManagerWithKey:(STPEphemeralKey *)ephemeralKey {
    id mockKeyManager = OCMClassMock([STPEphemeralKeyManager class]);
    OCMStub([mockKeyManager getOrCreateKey:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        STPEphemeralKeyCompletionBlock completion;
        [invocation getArgument:&completion atIndex:2];
        completion(ephemeralKey, nil);
    });
    return mockKeyManager;
}

- (id)mockKeyManagerWithError:(NSError *)error {
    id mockKeyManager = OCMClassMock([STPEphemeralKeyManager class]);
    OCMStub([mockKeyManager getOrCreateKey:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained STPEphemeralKeyCompletionBlock completion;
        [invocation getArgument:&completion atIndex:2];
        completion(nil, error);
    });
    return mockKeyManager;
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
        __unsafe_unretained STPCustomerCompletionBlock completion;
        [invocation getArgument:&completion atIndex:3];
        completion(customer, nil);
        [exp fulfill];
    });
}

- (void)stubListPaymentMethodsUsingKey:(STPEphemeralKey *)key
               returningPaymentMethods:(NSArray<STPPaymentMethod *> *)paymentMethods
                         expectedCount:(NSInteger)count
                         mockAPIClient:(id)mockAPIClient {
    XCTestExpectation *exp = [self expectationWithDescription:@"retrieve payment methods"];
    exp.expectedFulfillmentCount = count;
    OCMStub([mockAPIClient listPaymentMethodsForCustomerUsingKey:[OCMArg isEqual:key]
                                                      completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained STPPaymentMethodsCompletionBlock completion;
        [invocation getArgument:&completion atIndex:3];
        completion(paymentMethods, nil);
        [exp fulfill];
    });
}

- (void)testgetOrCreateKeyErrorForwardedToRetrieveCustomer {
    NSError *expectedError = [NSError errorWithDomain:@"foo" code:123 userInfo:nil];
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    OCMReject([mockAPIClient retrieveCustomerUsingKey:[OCMArg any] completion:[OCMArg any]]);
    id mockKeyManager = [self mockKeyManagerWithError:expectedError];
    XCTestExpectation *exp = [self expectationWithDescription:@"retrieveCustomer"];
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithKeyManager:mockKeyManager apiClient:mockAPIClient];
    [sut retrieveCustomer:^(STPCustomer *customer, NSError *error) {
        XCTAssertNil(customer);
        XCTAssertEqualObjects(error, expectedError);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testInitRetrievesResourceKeyAndCustomerAndPaymentMethods {
    STPEphemeralKey *customerKey = [STPFixtures ephemeralKey];
    STPCustomer *expectedCustomer = [STPFixtures customerWithSingleCardTokenSource];
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    [self stubListPaymentMethodsUsingKey:customerKey
                 returningPaymentMethods:@[]
                           expectedCount:1
                           mockAPIClient:mockAPIClient];
    [self stubRetrieveCustomerUsingKey:customerKey
                     returningCustomer:expectedCustomer
                         expectedCount:1
                         mockAPIClient:mockAPIClient];
    id mockKeyManager = [self mockKeyManagerWithKey:customerKey];
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithKeyManager:mockKeyManager apiClient:mockAPIClient];
    XCTAssertNotNil(sut);

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testRetrieveCustomerUsesCachedCustomerIfNotExpired {
    STPEphemeralKey *customerKey = [STPFixtures ephemeralKey];
    STPCustomer *expectedCustomer = [STPFixtures customerWithSingleCardTokenSource];
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    // apiClient.retrieveCustomer should be called once, when the context is initialized.
    // When sut.retrieveCustomer is called below, the cached customer will be used.
    [self stubRetrieveCustomerUsingKey:customerKey
                     returningCustomer:expectedCustomer
                         expectedCount:1
                         mockAPIClient:mockAPIClient];
    id mockKeyManager = [self mockKeyManagerWithKey:customerKey];
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithKeyManager:mockKeyManager apiClient:mockAPIClient];
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
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    // apiClient.retrieveCustomer should be called twice:
    // - when the context is initialized,
    // - when sut.retrieveCustomer is called below, as the cached customer has expired.
    [self stubRetrieveCustomerUsingKey:customerKey
                     returningCustomer:expectedCustomer
                         expectedCount:2
                         mockAPIClient:mockAPIClient];
    id mockKeyManager = [self mockKeyManagerWithKey:customerKey];
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithKeyManager:mockKeyManager apiClient:mockAPIClient];
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
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    // apiClient.retrieveCustomer should be called twice:
    // - when the context is initialized,
    // - when sut.retrieveCustomer is called below, as the cached customer has been cleared
    [self stubRetrieveCustomerUsingKey:customerKey
                     returningCustomer:expectedCustomer
                         expectedCount:2
                         mockAPIClient:mockAPIClient];
    id mockKeyManager = [self mockKeyManagerWithKey:customerKey];
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithKeyManager:mockKeyManager apiClient:mockAPIClient];
    [sut clearCache];
    XCTestExpectation *exp = [self expectationWithDescription:@"retrieveCustomer2"];
    [sut retrieveCustomer:^(STPCustomer *customer, __unused NSError *error) {
        XCTAssertEqualObjects(customer, expectedCustomer);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testRetrievePaymentMethodsUsesCacheIfNotExpired {
    STPEphemeralKey *customerKey = [STPFixtures ephemeralKey];
    NSArray<STPPaymentMethod *> *expectedPaymentMethods = @[[STPFixtures paymentMethod]];
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    // apiClient.listPaymentMethods should be called once, when the context is initialized.
    // When sut.listPaymentMethods is called below, the cached list will be used.
    [self stubListPaymentMethodsUsingKey:customerKey
                 returningPaymentMethods:expectedPaymentMethods
                           expectedCount:1
                           mockAPIClient:mockAPIClient];
    id mockKeyManager = [self mockKeyManagerWithKey:customerKey];
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithKeyManager:mockKeyManager apiClient:mockAPIClient];
    XCTestExpectation *exp2 = [self expectationWithDescription:@"listPaymentMethods"];
    [sut listPaymentMethodsForCustomerWithCompletion:^(NSArray *paymentMethods, __unused NSError *error) {
        XCTAssertEqualObjects(paymentMethods, expectedPaymentMethods);
        [exp2 fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testRetrievePaymentMethodsDoesNotUseCacheIfExpired {
    STPEphemeralKey *customerKey = [STPFixtures ephemeralKey];
    NSArray<STPPaymentMethod *> *expectedPaymentMethods = @[[STPFixtures paymentMethod]];
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    // apiClient.listPaymentMethods should be called twice:
    // - when the context is initialized,
    // - when sut.listPaymentMethods is called below, as the cached list has expired.
    [self stubListPaymentMethodsUsingKey:customerKey
                 returningPaymentMethods:expectedPaymentMethods
                           expectedCount:2
                           mockAPIClient:mockAPIClient];
    id mockKeyManager = [self mockKeyManagerWithKey:customerKey];
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithKeyManager:mockKeyManager apiClient:mockAPIClient];
    sut.paymentMethodsRetrievedDate = [NSDate dateWithTimeIntervalSinceNow:-70];
    XCTestExpectation *exp = [self expectationWithDescription:@"listPaymentMethods"];
    [sut listPaymentMethodsForCustomerWithCompletion:^(NSArray *paymentMethods, __unused NSError *error) {
        XCTAssertEqualObjects(paymentMethods, expectedPaymentMethods);
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testRetrievePaymentMethodsDoesNotUseCacheAfterClearingCache {
    STPEphemeralKey *customerKey = [STPFixtures ephemeralKey];
    NSArray<STPPaymentMethod *> *expectedPaymentMethods = @[[STPFixtures paymentMethod]];
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    // apiClient.listPaymentMethods should be called twice:
    // - when the context is initialized,
    // - when sut.listPaymentMethods is called below, as the cached list has been cleared
    [self stubListPaymentMethodsUsingKey:customerKey
                 returningPaymentMethods:expectedPaymentMethods
                           expectedCount:2
                           mockAPIClient:mockAPIClient];
    id mockKeyManager = [self mockKeyManagerWithKey:customerKey];
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithKeyManager:mockKeyManager apiClient:mockAPIClient];
    [sut clearCache];
    XCTestExpectation *exp = [self expectationWithDescription:@"listPaymentMethods"];
    [sut listPaymentMethodsForCustomerWithCompletion:^(NSArray *paymentMethods, __unused NSError *error) {
        XCTAssertEqualObjects(paymentMethods, expectedPaymentMethods);
        [exp fulfill];
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
        __unsafe_unretained STPCustomerCompletionBlock completion;
        [invocation getArgument:&completion atIndex:4];
        completion([STPFixtures customerWithSingleCardTokenSource], nil);
        [exp fulfill];
    });
    XCTestExpectation *exp2 = [self expectationWithDescription:@"updateCustomerWithShipping"];
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithKeyManager:mockKeyManager apiClient:mockAPIClient];
    [sut updateCustomerWithShippingAddress:address completion:^(NSError *error) {
        XCTAssertNil(error);
        [exp2 fulfill];
    }];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testAttachPaymentMethodCallsAPIClientCorrectly {
    STPEphemeralKey *customerKey = [STPFixtures ephemeralKey];
    STPPaymentMethod *expectedPaymentMethod = [STPFixtures paymentMethod];
    id mockAPIClient = OCMClassMock([STPAPIClient class]);

    XCTestExpectation *exp = [self expectationWithDescription:@"APIClient attachPaymentMethod"];
    OCMStub([mockAPIClient attachPaymentMethod:[OCMArg isEqual:expectedPaymentMethod.stripeId]
                            toCustomerUsingKey:[OCMArg isEqual:customerKey]
                                    completion:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained STPErrorBlock completion;
        [invocation getArgument:&completion atIndex:4];
        completion(nil);
        [exp fulfill];
    });
    
    STPEphemeralKeyManager *mockKeyManager = [self mockKeyManagerWithKey:customerKey];
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithKeyManager:mockKeyManager apiClient:mockAPIClient];
    XCTestExpectation *exp2 = [self expectationWithDescription:@"CustomerContext attachPaymentMethod"];
    [sut attachPaymentMethodToCustomer:expectedPaymentMethod completion:^(NSError *error) {
        XCTAssertNil(error);
        [exp2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testDetachPaymentMethodCallsAPIClientCorrectly {
    STPEphemeralKey *customerKey = [STPFixtures ephemeralKey];
    STPPaymentMethod *expectedPaymentMethod = [STPFixtures paymentMethod];
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    
    XCTestExpectation *exp = [self expectationWithDescription:@"APIClient detachPaymentMethod"];
    OCMStub([mockAPIClient detachPaymentMethod:[OCMArg isEqual:expectedPaymentMethod.stripeId]
                          fromCustomerUsingKey:[OCMArg isEqual:customerKey]
                                    completion:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained STPErrorBlock completion;
        [invocation getArgument:&completion atIndex:4];
        completion(nil);
        [exp fulfill];
    });
    
    STPEphemeralKeyManager *mockKeyManager = [self mockKeyManagerWithKey:customerKey];
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithKeyManager:mockKeyManager apiClient:mockAPIClient];
    XCTestExpectation *exp2 = [self expectationWithDescription:@"CustomerContext detachPaymentMethod"];
    [sut detachPaymentMethodFromCustomer:expectedPaymentMethod completion:^(NSError *error) {
        XCTAssertNil(error);
        [exp2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testListPaymentMethodCallsAPIClientCorrectly {
    STPEphemeralKey *customerKey = [STPFixtures ephemeralKey];
    NSArray<STPPaymentMethod *> *expectedPaymentMethods = @[[STPFixtures paymentMethod]];
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    
    XCTestExpectation *exp = [self expectationWithDescription:@"APIClient listPaymentMethods"];
    OCMStub([mockAPIClient listPaymentMethodsForCustomerUsingKey:[OCMArg isEqual:customerKey]
                                                      completion:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained STPPaymentMethodsCompletionBlock completion;
        [invocation getArgument:&completion atIndex:3];
        completion(expectedPaymentMethods, nil);
        [exp fulfill];
    });
    
    STPEphemeralKeyManager *mockKeyManager = [self mockKeyManagerWithKey:customerKey];
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithKeyManager:mockKeyManager apiClient:mockAPIClient];
    XCTestExpectation *exp2 = [self expectationWithDescription:@"CustomerContext listPaymentMethods"];
    [sut listPaymentMethodsForCustomerWithCompletion:^(NSArray<STPPaymentMethod *> *paymentMethods, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqualObjects(paymentMethods, expectedPaymentMethods);
        [exp2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

#pragma mark - includeApplePaySources

- (void)testFiltersApplePayPaymentMethodsByDefault {
    STPEphemeralKey *customerKey = [STPFixtures ephemeralKey];
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    NSArray<STPPaymentMethod *> *expectedPaymentMethods = @[[STPFixtures applePayPaymentMethod], [STPFixtures paymentMethod]];
    [self stubListPaymentMethodsUsingKey:customerKey
                 returningPaymentMethods:expectedPaymentMethods
                           expectedCount:1
                           mockAPIClient:mockAPIClient];
    id mockKeyManager = [self mockKeyManagerWithKey:customerKey];
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithKeyManager:mockKeyManager apiClient:mockAPIClient];
    XCTestExpectation *exp = [self expectationWithDescription:@"listPaymentMethods"];
    [sut listPaymentMethodsForCustomerWithCompletion:^(NSArray *paymentMethods, __unused NSError *error) {
        XCTAssertEqual(paymentMethods.count, (unsigned int)1);
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testIncludesApplePayPaymentMethods {
    STPEphemeralKey *customerKey = [STPFixtures ephemeralKey];
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    NSArray<STPPaymentMethod *> *expectedPaymentMethods = @[[STPFixtures applePayPaymentMethod], [STPFixtures paymentMethod]];
    [self stubListPaymentMethodsUsingKey:customerKey
                 returningPaymentMethods:expectedPaymentMethods
                           expectedCount:1
                           mockAPIClient:mockAPIClient];
    id mockKeyManager = [self mockKeyManagerWithKey:customerKey];
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithKeyManager:mockKeyManager apiClient:mockAPIClient];
    sut.includeApplePayPaymentMethods = YES;
    XCTestExpectation *exp = [self expectationWithDescription:@"listPaymentMethods"];
    [sut listPaymentMethodsForCustomerWithCompletion:^(NSArray *paymentMethods, __unused NSError *error) {
        XCTAssertEqual(paymentMethods.count, (unsigned int)2);
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testFiltersApplePaySourcesByDefault {
    STPEphemeralKey *customerKey = [STPFixtures ephemeralKey];
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    STPCustomer *expectedCustomer = [STPFixtures customerWithCardAndApplePaySources];
    [self stubRetrieveCustomerUsingKey:customerKey
                     returningCustomer:expectedCustomer
                         expectedCount:1
                         mockAPIClient:mockAPIClient];
    id mockKeyManager = [self mockKeyManagerWithKey:customerKey];
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithKeyManager:mockKeyManager apiClient:mockAPIClient];
    XCTestExpectation *exp = [self expectationWithDescription:@"retrieveCustomer"];
    [sut retrieveCustomer:^(STPCustomer *customer, __unused NSError *error) {
        XCTAssertEqual(customer.sources.count, (unsigned int)1);
        XCTAssertNil(customer.defaultSource);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testIncludeApplePaySources {
    STPEphemeralKey *customerKey = [STPFixtures ephemeralKey];
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    STPCustomer *expectedCustomer = [STPFixtures customerWithCardAndApplePaySources];
    [self stubRetrieveCustomerUsingKey:customerKey
                     returningCustomer:expectedCustomer
                         expectedCount:1
                         mockAPIClient:mockAPIClient];
    id mockKeyManager = [self mockKeyManagerWithKey:customerKey];
    STPCustomerContext *sut = [[STPCustomerContext alloc] initWithKeyManager:mockKeyManager apiClient:mockAPIClient];
    sut.includeApplePayPaymentMethods = YES;
    XCTestExpectation *exp = [self expectationWithDescription:@"retrieveCustomer"];
    [sut retrieveCustomer:^(STPCustomer *customer, __unused NSError *error) {
        XCTAssertEqual(customer.sources.count, (unsigned int)2);
        XCTAssertNotNil(customer.defaultSource);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

@end
