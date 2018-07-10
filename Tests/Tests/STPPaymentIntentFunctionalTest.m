//
//  STPPaymentIntentFunctionalTest.m
//  StripeiOS Tests
//
//  Created by Daniel Jackson on 6/27/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
@import Stripe;

#import "STPPaymentIntent+Private.h"

@interface STPPaymentIntentFunctionalTest : XCTestCase

@end

@implementation STPPaymentIntentFunctionalTest

- (void)testRetrievePreviousCreatedPaymentIntent {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_kFIsmbqInGw6ynJJDMGvsjRi"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Intent retrieve"];

    [client retrievePaymentIntentWithClientSecret:@"pi_1ChlnaIl4IdHmuTbVnM2HCCf_secret_0T6n3wuf21l04Jun2ZCOB8rOZ"
                                       completion:^(STPPaymentIntent *paymentIntent, NSError *error) {
                                           XCTAssertNil(error);

                                           XCTAssertNotNil(paymentIntent);
                                           XCTAssertEqualObjects(paymentIntent.stripeId, @"pi_1ChlnaIl4IdHmuTbVnM2HCCf");
                                           XCTAssertEqualObjects(paymentIntent.amount, @(100));
                                           XCTAssertEqualObjects(paymentIntent.currency, @"usd");
                                           XCTAssertFalse(paymentIntent.livemode);
                                           XCTAssertNil(paymentIntent.sourceId);
                                           XCTAssertEqual(paymentIntent.status, STPPaymentIntentStatusCanceled);

                                           [expectation fulfill];
                                       }];

    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testRetrieveWithWrongSecret {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_kFIsmbqInGw6ynJJDMGvsjRi"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Intent retrieve"];

    [client retrievePaymentIntentWithClientSecret:@"pi_1ChlnaIl4IdHmuTbVnM2HCCf_secret_bad-secret"
                                       completion:^(STPPaymentIntent *paymentIntent, NSError *error) {
                                           XCTAssertNil(paymentIntent);

                                           XCTAssertNotNil(error);
                                           XCTAssertEqualObjects(error.domain, StripeDomain);
                                           XCTAssertEqual(error.code, STPInvalidRequestError);
                                           XCTAssertEqualObjects(error.userInfo[STPErrorParameterKey],
                                                                 @"clientSecret");

                                           [expectation fulfill];
                             }];

    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testRetrieveMismatchedPublishableKey {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_dCyfhfyeO2CZkcvT5xyIDdJj"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Intent retrieve"];

    [client retrievePaymentIntentWithClientSecret:@"pi_1ChlnaIl4IdHmuTbVnM2HCCf_secret_0T6n3wuf21l04Jun2ZCOB8rOZ"
                                       completion:^(STPPaymentIntent *paymentIntent, NSError *error) {
                                           XCTAssertNil(paymentIntent);

                                           XCTAssertNotNil(error);
                                           XCTAssertEqualObjects(error.domain, StripeDomain);
                                           XCTAssertEqual(error.code, STPInvalidRequestError);
                                           XCTAssertEqualObjects(error.userInfo[STPErrorParameterKey],
                                                                 @"intent");

                                           [expectation fulfill];
                                       }];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end
