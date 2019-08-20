//
//  STPPaymentIntentTest.m
//  StripeiOS Tests
//
//  Created by Daniel Jackson on 6/27/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPPaymentIntent.h"
#import "STPPaymentIntent+Private.h"

#import "STPFixtures.h"
#import "STPTestUtils.h"

@interface STPPaymentIntentTest : XCTestCase

@end

@implementation STPPaymentIntentTest

- (void)testIdentifierFromSecret {
    XCTAssertEqualObjects([STPPaymentIntent idFromClientSecret:@"pi_123_secret_XYZ"],
                          @"pi_123");
    XCTAssertEqualObjects([STPPaymentIntent idFromClientSecret:@"pi_123_secret_RandomlyContains_secret_WhichIsFine"],
                          @"pi_123");

    XCTAssertNil([STPPaymentIntent idFromClientSecret:@""]);
    XCTAssertNil([STPPaymentIntent idFromClientSecret:@"po_123_secret_HasBadPrefix"]);
    XCTAssertNil([STPPaymentIntent idFromClientSecret:@"MissingSentinalForSplitting"]);
}

- (void)testStatusFromString {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    XCTAssertEqual(STPPaymentIntentStatusRequiresSourceAction, STPPaymentIntentStatusRequiresAction);
#pragma clang diagnostic pop
    XCTAssertEqual([STPPaymentIntent statusFromString:@"requires_payment_method"],
                   STPPaymentIntentStatusRequiresPaymentMethod);
    XCTAssertEqual([STPPaymentIntent statusFromString:@"REQUIRES_PAYMENT_METHOD"],
                   STPPaymentIntentStatusRequiresPaymentMethod);

    XCTAssertEqual([STPPaymentIntent statusFromString:@"requires_confirmation"],
                   STPPaymentIntentStatusRequiresConfirmation);
    XCTAssertEqual([STPPaymentIntent statusFromString:@"REQUIRES_CONFIRMATION"],
                   STPPaymentIntentStatusRequiresConfirmation);

    XCTAssertEqual([STPPaymentIntent statusFromString:@"requires_action"],
                   STPPaymentIntentStatusRequiresAction);
    XCTAssertEqual([STPPaymentIntent statusFromString:@"REQUIRES_ACTION"],
                   STPPaymentIntentStatusRequiresAction);

    XCTAssertEqual([STPPaymentIntent statusFromString:@"processing"],
                   STPPaymentIntentStatusProcessing);
    XCTAssertEqual([STPPaymentIntent statusFromString:@"PROCESSING"],
                   STPPaymentIntentStatusProcessing);

    XCTAssertEqual([STPPaymentIntent statusFromString:@"succeeded"],
                   STPPaymentIntentStatusSucceeded);
    XCTAssertEqual([STPPaymentIntent statusFromString:@"SUCCEEDED"],
                   STPPaymentIntentStatusSucceeded);

    XCTAssertEqual([STPPaymentIntent statusFromString:@"requires_capture"],
                   STPPaymentIntentStatusRequiresCapture);
    XCTAssertEqual([STPPaymentIntent statusFromString:@"REQUIRES_CAPTURE"],
                   STPPaymentIntentStatusRequiresCapture);

    XCTAssertEqual([STPPaymentIntent statusFromString:@"canceled"],
                   STPPaymentIntentStatusCanceled);
    XCTAssertEqual([STPPaymentIntent statusFromString:@"CANCELED"],
                   STPPaymentIntentStatusCanceled);

    XCTAssertEqual([STPPaymentIntent statusFromString:@"garbage"],
                   STPPaymentIntentStatusUnknown);
    XCTAssertEqual([STPPaymentIntent statusFromString:@"GARBAGE"],
                   STPPaymentIntentStatusUnknown);
}

- (void)testCaptureMethodFromString {
    XCTAssertEqual([STPPaymentIntent captureMethodFromString:@"manual"],
                   STPPaymentIntentCaptureMethodManual);
    XCTAssertEqual([STPPaymentIntent captureMethodFromString:@"MANUAL"],
                   STPPaymentIntentCaptureMethodManual);

    XCTAssertEqual([STPPaymentIntent captureMethodFromString:@"automatic"],
                   STPPaymentIntentCaptureMethodAutomatic);
    XCTAssertEqual([STPPaymentIntent captureMethodFromString:@"AUTOMATIC"],
                   STPPaymentIntentCaptureMethodAutomatic);

    XCTAssertEqual([STPPaymentIntent captureMethodFromString:@"garbage"],
                   STPPaymentIntentCaptureMethodUnknown);
    XCTAssertEqual([STPPaymentIntent captureMethodFromString:@"GARBAGE"],
                   STPPaymentIntentCaptureMethodUnknown);
}

