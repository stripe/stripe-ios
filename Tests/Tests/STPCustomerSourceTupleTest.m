//
//  STPCustomerSourceTupleTest.m
//  Stripe
//
//  Created by Brian Dorfman on 10/12/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPCustomer+SourceTuple.h"
#import "STPFixtures.h"
#import "STPMocks.h"
#import "STPPaymentConfiguration.h"

@interface STPCustomerSourceTupleTest : XCTestCase

@end

@implementation STPCustomerSourceTupleTest

/**
 Helper method for performing source tuple tests. This validates the intended
 behavior with variable input data.

 If a customer has valid sources for UI, they should all be in the tuple's
 payment methods. If apple pay is enabled, it should also be included in the
 method count.

 @param sut The customer to test
 @param applePayEnabled Whether or not apple pay should be added as a method
 @param expectedSourceCount The expected final valid sources count, including apple pay if you enabled it.
 @param expectedSelectedSource The expected selected source. Should be customer's
 default source if it is valid, or apple pay, or nil.
 */
- (void)performSourceTupleTestWithCustomer:(STPCustomer *)sut
                           applePayEnabled:(BOOL)applePayEnabled
                      expectedValidSources:(NSUInteger)expectedSourceCount
                    expectedSelectedSource:(id)expectedSelectedSource {
    STPPaymentConfiguration *config = [STPMocks paymentConfigurationWithApplePaySupportingDevice];
    config.additionalPaymentMethods = applePayEnabled ? STPPaymentMethodTypeAll : STPPaymentMethodTypeNone;

    STPPaymentMethodTuple *tuple = [sut filteredSourceTupleForUIWithConfiguration:config];
    XCTAssertNotNil(tuple);

    if (expectedSelectedSource) {
        XCTAssertEqualObjects(tuple.selectedPaymentMethod, expectedSelectedSource);
    }
    else {
        XCTAssertNil(tuple.selectedPaymentMethod);
    }

    XCTAssertNotNil(tuple.paymentMethods);

    XCTAssertTrue(tuple.paymentMethods.count == expectedSourceCount);
}

/**
 This helper calls the matching above helper twice, once with and once without
 apple pay enabled and modifies the expected outcome accordingly.

 See that method for parameter documentation
 */
- (void)performSourceTupleTestWithCustomer:(STPCustomer *)sut
                      expectedValidSources:(NSUInteger)expectedSourceCount
                    expectedSelectedSource:(id)expectedSelectedSource {
    [self performSourceTupleTestWithCustomer:sut
                             applePayEnabled:NO
                        expectedValidSources:expectedSourceCount
                      expectedSelectedSource:expectedSelectedSource];

    [self performSourceTupleTestWithCustomer:sut
                             applePayEnabled:YES
                        expectedValidSources:expectedSourceCount + 1
                      expectedSelectedSource:expectedSelectedSource ?: [STPApplePayPaymentMethod new]];
}

- (void)testSourceTupleCreationNoSources {
    STPCustomer *customer = [STPFixtures customerWithNoSources];

    [self performSourceTupleTestWithCustomer:customer
                        expectedValidSources:0
                      expectedSelectedSource:nil];
}

- (void)testSourceTupleCreationSingleTokenCardSource {
    STPCustomer *customer = [STPFixtures customerWithSingleCardTokenSource];
    [self performSourceTupleTestWithCustomer:customer
                        expectedValidSources:1
                      expectedSelectedSource:customer.defaultSource];
}

- (void)testSourceTupleCreationSingleSourceCardSource {
    STPCustomer *customer = [STPFixtures customerWithSingleCardSourceSource];
    [self performSourceTupleTestWithCustomer:customer
                        expectedValidSources:1
                      expectedSelectedSource:customer.defaultSource];
}

- (void)testSourceTupleCreationMixedCardSources {
    STPCustomer *customer = [STPFixtures customerWithCardTokenAndSourceSources];
    [self performSourceTupleTestWithCustomer:customer
                        expectedValidSources:2
                      expectedSelectedSource:customer.defaultSource];
}

- (void)testSourceTupleCreationInvalidSourcesOnly {
    STPCustomer *customer = [STPFixtures customerWithSourcesFromJSONKeys:@[STPTestJSONSource3DS,
                                                                           STPTestJSONSourceAlipay,
                                                                           STPTestJSONSourceiDEAL,
                                                                           STPTestJSONSourceSEPADebit]
                                                           defaultSource:STPTestJSONSourceiDEAL];
    [self performSourceTupleTestWithCustomer:customer
                        expectedValidSources:0
                      expectedSelectedSource:nil];
}


- (void)testSourceTupleCreationMixedValidAndInvalidSourcesWithInvalidDefaultSource {
    STPCustomer *customer = [STPFixtures customerWithSourcesFromJSONKeys:@[STPTestJSONSource3DS,
                                                                           STPTestJSONSourceAlipay,
                                                                           STPTestJSONSourceCard,
                                                                           STPTestJSONSourceiDEAL,
                                                                           STPTestJSONSourceSEPADebit,
                                                                           STPTestJSONCard]
                                                           defaultSource:STPTestJSONSourceiDEAL];

    [self performSourceTupleTestWithCustomer:customer
                        expectedValidSources:2
                      expectedSelectedSource:nil];
}

- (void)testSourceTupleCreationMixedValidAndInvalidSourcesWithValidDefaultSource {
    STPCustomer *customer = [STPFixtures customerWithSourcesFromJSONKeys:@[STPTestJSONSource3DS,
                                                                           STPTestJSONSourceAlipay,
                                                                           STPTestJSONSourceCard,
                                                                           STPTestJSONSourceiDEAL,
                                                                           STPTestJSONSourceSEPADebit,
                                                                           STPTestJSONCard]
                                                           defaultSource:STPTestJSONCard];
    [self performSourceTupleTestWithCustomer:customer
                        expectedValidSources:2
                      expectedSelectedSource:customer.sources[5]];
}

@end
