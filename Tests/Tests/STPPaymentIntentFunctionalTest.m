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
#import "STPTestingAPIClient.h"
#import "STPTestingAPIClient.h"

@interface STPPaymentIntentFunctionalTest : XCTestCase
@end

@implementation STPPaymentIntentFunctionalTest

- (void)testCreatePaymentIntentWithTestingServer {
    XCTestExpectation *expectation = [self expectationWithDescription:@"PaymentIntent create."];
    [[STPTestingAPIClient sharedClient] createPaymentIntentWithParams:nil
                                                           completion:^(NSString * _Nullable clientSecret, NSError * _Nullable error) {
        XCTAssertNotNil(clientSecret);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testCreatePaymentIntentWithInvalidCurrency {
    XCTestExpectation *expectation = [self expectationWithDescription:@"PaymentIntent create."];
    [[STPTestingAPIClient sharedClient] createPaymentIntentWithParams:@{@"payment_method_types": @[@"bancontact"]} completion:^(NSString * _Nullable clientSecret, NSError * _Nullable error) {
        XCTAssertNil(clientSecret);
        XCTAssertNotNil(error);
        XCTAssertTrue([error.userInfo[STPErrorMessageKey] hasPrefix:@"Error creating PaymentIntent: The currency provided (usd) is invalid. Payments with bancontact support the following currencies: eur."]);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testRetrievePreviousCreatedPaymentIntent {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Intent retrieve"];

    [client retrievePaymentIntentWithClientSecret:@"pi_1GGCGfFY0qyl6XeWbSAsh2hn_secret_jbhwsI0DGWhKreJs3CCrluUGe"
                                       completion:^(STPPaymentIntent *paymentIntent, NSError *error) {
                                           XCTAssertNil(error);

                                           XCTAssertNotNil(paymentIntent);
                                           XCTAssertEqualObjects(paymentIntent.stripeId, @"pi_1GGCGfFY0qyl6XeWbSAsh2hn");
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

    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testRetrieveWithWrongSecret {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Intent retrieve"];

    [client retrievePaymentIntentWithClientSecret:@"pi_1GGCGfFY0qyl6XeWbSAsh2hn_secret_bad-secret"
                                       completion:^(STPPaymentIntent *paymentIntent, NSError *error) {
                                           XCTAssertNil(paymentIntent);

                                           XCTAssertNotNil(error);
                                           XCTAssertEqualObjects(error.domain, StripeDomain);
                                           XCTAssertEqual(error.code, STPInvalidRequestError);
                                           XCTAssertEqualObjects(error.userInfo[STPErrorParameterKey],
                                                                 @"clientSecret");

                                           [expectation fulfill];
                             }];

    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testRetrieveMismatchedPublishableKey {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_dCyfhfyeO2CZkcvT5xyIDdJj"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Intent retrieve"];

    [client retrievePaymentIntentWithClientSecret:@"pi_1GGCGfFY0qyl6XeWbSAsh2hn_secret_jbhwsI0DGWhKreJs3CCrluUGe"
                                       completion:^(STPPaymentIntent *paymentIntent, NSError *error) {
                                           XCTAssertNil(paymentIntent);

                                           XCTAssertNotNil(error);
                                           XCTAssertEqualObjects(error.domain, StripeDomain);
                                           XCTAssertEqual(error.code, STPInvalidRequestError);
                                           XCTAssertEqualObjects(error.userInfo[STPErrorParameterKey],
                                                                 @"intent");

                                           [expectation fulfill];
                                       }];

    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testConfirmCanceledPaymentIntentFails {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Intent confirm"];

    STPPaymentIntentParams *params = [[STPPaymentIntentParams alloc] initWithClientSecret:@"pi_1GGCGfFY0qyl6XeWbSAsh2hn_secret_jbhwsI0DGWhKreJs3CCrluUGe"];
    params.sourceParams = [self cardSourceParams];
    [client confirmPaymentIntentWithParams:params
                                completion:^(STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable error) {
                                    XCTAssertNil(paymentIntent);

                                    XCTAssertNotNil(error);
                                    XCTAssertEqualObjects(error.domain, StripeDomain);
                                    XCTAssertEqual(error.code, STPInvalidRequestError);
                                    XCTAssertTrue([error.userInfo[STPErrorMessageKey] hasPrefix:@"This PaymentIntent's source could not be updated because it has a status of canceled. You may only update the source of a PaymentIntent with one of the following statuses: requires_payment_method, requires_confirmation, requires_action."],
                                                  @"Expected error message to complain about status being canceled. Actual msg: `%@`", error.userInfo[STPErrorMessageKey]);

                                    [expectation fulfill];
                                }];
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testConfirmPaymentIntentWith3DSCardSucceeds {

    __block NSString *clientSecret = nil;
    XCTestExpectation *createExpectation = [self expectationWithDescription:@"Create PaymentIntent."];
    [[STPTestingAPIClient sharedClient] createPaymentIntentWithParams:nil completion:^(NSString * _Nullable createdClientSecret, NSError * _Nullable creationError) {
        XCTAssertNotNil(createdClientSecret);
        XCTAssertNil(creationError);
        [createExpectation fulfill];
        clientSecret = [createdClientSecret copy];
    }];
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
    XCTAssertNotNil(clientSecret);

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
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

                                    [expectation fulfill];
                                }];

    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testConfirmPaymentIntentWith3DSCardPaymentMethodSucceeds {

    __block NSString *clientSecret = nil;
       XCTestExpectation *createExpectation = [self expectationWithDescription:@"Create PaymentIntent."];
       [[STPTestingAPIClient sharedClient] createPaymentIntentWithParams:nil completion:^(NSString * _Nullable createdClientSecret, NSError * _Nullable creationError) {
           XCTAssertNotNil(createdClientSecret);
           XCTAssertNil(creationError);
           [createExpectation fulfill];
           clientSecret = [createdClientSecret copy];
       }];
       [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
       XCTAssertNotNil(clientSecret);
    
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Intent confirm"];
    
    STPPaymentIntentParams *params = [[STPPaymentIntentParams alloc] initWithClientSecret:clientSecret];
    STPPaymentMethodCardParams *cardParams = [STPPaymentMethodCardParams new];
    cardParams.number = @"4000000000003063";
    cardParams.expMonth = @(7);
    cardParams.expYear = @([[NSCalendar currentCalendar] component:NSCalendarUnitYear fromDate:[NSDate date]] + 5);

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
    
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testConfirmPaymentIntentWithShippingDetailsSucceeds {
    __block NSString *clientSecret = nil;
    XCTestExpectation *createExpectation = [self expectationWithDescription:@"Create PaymentIntent."];
    [[STPTestingAPIClient sharedClient] createPaymentIntentWithParams:nil completion:^(NSString * _Nullable createdClientSecret, NSError * _Nullable creationError) {
        XCTAssertNotNil(createdClientSecret);
        XCTAssertNil(creationError);
        [createExpectation fulfill];
        clientSecret = [createdClientSecret copy];
    }];
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
    XCTAssertNotNil(clientSecret);

    STPPaymentIntentParams *params = [[STPPaymentIntentParams alloc] initWithClientSecret:clientSecret];
    STPPaymentMethodCardParams *cardParams = [STPPaymentMethodCardParams new];
    cardParams.number = @"4242424242424242";
    cardParams.expMonth = @(7);
    cardParams.expYear = @([[NSCalendar currentCalendar] component:NSCalendarUnitYear fromDate:[NSDate date]] + 5);

    STPPaymentMethodBillingDetails *billingDetails = [STPPaymentMethodBillingDetails new];

    params.paymentMethodParams = [STPPaymentMethodParams paramsWithCard:cardParams
                                                         billingDetails:billingDetails
                                                               metadata:nil];

    STPPaymentIntentShippingDetailsAddressParams *addressParams = [[STPPaymentIntentShippingDetailsAddressParams alloc] initWithLine1:@"123 Main St"];
    addressParams.line2 = @"Apt 2";
    addressParams.city = @"San Francisco";
    addressParams.state = @"CA";
    addressParams.country = @"US";
    addressParams.postalCode = @"94106";
    params.shipping = [[STPPaymentIntentShippingDetailsParams alloc] initWithAddress:addressParams name:@"Jane"];
    params.shipping.carrier = @"UPS";
    params.shipping.phone = @"555-555-5555";
    params.shipping.trackingNumber = @"123abc";

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Intent confirm"];
    [client confirmPaymentIntentWithParams:params
                                completion:^(STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable error) {
        XCTAssertNil(error, @"With valid key + secret, should be able to confirm the intent");

        XCTAssertNotNil(paymentIntent);
        XCTAssertEqualObjects(paymentIntent.stripeId, params.stripeId);
        XCTAssertFalse(paymentIntent.livemode);
        XCTAssertNotNil(paymentIntent.paymentMethodId);

        // Address
        XCTAssertEqualObjects(paymentIntent.shipping.address.line1, @"123 Main St");
        XCTAssertEqualObjects(paymentIntent.shipping.address.line2, @"Apt 2");
        XCTAssertEqualObjects(paymentIntent.shipping.address.city, @"San Francisco");
        XCTAssertEqualObjects(paymentIntent.shipping.address.state, @"CA");
        XCTAssertEqualObjects(paymentIntent.shipping.address.country, @"US");
        XCTAssertEqualObjects(paymentIntent.shipping.address.postalCode, @"94106");

        XCTAssertEqualObjects(paymentIntent.shipping.name, @"Jane");
        XCTAssertEqualObjects(paymentIntent.shipping.carrier, @"UPS");
        XCTAssertEqualObjects(paymentIntent.shipping.phone, @"555-555-5555");
        XCTAssertEqualObjects(paymentIntent.shipping.trackingNumber, @"123abc");

        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

#pragma mark - giropay

- (void)testConfirmPaymentIntentWithGiropay {
    __block NSString *clientSecret = nil;
    XCTestExpectation *createExpectation = [self expectationWithDescription:@"Create PaymentIntent."];
    [[STPTestingAPIClient sharedClient] createPaymentIntentWithParams:@{
        @"payment_method_types": @[@"giropay"],
        @"currency": @"eur",
    }
                                                           completion:^(NSString * _Nullable createdClientSecret, NSError * _Nullable creationError) {
        XCTAssertNotNil(createdClientSecret);
        XCTAssertNil(creationError);
        [createExpectation fulfill];
        clientSecret = [createdClientSecret copy];
    }];
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
    XCTAssertNotNil(clientSecret);

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Intent confirm"];

    STPPaymentIntentParams *paymentIntentParams = [[STPPaymentIntentParams alloc] initWithClientSecret:clientSecret];
    STPPaymentMethodGiropayParams *giropayParams = [STPPaymentMethodGiropayParams new];

    STPPaymentMethodBillingDetails *billingDetails = [STPPaymentMethodBillingDetails new];
    billingDetails.name = @"Jenny Rosen";

    paymentIntentParams.paymentMethodParams = [STPPaymentMethodParams paramsWithGiropay:giropayParams
                                                                         billingDetails:billingDetails
                                                                               metadata:@{@"test_key": @"test_value"}];
    paymentIntentParams.returnURL = @"example-app-scheme://authorized";

    [client confirmPaymentIntentWithParams:paymentIntentParams
                                completion:^(STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable error) {
        XCTAssertNil(error, @"With valid key + secret, should be able to confirm the intent");

        XCTAssertNotNil(paymentIntent);
        XCTAssertEqualObjects(paymentIntent.stripeId, paymentIntentParams.stripeId);

        XCTAssertFalse(paymentIntent.livemode);
        XCTAssertNotNil(paymentIntent.paymentMethodId);

        // giropay requires a redirect
        XCTAssertEqual(paymentIntent.status, STPPaymentIntentStatusRequiresAction);
        XCTAssertNotNil(paymentIntent.nextAction.redirectToURL.returnURL);
        XCTAssertEqualObjects(paymentIntent.nextAction.redirectToURL.returnURL,
                              [NSURL URLWithString:@"example-app-scheme://authorized"]);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

#pragma mark - AU BECS Debit

- (void)testConfirmAUBECSDebitPaymentIntent {

    __block NSString *clientSecret = nil;
    XCTestExpectation *createExpectation = [self expectationWithDescription:@"Create PaymentIntent."];
    [[STPTestingAPIClient sharedClient] createPaymentIntentWithParams:@{
        @"currency": @"aud",
        @"amount": @(2000),
        @"payment_method_types": @[@"au_becs_debit"],
    }
                                                              account:@"au"
                                                           completion:^(NSString * _Nullable createdClientSecret, NSError * _Nullable creationError) {
        XCTAssertNotNil(createdClientSecret);
        XCTAssertNil(creationError);
        [createExpectation fulfill];
        clientSecret = [createdClientSecret copy];
    }];
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
    XCTAssertNotNil(clientSecret);

    STPPaymentMethodAUBECSDebitParams *becsParams = [STPPaymentMethodAUBECSDebitParams new];
    becsParams.bsbNumber = @"000000"; // Stripe test bank
    becsParams.accountNumber = @"000123456"; // test account

    STPPaymentMethodBillingDetails *billingDetails = [STPPaymentMethodBillingDetails new];
    billingDetails.name = @"Jenny Rosen";
    billingDetails.email = @"jrosen@example.com";

    STPPaymentMethodParams *params = [STPPaymentMethodParams paramsWithAUBECSDebit:becsParams
                                                                    billingDetails:billingDetails
                                                                          metadata:@{@"test_key": @"test_value"}];


    STPPaymentIntentParams *paymentIntentParams = [[STPPaymentIntentParams alloc] initWithClientSecret:clientSecret];
    paymentIntentParams.paymentMethodParams = params;

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingAUPublishableKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Intent confirm"];

    [client confirmPaymentIntentWithParams:paymentIntentParams
                                completion:^(STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable error) {
                                    XCTAssertNil(error, @"With valid key + secret, should be able to confirm the intent");

                                    XCTAssertNotNil(paymentIntent);
                                    XCTAssertEqualObjects(paymentIntent.stripeId, paymentIntentParams.stripeId);
                                    XCTAssertNotNil(paymentIntent.paymentMethodId);

                                    // AU BECS Debit should be in Processing
                                    XCTAssertEqual(paymentIntent.status, STPPaymentIntentStatusProcessing);

                                    [expectation fulfill];
                                }];

    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

#pragma mark - Przelewy24

- (void)testConfirmPaymentIntentWithPrzelewy24 {
    __block NSString *clientSecret = nil;
    XCTestExpectation *createExpectation = [self expectationWithDescription:@"Create PaymentIntent."];
    [[STPTestingAPIClient sharedClient] createPaymentIntentWithParams:@{
        @"payment_method_types": @[@"p24"],
        @"currency": @"eur",
    }
                                                           completion:^(NSString * _Nullable createdClientSecret, NSError * _Nullable creationError) {
        XCTAssertNotNil(createdClientSecret);
        XCTAssertNil(creationError);
        [createExpectation fulfill];
        clientSecret = [createdClientSecret copy];
    }];
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
    XCTAssertNotNil(clientSecret);

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Intent confirm"];

    STPPaymentIntentParams *paymentIntentParams = [[STPPaymentIntentParams alloc] initWithClientSecret:clientSecret];
    STPPaymentMethodPrzelewy24Params *przelewy24Params = [STPPaymentMethodPrzelewy24Params new];

    STPPaymentMethodBillingDetails *billingDetails = [STPPaymentMethodBillingDetails new];
    billingDetails.email = @"email@email.com";

    paymentIntentParams.paymentMethodParams = [STPPaymentMethodParams paramsWithPrzelewy24:przelewy24Params
                                                                            billingDetails:billingDetails
                                                                                  metadata:@{@"test_key": @"test_value"}];
    paymentIntentParams.returnURL = @"example-app-scheme://authorized";
    [client confirmPaymentIntentWithParams:paymentIntentParams
                                completion:^(STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable error) {
                                    XCTAssertNil(error, @"With valid key + secret, should be able to confirm the intent");

                                    XCTAssertNotNil(paymentIntent);
                                    XCTAssertEqualObjects(paymentIntent.stripeId, paymentIntentParams.stripeId);
                                    XCTAssertFalse(paymentIntent.livemode);
                                    XCTAssertNotNil(paymentIntent.paymentMethodId);

                                    // Przelewy24 requires a redirect
                                    XCTAssertEqual(paymentIntent.status, STPPaymentIntentStatusRequiresAction);
                                    XCTAssertNotNil(paymentIntent.nextAction.redirectToURL.returnURL);
                                    XCTAssertEqualObjects(paymentIntent.nextAction.redirectToURL.returnURL,
                                                          [NSURL URLWithString:@"example-app-scheme://authorized"]);

                                    [expectation fulfill];
                                }];

    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

#pragma mark - Bancontact

- (void)testConfirmPaymentIntentWithBancontact {
    __block NSString *clientSecret = nil;
    XCTestExpectation *createExpectation = [self expectationWithDescription:@"Create PaymentIntent."];
    [[STPTestingAPIClient sharedClient] createPaymentIntentWithParams:@{
        @"payment_method_types": @[@"bancontact"],
        @"currency": @"eur",
    }
                                                           completion:^(NSString * _Nullable createdClientSecret, NSError * _Nullable creationError) {
        XCTAssertNotNil(createdClientSecret);
        XCTAssertNil(creationError);
        [createExpectation fulfill];
        clientSecret = [createdClientSecret copy];
    }];
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
    XCTAssertNotNil(clientSecret);

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Intent confirm"];

    STPPaymentIntentParams *paymentIntentParams = [[STPPaymentIntentParams alloc] initWithClientSecret:clientSecret];
    STPPaymentMethodBancontactParams *bancontact = [STPPaymentMethodBancontactParams new];

    STPPaymentMethodBillingDetails *billingDetails = [STPPaymentMethodBillingDetails new];
    billingDetails.name = @"Jane Doe";

    paymentIntentParams.paymentMethodParams = [STPPaymentMethodParams paramsWithBancontact:bancontact
                                                                            billingDetails:billingDetails
                                                                                  metadata:@{@"test_key": @"test_value"}];
    paymentIntentParams.returnURL = @"example-app-scheme://authorized";
    [client confirmPaymentIntentWithParams:paymentIntentParams
                                completion:^(STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable error) {
                                    XCTAssertNil(error, @"With valid key + secret, should be able to confirm the intent");

                                    XCTAssertNotNil(paymentIntent);
                                    XCTAssertEqualObjects(paymentIntent.stripeId, paymentIntentParams.stripeId);
                                    XCTAssertFalse(paymentIntent.livemode);
                                    XCTAssertNotNil(paymentIntent.paymentMethodId);

                                    // Bancontact requires a redirect
                                    XCTAssertEqual(paymentIntent.status, STPPaymentIntentStatusRequiresAction);
                                    XCTAssertNotNil(paymentIntent.nextAction.redirectToURL.returnURL);
                                    XCTAssertEqualObjects(paymentIntent.nextAction.redirectToURL.returnURL,
                                                          [NSURL URLWithString:@"example-app-scheme://authorized"]);

                                    [expectation fulfill];
                                }];

    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

#pragma mark - OXXO

- (void)testConfirmPaymentIntentWithOXXO {
    __block NSString *clientSecret = nil;
    XCTestExpectation *createExpectation = [self expectationWithDescription:@"Create PaymentIntent."];
    [[STPTestingAPIClient sharedClient] createPaymentIntentWithParams:@{
        @"payment_method_types": @[@"oxxo"],
        @"amount": @(2000),
        @"currency": @"mxn",
    }
                                                              account:@"mex"
                                                           completion:^(NSString * _Nullable createdClientSecret, NSError * _Nullable creationError) {
        XCTAssertNotNil(createdClientSecret);
        XCTAssertNil(creationError);
        [createExpectation fulfill];
        clientSecret = [createdClientSecret copy];
    }];
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
    XCTAssertNotNil(clientSecret);
    
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingMEXPublishableKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Intent confirm"];
    
    STPPaymentIntentParams *paymentIntentParams = [[STPPaymentIntentParams alloc] initWithClientSecret:clientSecret];
    STPPaymentMethodOXXOParams *oxxo = [STPPaymentMethodOXXOParams new];
    
    STPPaymentMethodBillingDetails *billingDetails = [STPPaymentMethodBillingDetails new];
    billingDetails.name = @"Jane Doe";
    billingDetails.email = @"email@email.com";
    
    paymentIntentParams.paymentMethodParams = [STPPaymentMethodParams paramsWithOXXO:oxxo
                                                                      billingDetails:billingDetails
                                                                            metadata:@{@"test_key": @"test_value"}];
    [client confirmPaymentIntentWithParams:paymentIntentParams
                                completion:^(STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable error) {
        XCTAssertNil(error, @"With valid key + secret, should be able to confirm the intent");
        
        XCTAssertNotNil(paymentIntent);
        XCTAssertEqualObjects(paymentIntent.stripeId, paymentIntentParams.stripeId);
        XCTAssertFalse(paymentIntent.livemode);
        XCTAssertNotNil(paymentIntent.paymentMethodId);
        
        // OXXO requires display the voucher as next step
        NSDictionary *displayOxxoDetails = [paymentIntent.nextAction.allResponseFields objectForKey:@"display_oxxo_details"];
        XCTAssertNotNil([displayOxxoDetails objectForKey:@"expires_after"]);
        XCTAssertNotNil([displayOxxoDetails objectForKey:@"number"]);
        XCTAssertEqual(paymentIntent.status, STPPaymentIntentStatusRequiresAction);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

#pragma mark - EPS

- (void)testConfirmPaymentIntentWithEPS {
    __block NSString *clientSecret = nil;
    XCTestExpectation *createExpectation = [self expectationWithDescription:@"Create PaymentIntent."];
    [[STPTestingAPIClient sharedClient] createPaymentIntentWithParams:@{
        @"payment_method_types": @[@"eps"],
        @"currency": @"eur",
    }
                                                           completion:^(NSString * _Nullable createdClientSecret, NSError * _Nullable creationError) {
        XCTAssertNotNil(createdClientSecret);
        XCTAssertNil(creationError);
        [createExpectation fulfill];
        clientSecret = [createdClientSecret copy];
    }];
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
    XCTAssertNotNil(clientSecret);

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Intent confirm"];

    STPPaymentIntentParams *paymentIntentParams = [[STPPaymentIntentParams alloc] initWithClientSecret:clientSecret];
    STPPaymentMethodEPSParams *epsParams = [STPPaymentMethodEPSParams new];

    STPPaymentMethodBillingDetails *billingDetails = [STPPaymentMethodBillingDetails new];
    billingDetails.name = @"Jenny Rosen";

    paymentIntentParams.paymentMethodParams = [STPPaymentMethodParams paramsWithEPS:epsParams
                                                                         billingDetails:billingDetails
                                                                               metadata:@{@"test_key": @"test_value"}];
    paymentIntentParams.returnURL = @"example-app-scheme://authorized";

    [client confirmPaymentIntentWithParams:paymentIntentParams
                                completion:^(STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable error) {
        XCTAssertNil(error, @"With valid key + secret, should be able to confirm the intent");

        XCTAssertNotNil(paymentIntent);
        XCTAssertEqualObjects(paymentIntent.stripeId, paymentIntentParams.stripeId);

        XCTAssertFalse(paymentIntent.livemode);
        XCTAssertNotNil(paymentIntent.paymentMethodId);

        // EPS requires a redirect
        XCTAssertEqual(paymentIntent.status, STPPaymentIntentStatusRequiresAction);
        XCTAssertNotNil(paymentIntent.nextAction.redirectToURL.returnURL);
        XCTAssertEqualObjects(paymentIntent.nextAction.redirectToURL.returnURL,
                              [NSURL URLWithString:@"example-app-scheme://authorized"]);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

#pragma mark - Helpers

- (STPSourceParams *)cardSourceParams {
    STPCardParams *card = [[STPCardParams alloc] init];
    card.number = @"4000 0000 0000 3063"; // Test 3DS required card
    card.expMonth = 7;
    card.expYear = [[NSCalendar currentCalendar] component:NSCalendarUnitYear fromDate:[NSDate date]] + 5;
    card.currency = @"usd";

    return [STPSourceParams cardParamsWithCard:card];
}

@end
