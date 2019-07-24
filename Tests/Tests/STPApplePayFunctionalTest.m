//
//  STPApplePayTest.m
//  Stripe
//
//  Created by Jack Flintermann on 12/21/14.
//  Copyright (c) 2014 Stripe, Inc. All rights reserved.
//

@import XCTest;
@import PassKit;

#import "STPAPIClient.h"
#import "STPAPIClient+ApplePay.h"
#import "STPNetworkStubbingTestCase.h"
#import "STPFixtures.h"

@interface STPApplePayFunctionalTest : STPNetworkStubbingTestCase

@end

@implementation STPApplePayFunctionalTest

- (void)setUp {
//    self.recordingMode = YES;
    [super setUp];
}

// TODO: regenerate these fixtures with a fresh/real PKPayment
- (void)testCreateTokenWithPayment {
    PKPayment *payment = [STPFixtures applePayPayment];
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_vOo1umqsYxSrP5UXfOeL3ecm"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Apple pay token creation"];
    [client createTokenWithPayment:payment
                        completion:^(STPToken *token, NSError *error) {
                            [expectation fulfill];
                            XCTAssertNil(token, @"token should be nil");
                            XCTAssertNotNil(error, @"error should not be nil");

                            // Since we can't actually generate a new cryptogram in a CI environment, we should just post a blob of expired token data and
                            // make sure we get the "too long since tokenization" error. This at least asserts that our blob has been correctly formatted and
                            // can be decrypted by the backend.
                            XCTAssert([error.localizedDescription rangeOfString:@"too long"].location != NSNotFound,
                                      @"Error is unrelated to 24-hour expiry: %@",
                                      error.localizedDescription);
                        }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testCreateSourceWithPayment {
    PKPayment *payment = [STPFixtures applePayPayment];
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_vOo1umqsYxSrP5UXfOeL3ecm"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Apple pay source creation"];
    [client createSourceWithPayment:payment
                        completion:^(STPSource *source, NSError *error) {
                            [expectation fulfill];
                            XCTAssertNil(source, @"token should be nil");
                            XCTAssertNotNil(error, @"error should not be nil");

                            // Since we can't actually generate a new cryptogram in a CI environment, we should just post a blob of expired token data and
                            // make sure we get the "too long since tokenization" error. This at least asserts that our blob has been correctly formatted and
                            // can be decrypted by the backend.
                            XCTAssert([error.localizedDescription rangeOfString:@"too long"].location != NSNotFound,
                                      @"Error is unrelated to 24-hour expiry: %@",
                                      error.localizedDescription);
                        }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

@end
