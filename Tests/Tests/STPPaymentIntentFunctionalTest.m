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

- (void)testConfirmCanceledPaymentIntentFails {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_kFIsmbqInGw6ynJJDMGvsjRi"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Intent confirm"];

    STPPaymentIntentParams *params = [[STPPaymentIntentParams alloc] initWithClientSecret:@"pi_1ChlnaIl4IdHmuTbVnM2HCCf_secret_0T6n3wuf21l04Jun2ZCOB8rOZ"];
    params.sourceParams = [self cardSourceParams];
    [client confirmPaymentIntentWithParams:params
                                completion:^(STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable error) {
                                    XCTAssertNil(paymentIntent);

                                    XCTAssertNotNil(error);
                                    XCTAssertEqualObjects(error.domain, StripeDomain);
                                    XCTAssertEqual(error.code, STPInvalidRequestError);
                                    XCTAssertEqualObjects(error.userInfo[STPErrorMessageKey],
                                                          @"This PaymentIntent could not be updated because it has a status of canceled. Only a PaymentIntent with one of the following statuses may be updated: requires_source, requires_confirmation, requires_source_action.");

                                    [expectation fulfill];
                                }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

/*
 This test exists so that you can manually plug in an id + secret and verify that confirming a PaymentIntent
 succeeds, as a one time thing.

 This is disabled because we don't have an automatic method for creating them, but you can create one using
 your backend, plug the values in, rename this test method (remove `disabled_` prefix) and run it to
 exercise the client SDK.
 */
- (void)disabled_testConfirmPaymentIntentSucceeds {
    // Fill these strings with values for a confirmable PaymentIntent for this test to pass
    NSString *publishableKey = @"";
    NSString *clientSecret = @"";

    if (publishableKey.length == 0 || clientSecret.length == 0) {
        XCTFail(@"Must provide publishableKey and clientSecret manually for this test");
        return;
    }

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:publishableKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Intent confirm"];

    STPPaymentIntentParams *params = [[STPPaymentIntentParams alloc] initWithClientSecret:clientSecret];
    params.sourceParams = [self cardSourceParams];
    [client confirmPaymentIntentWithParams:params
                                completion:^(STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable error) {
                                    XCTAssertNil(error, @"With valid key + secret, should be able to confirm the intent");

                                    XCTAssertNotNil(paymentIntent);
                                    XCTAssertEqualObjects(paymentIntent.stripeId, params.stripeId);
                                    XCTAssertFalse(paymentIntent.livemode);

                                    // sourceParams is the 3DS-required test card
                                    XCTAssertEqual(paymentIntent.status, STPPaymentIntentStatusRequiresSourceAction);

                                    // Going to log all the fields, so that you, the developer manually running this test can inspect them
                                    NSLog(@"Confirmed PaymentIntent: %@", paymentIntent.allResponseFields);

                                    [expectation fulfill];
                                }];

    [self waitForExpectationsWithTimeout:5 handler:nil];
}

#pragma mark - Helpers

- (STPSourceParams *)cardSourceParams {
    STPCardParams *card = [[STPCardParams alloc] init];
    card.number = @"4000 0000 0000 3063"; // Test 3DS required card
    card.expMonth = 7;
    card.expYear = 2024;
    card.currency = @"usd";

    return [STPSourceParams cardParamsWithCard:card];
}

@end
