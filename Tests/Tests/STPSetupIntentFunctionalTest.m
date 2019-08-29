//
//  STPSetupIntentFunctionalTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 6/28/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPNetworkStubbingTestCase.h"

#import "STPSetupIntent+Private.h"

@import Stripe;

@interface STPSetupIntentFunctionalTest : STPNetworkStubbingTestCase

@end

@implementation STPSetupIntentFunctionalTest

- (void)setUp {
//    self.recordingMode = YES;
    [super setUp];
}

- (void)testRetrieveSetupIntentSucceeds {
    // Tests retrieving a previously created SetupIntent succeeds
    NSString *publishableKey = @"pk_test_JBVAMwnBuzCdmsgN34jfxbU700LRiPqVit";
    NSString *setupIntentClientSecret = @"seti_1EqP75KlwPmebFhp81EbUnTF_secret_FL5H8va3AbQhMUdU2ohkWm0OXSHNbLU";
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:publishableKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Setup Intent retrieve"];
    
    [client retrieveSetupIntentWithClientSecret:setupIntentClientSecret
                                     completion:^(STPSetupIntent *setupIntent, NSError *error) {
                                         XCTAssertNil(error);
                                         
                                         XCTAssertNotNil(setupIntent);
                                         XCTAssertEqualObjects(setupIntent.stripeID, @"seti_1EqP75KlwPmebFhp81EbUnTF");
                                         XCTAssertEqualObjects(setupIntent.clientSecret, setupIntentClientSecret);
                                         XCTAssertEqualObjects(setupIntent.created, [NSDate dateWithTimeIntervalSince1970:1561747679]);
                                         XCTAssertNil(setupIntent.customerID);
                                         XCTAssertNil(setupIntent.stripeDescription);
                                         XCTAssertFalse(setupIntent.livemode);
                                         XCTAssertNil(setupIntent.nextAction);
                                         XCTAssertEqualObjects(setupIntent.paymentMethodID, @"pm_1EqP6vKlwPmebFhpuonlkPbr");
                                         XCTAssertEqualObjects(setupIntent.paymentMethodTypes, @[@(STPPaymentMethodTypeCard)]);
                                         XCTAssertEqual(setupIntent.status, STPSetupIntentStatusRequiresConfirmation);
                                         XCTAssertEqual(setupIntent.usage, STPSetupIntentUsageOffSession);
                                         [expectation fulfill];
                                     }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testConfirmSetupIntentSucceeds {
    /**
     Tests confirming a SetupIntent succeeds.
     
     ⚠️ This test will fail if self.recordingMode = YES
     Confirming a SetupIntent is a one-time, non-idempotent operation, and we can't create a new SetupIntent on the client because it requires a secret key (as opposed to a publishable key).

     To update this test requires manual steps:
     1. Create a SetupIntent (via curl or your backend) without a PaymentMethod attached. e.g.
         curl https://api.stripe.com/v1/setup_intents \
         -u (👉 YOUR SECRET KEY) \
         -X POST
     2. Fill in the publishable key and the SetupIntent's secret key below.
     3. Run the test w/ self.recordingMode = YES (don't commit this).
     4. Commit the recorded response in git.
     */
    NSString *publishableKey = @"pk_test_JBVAMwnBuzCdmsgN34jfxbU700LRiPqVit"; // See https://dashboard.stripe.com/test/apikeys
    NSString *setupIntentClientSecret = @"seti_1F0bc0KlwPmebFhpKj75uxLu_secret_FVcrIHr0m6Tf8nIOC0QQquj4KMi1guJ";

    if (publishableKey.length == 0 || setupIntentClientSecret.length == 0) {
        XCTFail(@"Must provide publishableKey and clientSecret manually for this test");
        return;
    }
    
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:publishableKey];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Intent confirm"];
    STPSetupIntentConfirmParams *params = [[STPSetupIntentConfirmParams alloc] initWithClientSecret:setupIntentClientSecret];
    params.returnURL = @"example-app-scheme://authorized";
    // Confirm using a card requiring 3DS2 authentication (ie requires next steps)
    params.paymentMethodID = @"pm_card_authenticationRequired";
    [client confirmSetupIntentWithParams:params
                              completion:^(STPSetupIntent *setupIntent, NSError *error) {
                                  XCTAssertNil(error, @"With valid key + secret, should be able to confirm the intent");
                                  
                                  XCTAssertNotNil(setupIntent);
                                  XCTAssertEqualObjects(setupIntent.stripeID, [STPSetupIntent idFromClientSecret:params.clientSecret]);
                                  XCTAssertEqualObjects(setupIntent.clientSecret, setupIntentClientSecret);
                                  XCTAssertFalse(setupIntent.livemode);
                                  
                                  XCTAssertEqual(setupIntent.status, STPSetupIntentStatusRequiresAction);
                                  XCTAssertNotNil(setupIntent.nextAction);
                                  XCTAssertEqual(setupIntent.nextAction.type, STPIntentActionTypeRedirectToURL);
                                  XCTAssertEqualObjects(setupIntent.nextAction.redirectToURL.returnURL, [NSURL URLWithString:@"example-app-scheme://authorized"]);
                                  XCTAssertNotNil(setupIntent.paymentMethodID);
                                  [expectation fulfill];
                              }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