- (void)testConfirmationMethodFromString {
    XCTAssertEqual([STPPaymentIntent confirmationMethodFromString:@"secret"],
                   STPPaymentIntentConfirmationMethodSecret);
    XCTAssertEqual([STPPaymentIntent confirmationMethodFromString:@"SECRET"],
                   STPPaymentIntentConfirmationMethodSecret);

    XCTAssertEqual([STPPaymentIntent confirmationMethodFromString:@"publishable"],
                   STPPaymentIntentConfirmationMethodPublishable);
    XCTAssertEqual([STPPaymentIntent confirmationMethodFromString:@"PUBLISHABLE"],
                   STPPaymentIntentConfirmationMethodPublishable);

    XCTAssertEqual([STPPaymentIntent confirmationMethodFromString:@"garbage"],
                   STPPaymentIntentConfirmationMethodUnknown);
    XCTAssertEqual([STPPaymentIntent confirmationMethodFromString:@"GARBAGE"],
                   STPPaymentIntentConfirmationMethodUnknown);
}

- (void)testSetupFutureUsageFromString {
    XCTAssertEqual([STPPaymentIntent setupFutureUsageFromString:@"on_session"],
                   STPPaymentIntentSetupFutureUsageOnSession);
    XCTAssertEqual([STPPaymentIntent setupFutureUsageFromString:@"ON_SESSION"],
                   STPPaymentIntentSetupFutureUsageOnSession);

    XCTAssertEqual([STPPaymentIntent setupFutureUsageFromString:@"off_session"],
                   STPPaymentIntentSetupFutureUsageOffSession);
    XCTAssertEqual([STPPaymentIntent setupFutureUsageFromString:@"OFF_SESSION"],
                   STPPaymentIntentSetupFutureUsageOffSession);
    
    XCTAssertEqual([STPPaymentIntent setupFutureUsageFromString:@"garbage"],
                   STPPaymentIntentSetupFutureUsageUnknown);
    XCTAssertEqual([STPPaymentIntent setupFutureUsageFromString:@"GARBAGE"],
                   STPPaymentIntentSetupFutureUsageUnknown);
}

#pragma mark - Description Tests

- (void)testDescription {
    STPPaymentIntent *paymentIntent = [STPFixtures paymentIntent];

    XCTAssertNotNil(paymentIntent);
    NSString *desc = paymentIntent.description;
    XCTAssertTrue([desc containsString:NSStringFromClass([paymentIntent class])]);
    XCTAssertGreaterThan(desc.length, 500UL, @"Custom description should be long");
}

#pragma mark - STPAPIResponseDecodable Tests

- (void)testDecodedObjectFromAPIResponseRequiredFields {
    NSDictionary *fullJson = [STPTestUtils jsonNamed:STPTestJSONPaymentIntent];

    XCTAssertNotNil([STPPaymentIntent decodedObjectFromAPIResponse:fullJson], @"can decode with full json");

    NSArray<NSString *> *requiredFields = @[
                                            @"id",
                                            @"client_secret",
                                            @"amount",
                                            @"currency",
                                            @"livemode",
                                            @"status",
                                            ];

    for (NSString *field in requiredFields) {
        NSMutableDictionary *partialJson = [fullJson mutableCopy];

        XCTAssertNotNil(partialJson[field], @"json should contain %@", field);
        [partialJson removeObjectForKey:field];

        XCTAssertNil([STPPaymentIntent decodedObjectFromAPIResponse:partialJson], @"should not decode without %@", field);
    }
}

