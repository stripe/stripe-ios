//
//  STPAPIClientNetworkBridgeTest.m
//  StripeiOS
//
//  Created by David Estes on 9/23/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@import Stripe;
@import XCTest;
@import PassKit;
@import StripeCoreTestUtils;
#import "STPNetworkStubbingTestCase.h"
#import "STPTestingAPIClient.h"
#import "STPFixtures.h"

@interface StripeAPIBridgeNetworkTest : XCTestCase

@property (nonatomic) STPAPIClient *client;

@end

// These are a little redundant with the existing
// API tests, but it's a good way to test that the
// bridge works correctly.
@implementation StripeAPIBridgeNetworkTest

- (void)setUp {
    self.client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    [super setUp];
}

// MARK: Bank Account
- (void)testCreateTokenWithBankAccount {
    XCTestExpectation *exp = [self expectationWithDescription:@"Request complete"];
    STPBankAccountParams *params = [[STPBankAccountParams alloc] init];
    params.accountNumber = @"000123456789";
    params.routingNumber = @"110000000";
    params.country = @"US";
    
    [self.client createTokenWithBankAccount:params completion:^(STPToken *token, NSError *error) {
        XCTAssertNotNil(token);
        XCTAssertNil(error);
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:TestConstants.STPTestingNetworkRequestTimeout handler:nil];
}

// MARK: PII

- (void)testCreateTokenWithPII {
    XCTestExpectation *exp = [self expectationWithDescription:@"Create token"];
    
    [self.client createTokenWithPersonalIDNumber:@"123456789" completion:^(STPToken *token, NSError *error) {
        XCTAssertNotNil(token);
        XCTAssertNil(error);
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:TestConstants.STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testCreateTokenWithSSNLast4 {
    XCTestExpectation *exp = [self expectationWithDescription:@"Create SSN"];
    
    [self.client createTokenWithSSNLast4:@"1234" completion:^(STPToken *token, NSError *error) {
        XCTAssertNotNil(token);
        XCTAssertNil(error);
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:TestConstants.STPTestingNetworkRequestTimeout handler:nil];
}

// MARK: Connect Accounts

- (void)testCreateConnectAccount {
    XCTestExpectation *exp = [self expectationWithDescription:@"Create connect account"];
    STPConnectAccountCompanyParams *companyParams = [[STPConnectAccountCompanyParams alloc] init];
    companyParams.name = @"Company";
    STPConnectAccountParams *params = [[STPConnectAccountParams alloc] initWithCompany:companyParams];
    [self.client createTokenWithConnectAccount:params completion:^(STPToken *token, NSError *error) {
        XCTAssertNotNil(token);
        XCTAssertNil(error);
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:TestConstants.STPTestingNetworkRequestTimeout handler:nil];
}

// MARK: Upload

- (void)testUploadFile {
    XCTestExpectation *exp = [self expectationWithDescription:@"Upload file"];
    UIImage *image = [UIImage imageNamed:@"stp_test_upload_image.jpeg"
                                inBundle:[NSBundle bundleForClass:self.class]
           compatibleWithTraitCollection:nil];
    
    [self.client uploadImage:image purpose:STPFilePurposeDisputeEvidence completion:^(STPFile *file, NSError *error) {
        XCTAssertNotNil(file);
        XCTAssertNil(error);
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:TestConstants.STPTestingNetworkRequestTimeout handler:nil];
}

// MARK: Credit Cards

- (void)testCardToken {
    XCTestExpectation *exp = [self expectationWithDescription:@"Create card token"];
    STPCardParams *params = [[STPCardParams alloc] init];
    params.number = @"4242424242424242";
    params.expYear = 42;
    params.expMonth = 12;
    params.cvc = @"123";
    
    [self.client createTokenWithCard:params completion:^(STPToken *token, NSError *error) {
        XCTAssertNotNil(token);
        XCTAssertNil(error);
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:TestConstants.STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testCVCUpdate  {
    XCTestExpectation *exp = [self expectationWithDescription:@"CVC Update"];
    
    [self.client createTokenForCVCUpdate:@"123" completion:^(STPToken *token, NSError *error) {
        XCTAssertNotNil(token);
        XCTAssertNil(error);
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:TestConstants.STPTestingNetworkRequestTimeout handler:nil];
}

// MARK: Sources

- (void)testCreateRetrieveAndPollSource  {
    XCTestExpectation *exp = [self expectationWithDescription:@"Upload file"];
    XCTestExpectation *expR = [self expectationWithDescription:@"Retrieve source"];
    XCTestExpectation *expP = [self expectationWithDescription:@"Poll source"];

    STPCardParams *card = [[STPCardParams alloc] init];
    card.number = @"4242424242424242";
    card.expYear = 42;
    card.expMonth = 12;
    card.cvc = @"123";
    
    STPSourceParams *params = [STPSourceParams cardParamsWithCard:card];
    
    [self.client createSourceWithParams:params completion:^(STPSource *source, NSError *error) {
        XCTAssertNotNil(source);
        XCTAssertNil(error);
        [exp fulfill];
        
        [self.client retrieveSourceWithId:source.stripeID clientSecret:source.clientSecret completion:^(STPSource *source2, NSError *error2) {
            XCTAssertNotNil(source2);
            XCTAssertNil(error2);
            [expR fulfill];
        }];

        [self.client startPollingSourceWithId:source.stripeID clientSecret:source.clientSecret timeout:10 completion:^(STPSource *source2, NSError *error2) {
            XCTAssertNotNil(source2);
            XCTAssertNil(error2);
            [self.client stopPollingSourceWithId:source.stripeID];
            [expP fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:TestConstants.STPTestingNetworkRequestTimeout handler:nil];
}

// MARK: Payment Intents

- (void)testRetrievePaymentIntent  {
    XCTestExpectation *exp = [self expectationWithDescription:@"Fetch"];
    XCTestExpectation *exp2 = [self expectationWithDescription:@"Fetch with expansion"];
    
    STPTestingAPIClient *testClient = [[STPTestingAPIClient alloc] init];
    [testClient createPaymentIntentWithParams:nil completion:^(NSString *clientSecret, NSError *error) {
        XCTAssertNil(error);
        
        [self.client retrievePaymentIntentWithClientSecret:clientSecret completion:^(STPPaymentIntent *pi, NSError *error2) {
            XCTAssertNotNil(pi);
            XCTAssertNil(error2);
            [exp fulfill];
        }];
        
        [self.client retrievePaymentIntentWithClientSecret:clientSecret expand:@[@"metadata"] completion:^(STPPaymentIntent *pi, NSError *error2) {
            XCTAssertNotNil(pi);
            XCTAssertNil(error2);
            [exp2 fulfill];
        }];
    }];
     
    [self waitForExpectationsWithTimeout:TestConstants.STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testConfirmPaymentIntent  {
    XCTestExpectation *exp = [self expectationWithDescription:@"Confirm"];
    XCTestExpectation *exp2 = [self expectationWithDescription:@"Confirm with expansion"];
    STPTestingAPIClient *testClient = [[STPTestingAPIClient alloc] init];
    
    STPPaymentMethodCardParams *card = [[STPPaymentMethodCardParams alloc] init];
    card.number = @"4242424242424242";
    card.expYear = @42;
    card.expMonth = @12;
    card.cvc = @"123";
    
    [testClient createPaymentIntentWithParams:nil completion:^(NSString *clientSecret, NSError *error) {
        XCTAssertNil(error);
        
        STPPaymentIntentParams *params = [[STPPaymentIntentParams alloc] initWithClientSecret:clientSecret];
        params.paymentMethodParams = [STPPaymentMethodParams paramsWithCard:card billingDetails:nil metadata:nil];
        
        [self.client confirmPaymentIntentWithParams:params completion:^(STPPaymentIntent *pi, NSError *error2) {
            XCTAssertNotNil(pi);
            XCTAssertNil(error2);
            [exp fulfill];
        }];
    }];
    
    [testClient createPaymentIntentWithParams:nil completion:^(NSString *clientSecret, NSError *error) {
        XCTAssertNil(error);
        
        STPPaymentIntentParams *params = [[STPPaymentIntentParams alloc] initWithClientSecret:clientSecret];
        params.paymentMethodParams = [STPPaymentMethodParams paramsWithCard:card billingDetails:nil metadata:nil];
        
        [self.client confirmPaymentIntentWithParams:params completion:^(STPPaymentIntent *pi, NSError *error2) {
            XCTAssertNotNil(pi);
            XCTAssertNil(error2);
            [exp2 fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:TestConstants.STPTestingNetworkRequestTimeout handler:nil];
}

// MARK: Setup Intents

- (void)testRetrieveSetupIntent  {
    XCTestExpectation *exp = [self expectationWithDescription:@"Fetch"];
    
    STPTestingAPIClient *testClient = [[STPTestingAPIClient alloc] init];
    [testClient createSetupIntentWithParams:nil completion:^(NSString *clientSecret, NSError *error) {
        XCTAssertNil(error);
        
        [self.client retrieveSetupIntentWithClientSecret:clientSecret completion:^(STPSetupIntent *si, NSError *error2) {
            XCTAssertNotNil(si);
            XCTAssertNil(error2);
            [exp fulfill];
        }];
    }];
     
    [self waitForExpectationsWithTimeout:TestConstants.STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testConfirmSetupIntent  {
    XCTestExpectation *exp = [self expectationWithDescription:@"Confirm"];
    STPTestingAPIClient *testClient = [[STPTestingAPIClient alloc] init];
    
    STPPaymentMethodCardParams *card = [[STPPaymentMethodCardParams alloc] init];
    card.number = @"4242424242424242";
    card.expYear = @42;
    card.expMonth = @12;
    card.cvc = @"123";
    
    [testClient createSetupIntentWithParams:nil completion:^(NSString *clientSecret, NSError *error) {
        XCTAssertNil(error);
        
        STPSetupIntentConfirmParams *params = [[STPSetupIntentConfirmParams alloc] initWithClientSecret:clientSecret];
        params.paymentMethodParams = [STPPaymentMethodParams paramsWithCard:card billingDetails:nil metadata:nil];
        
        [self.client confirmSetupIntentWithParams:params completion:^(STPSetupIntent *si, NSError *error2) {
            XCTAssertNotNil(si);
            XCTAssertNil(error2);
            [exp fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:TestConstants.STPTestingNetworkRequestTimeout handler:nil];
}

// MARK: Payment Methods

- (void)testCreatePaymentMethod  {
    XCTestExpectation *exp = [self expectationWithDescription:@"Create PaymentMethod"];

    STPPaymentMethodCardParams *card = [[STPPaymentMethodCardParams alloc] init];
    card.number = @"4242424242424242";
    card.expYear = @42;
    card.expMonth = @12;
    card.cvc = @"123";
    
    STPPaymentMethodParams *params = [[STPPaymentMethodParams alloc] initWithCard:card billingDetails:nil metadata:nil];
    
    [self.client createPaymentMethodWithParams:params completion:^(STPPaymentMethod *pm, NSError *error) {
        XCTAssertNotNil(pm);
        XCTAssertNil(error);
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:TestConstants.STPTestingNetworkRequestTimeout handler:nil];
}


// MARK: Radar

- (void)testCreateRadarSession  {
    XCTestExpectation *exp = [self expectationWithDescription:@"Create session"];

    [self.client createRadarSessionWithCompletion:^(STPRadarSession *session, NSError *error) {
        XCTAssertNotNil(session);
        XCTAssertNil(error);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:TestConstants.STPTestingNetworkRequestTimeout handler:nil];
}

// MARK: ApplePay

- (void)testCreateApplePayToken  {
    XCTestExpectation *exp = [self expectationWithDescription:@"CreateToken"];
    XCTestExpectation *exp2 = [self expectationWithDescription:@"CreateSource"];
    XCTestExpectation *exp3 = [self expectationWithDescription:@"CreatePM"];
    PKPayment *payment = [STPFixtures applePayPayment];
    [self.client createTokenWithPayment:payment completion:^(STPToken *token, NSError *error) {
        // The certificate used to sign our fake Apple Pay test payment is invalid, which makes sense.
        // Expect an error.
        XCTAssertNil(token);
        XCTAssertNotNil(error);
        [exp fulfill];
    }];
    
    [self.client createSourceWithPayment:payment completion:^(STPSource *source, NSError *error) {
        XCTAssertNil(source);
        XCTAssertNotNil(error);
        [exp2 fulfill];
    }];
    
    [self.client createPaymentMethodWithPayment:payment completion:^(STPPaymentMethod *pm, NSError *error) {
        XCTAssertNil(pm);
        XCTAssertNotNil(error);
        [exp3 fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:TestConstants.STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testPKPaymentError {
    XCTestExpectation *exp = [self expectationWithDescription:@"Upload file"];
    STPCardParams *params = [[STPCardParams alloc] init];
    params.number = @"4242424242424242";
    params.expYear = 20;
    params.expMonth = 12;
    params.cvc = @"123";
    
    [self.client createTokenWithCard:params completion:^(STPToken *token, NSError *error) {
        XCTAssertNil(token);
        XCTAssertNotNil(error);
        XCTAssertNotNil([STPAPIClient pkPaymentErrorForStripeError:error]);

        [exp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:TestConstants.STPTestingNetworkRequestTimeout handler:nil];
}

@end
