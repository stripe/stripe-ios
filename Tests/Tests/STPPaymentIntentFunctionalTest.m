//
//  STPPaymentIntentFunctionalTest.m
//  StripeiOS Tests
//
//  Created by Daniel Jackson on 6/27/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPNetworkStubbingTestCase.h"
@import Stripe;

#import "STPPaymentIntent+Private.h"

@interface STPPaymentIntentFunctionalTest : STPNetworkStubbingTestCase
@end

@implementation STPPaymentIntentFunctionalTest

- (void)setUp {
//    self.recordingMode = YES;
    [super setUp];
}

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
                                           XCTAssertNil(paymentIntent.paymentMethodId);
                                           XCTAssertEqual(paymentIntent.status, STPPaymentIntentStatusCanceled);
                                           XCTAssertEqual(paymentIntent.setupFutureUsage, STPPaymentIntentSetupFutureUsageNone);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
                                           XCTAssertNil(paymentIntent.nextSourceAction);
#pragma clang diagnostic pop
                                           XCTAssertNil(paymentIntent.nextAction);

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
                                    XCTAssertTrue([error.userInfo[STPErrorMessageKey] hasPrefix:@"This PaymentIntent's source could not be updated because it has a status of canceled. You may only update the source of a PaymentIntent with one of the following statuses: requires_payment_method, requires_confirmation, requires_action, requires_capture."],
                                                  @"Expected error message to complain about status being canceled. Actual msg: `%@`", error.userInfo[STPErrorMessageKey]);

                                    [expectation fulfill];
                                }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

#pragma mark - Disabled Tests
/*
 ⚠️ These tests exist so that you can manually plug in an id + secret and verify that confirming a PaymentIntent
 succeeds, as a one time thing. These are disabled because we don't have an automatic method for creating PaymentIntents.
 
 To run requires manual steps:
 1. Create a PaymentIntent.  e.g.:
     curl https://api.stripe.com/v1/payment_intents \
     -u (👉 YOUR SECRET KEY) \
     -d payment_method=pm_card_visa \
     -d amount=100 \
     -d currency=usd \
     -X POST
 2. Fill in the publishable key and the PaymentIntent's secret_key in the test method.
 3. Rename the test method (remove `disabled_` prefix)
 
 Note you will have to do this for each test.
 */

- (void)disabled_testConfirmPaymentIntentWithCardSucceeds {
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
    // returnURL must be passed in while confirming (not creation time)
    params.returnURL = @"example-app-scheme://authorized";
    [client confirmPaymentIntentWithParams:params
                                completion:^(STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable error) {
                                    XCTAssertNil(error, @"With valid key + secret, should be able to confirm the intent");

                                    XCTAssertNotNil(paymentIntent);
                                    XCTAssertEqualObjects(paymentIntent.stripeId, params.stripeId);
                                    XCTAssertFalse(paymentIntent.livemode);

                                    // sourceParams is the 3DS-required test card
                                    XCTAssertEqual(paymentIntent.status, STPPaymentIntentStatusRequiresAction);

                                    // STPRedirectContext is relying on receiving returnURL
                                    XCTAssertNotNil(paymentIntent.nextAction.redirectToURL.returnURL);
                                    XCTAssertEqualObjects(paymentIntent.nextAction.redirectToURL.returnURL,
                                                          [NSURL URLWithString:@"example-app-scheme://authorized"]);
                                    
                                    // Test deprecated property still works too
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
                                    XCTAssertNotNil(paymentIntent.nextSourceAction.authorizeWithURL.returnURL);
                                    XCTAssertEqualObjects(paymentIntent.nextSourceAction.authorizeWithURL.returnURL,
                                                          [NSURL URLWithString:@"example-app-scheme://authorized"]);
#pragma clang diagnostic pop

                                    // Going to log all the fields, so that you, the developer manually running this test can inspect them
                                    NSLog(@"Confirmed PaymentIntent: %@", paymentIntent.allResponseFields);

                                    [expectation fulfill];
                                }];

    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)disabled_testConfirmPaymentIntentWithCardPaymentMethodSucceeds {
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
    STPPaymentMethodCardParams *cardParams = [STPPaymentMethodCardParams new];
    cardParams.number = @"4000000000003063";
    cardParams.expMonth = @(7);
    cardParams.expYear = @(2024);

    STPPaymentMethodBillingDetails *billingDetails = [STPPaymentMethodBillingDetails new];
    
    params.paymentMethodParams = [STPPaymentMethodParams paramsWithCard:cardParams
                                                         billingDetails:billingDetails
                                                               metadata:nil];
    // returnURL must be passed in while confirming (not creation time)
    params.returnURL = @"example-app-scheme://authorized";
    [client confirmPaymentIntentWithParams:params
                                completion:^(STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable error) {
                                    XCTAssertNil(error, @"With valid key + secret, should be able to confirm the intent");
                                    
                                    XCTAssertNotNil(paymentIntent);
                                    XCTAssertEqualObjects(paymentIntent.stripeId, params.stripeId);
                                    XCTAssertFalse(paymentIntent.livemode);
                                    XCTAssertNotNil(paymentIntent.paymentMethodId);
                                    
                                    // sourceParams is the 3DS-required test card
                                    XCTAssertEqual(paymentIntent.status, STPPaymentIntentStatusRequiresAction);
                                    
                                    // STPRedirectContext is relying on receiving returnURL
                                    
                                    XCTAssertNotNil(paymentIntent.nextAction.redirectToURL.returnURL);
                                    XCTAssertEqualObjects(paymentIntent.nextAction.redirectToURL.returnURL,
                                                          [NSURL URLWithString:@"example-app-scheme://authorized"]);

                                    // Going to log all the fields so that you, the developer manually running this test, can inspect them
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