- (void)testDecodedObjectFromAPIResponseMapping {
    NSDictionary *response = [STPTestUtils jsonNamed:@"PaymentIntent"];
    STPPaymentIntent *paymentIntent = [STPPaymentIntent decodedObjectFromAPIResponse:response];

    XCTAssertEqualObjects(paymentIntent.stripeId, @"pi_1Cl15wIl4IdHmuTbCWrpJXN6");
    XCTAssertEqualObjects(paymentIntent.clientSecret, @"pi_1Cl15wIl4IdHmuTbCWrpJXN6_secret_EkKtQ7Sg75hLDFKqFG8DtWcaK");
    XCTAssertEqualObjects(paymentIntent.amount, @2345);
    XCTAssertEqualObjects(paymentIntent.canceledAt, [NSDate dateWithTimeIntervalSince1970:1530911045]);
    XCTAssertEqual(paymentIntent.captureMethod, STPPaymentIntentCaptureMethodManual);
    XCTAssertEqual(paymentIntent.confirmationMethod, STPPaymentIntentConfirmationMethodPublishable);
    XCTAssertEqualObjects(paymentIntent.created, [NSDate dateWithTimeIntervalSince1970:1530911040]);
    XCTAssertEqualObjects(paymentIntent.currency, @"usd");
    XCTAssertEqualObjects(paymentIntent.stripeDescription, @"My Sample PaymentIntent");
    XCTAssertFalse(paymentIntent.livemode);
    XCTAssertEqualObjects(paymentIntent.receiptEmail, @"danj@example.com");
    
    // Deprecated: `nextSourceAction` & `authorizeWithURL` should just be aliases for `nextAction` & `redirectToURL`
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    XCTAssertEqual(paymentIntent.nextSourceAction, paymentIntent.nextAction, @"Should be the same object.");
    XCTAssertEqual(paymentIntent.nextSourceAction.authorizeWithURL, paymentIntent.nextAction.redirectToURL, @"Should be the same object.");
#pragma clang diagnostic pop

    // nextAction
    XCTAssertNotNil(paymentIntent.nextAction);
    XCTAssertEqual(paymentIntent.nextAction.type, STPIntentActionTypeRedirectToURL);
    XCTAssertNotNil(paymentIntent.nextAction.redirectToURL);
    XCTAssertNotNil(paymentIntent.nextAction.redirectToURL.url);
    NSURL *returnURL = paymentIntent.nextAction.redirectToURL.returnURL;
    XCTAssertNotNil(returnURL);
    XCTAssertEqualObjects(returnURL, [NSURL URLWithString:@"payments-example://stripe-redirect"]);
    NSURL *url = paymentIntent.nextAction.redirectToURL.url;
    XCTAssertNotNil(url);

    XCTAssertEqualObjects(url, [NSURL URLWithString:@"https://hooks.stripe.com/redirect/authenticate/src_1Cl1AeIl4IdHmuTb1L7x083A?client_secret=src_client_secret_DBNwUe9qHteqJ8qQBwNWiigk"]);
    XCTAssertEqualObjects(paymentIntent.sourceId, @"src_1Cl1AdIl4IdHmuTbseiDWq6m");
    XCTAssertEqual(paymentIntent.status, STPPaymentIntentStatusRequiresAction);
    XCTAssertEqual(paymentIntent.setupFutureUsage, STPPaymentIntentSetupFutureUsageNone);
    
    XCTAssertEqualObjects(paymentIntent.paymentMethodTypes, @[@(STPPaymentMethodTypeCard)]);
    
    // lastPaymentError
    
    XCTAssertNotNil(paymentIntent.lastPaymentError);
    XCTAssertEqualObjects(paymentIntent.lastPaymentError.code, @"payment_intent_authentication_failure");
    XCTAssertEqualObjects(paymentIntent.lastPaymentError.docURL, @"https://stripe.com/docs/error-codes/payment-intent-authentication-failure");
    XCTAssertEqualObjects(paymentIntent.lastPaymentError.message, @"The provided PaymentMethod has failed authentication. You can provide payment_method_data or a new PaymentMethod to attempt to fulfill this PaymentIntent again.");
    XCTAssertNotNil(paymentIntent.lastPaymentError.paymentMethod);
    XCTAssertEqual(paymentIntent.lastPaymentError.type, STPPaymentIntentLastPaymentErrorTypeInvalidRequest);

    XCTAssertNotEqual(paymentIntent.allResponseFields, response, @"should have own copy of fields");
    XCTAssertEqualObjects(paymentIntent.allResponseFields, response, @"fields values should match");
}

@end
