//
//  STPSetupIntentFunctionalTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 6/28/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPSetupIntent+Private.h"

#import "STPTestingAPIClient.h"

@import Stripe;

@interface STPSetupIntentFunctionalTest : XCTestCase

@end

@implementation STPSetupIntentFunctionalTest

- (void)testCreateSetupIntentWithTestingServer {
    XCTestExpectation *expectation = [self expectationWithDescription:@"SetupIntent create."];
    [[STPTestingAPIClient sharedClient] createSetupIntentWithParams:nil
                                                         completion:^(NSString * _Nullable clientSecret, NSError * _Nullable error) {
        XCTAssertNotNil(clientSecret);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testRetrieveSetupIntentSucceeds {
    // Tests retrieving a previously created SetupIntent succeeds
    NSString *setupIntentClientSecret = @"seti_1GGCuIFY0qyl6XeWVfbQK6b3_secret_GnoX2tzX2JpvxsrcykRSVna2lrYLKew";
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingPublishableKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Setup Intent retrieve"];
    
    [client retrieveSetupIntentWithClientSecret:setupIntentClientSecret
                                     completion:^(STPSetupIntent *setupIntent, NSError *error) {
                                         XCTAssertNil(error);
                                         
                                         XCTAssertNotNil(setupIntent);
                                         XCTAssertEqualObjects(setupIntent.stripeID, @"seti_1GGCuIFY0qyl6XeWVfbQK6b3");
                                         XCTAssertEqualObjects(setupIntent.clientSecret, setupIntentClientSecret);
                                         XCTAssertEqualObjects(setupIntent.created, [NSDate dateWithTimeIntervalSince1970:1582673622]);
                                         XCTAssertNil(setupIntent.customerID);
                                         XCTAssertNil(setupIntent.stripeDescription);
                                         XCTAssertFalse(setupIntent.livemode);
                                         XCTAssertNil(setupIntent.nextAction);
                                         XCTAssertNil(setupIntent.paymentMethodID);
                                         XCTAssertEqualObjects(setupIntent.paymentMethodTypes, @[@(STPPaymentMethodTypeCard)]);
                                         XCTAssertEqual(setupIntent.status, STPSetupIntentStatusRequiresPaymentMethod);
                                         XCTAssertEqual(setupIntent.usage, STPSetupIntentUsageOffSession);
                                         [expectation fulfill];
                                     }];
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testConfirmSetupIntentSucceeds {

    __block NSString *clientSecret = nil;
    XCTestExpectation *createExpectation = [self expectationWithDescription:@"Create SetupIntent."];
    [[STPTestingAPIClient sharedClient] createSetupIntentWithParams:nil completion:^(NSString * _Nullable createdClientSecret, NSError * _Nullable creationError) {
        XCTAssertNotNil(createdClientSecret);
        XCTAssertNil(creationError);
        [createExpectation fulfill];
        clientSecret = [createdClientSecret copy];
    }];
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
    XCTAssertNotNil(clientSecret);
    
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingPublishableKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"SetupIntent confirm"];
    STPSetupIntentConfirmParams *params = [[STPSetupIntentConfirmParams alloc] initWithClientSecret:clientSecret];
    params.returnURL = @"example-app-scheme://authorized";
    // Confirm using a card requiring 3DS1 authentication (ie requires next steps)
    params.paymentMethodID = @"pm_card_authenticationRequired";
    [client confirmSetupIntentWithParams:params
                              completion:^(STPSetupIntent *setupIntent, NSError *error) {
                                  XCTAssertNil(error, @"With valid key + secret, should be able to confirm the intent");
                                  
                                  XCTAssertNotNil(setupIntent);
                                  XCTAssertEqualObjects(setupIntent.stripeID, [STPSetupIntent idFromClientSecret:params.clientSecret]);
                                  XCTAssertEqualObjects(setupIntent.clientSecret, clientSecret);
                                  XCTAssertFalse(setupIntent.livemode);
                                  
                                  XCTAssertEqual(setupIntent.status, STPSetupIntentStatusRequiresAction);
                                  XCTAssertNotNil(setupIntent.nextAction);
                                  XCTAssertEqual(setupIntent.nextAction.type, STPIntentActionTypeRedirectToURL);
                                  XCTAssertEqualObjects(setupIntent.nextAction.redirectToURL.returnURL, [NSURL URLWithString:@"example-app-scheme://authorized"]);
                                  XCTAssertNotNil(setupIntent.paymentMethodID);
                                  [expectation fulfill];
                              }];
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

@end
