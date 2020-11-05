//
//  STPPaymentMethodAUBECSDebitParamsTests.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 3/4/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPTestingAPIClient.h"

@interface STPPaymentMethodAUBECSDebitParamsTests : XCTestCase

@end

@implementation STPPaymentMethodAUBECSDebitParamsTests

- (void)testCreateAUBECSPaymentMethod {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingAUPublishableKey];
    STPPaymentMethodAUBECSDebitParams *becsParams = [STPPaymentMethodAUBECSDebitParams new];
    becsParams.bsbNumber = @"000000"; // Stripe test bank
    becsParams.accountNumber = @"000123456"; // test account

    STPPaymentMethodBillingDetails *billingDetails = [STPPaymentMethodBillingDetails new];
    billingDetails.name = @"Jenny Rosen";
    billingDetails.email = @"jrosen@example.com";

    STPPaymentMethodParams *params = [STPPaymentMethodParams paramsWithAUBECSDebit:becsParams
                                                                    billingDetails:billingDetails
                                                                          metadata:@{@"test_key": @"test_value"}];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Method AU BECS Debit create"];

    [client createPaymentMethodWithParams:params
                               completion:^(STPPaymentMethod * _Nullable paymentMethod, NSError * _Nullable error) {
        [expectation fulfill];

        XCTAssertNil(error, @"Unexpected error creating AU BECS Debit PaymentMethod: %@", error);
        XCTAssertNotNil(paymentMethod, @"Failed to create AU BECS Debit PaymentMethod");
        XCTAssertNotNil(paymentMethod.stripeId, @"Missing stripeId");
        XCTAssertNotNil(paymentMethod.created, @"Missing created");
        XCTAssertFalse(paymentMethod.liveMode, @"Incorrect livemode");
        XCTAssertEqual(paymentMethod.type, STPPaymentMethodTypeAUBECSDebit, @"Incorrect PaymentMethod type");
        
        // Billing Details
        XCTAssertEqualObjects(paymentMethod.billingDetails.email, @"jrosen@example.com", @"Incorrect email");
        XCTAssertEqualObjects(paymentMethod.billingDetails.name, @"Jenny Rosen", @"Incorrect name");

        // AU BECS Debit
        XCTAssertEqualObjects(paymentMethod.auBECSDebit.bsbNumber, @"000000", @"Incorrect BSB Number");
        XCTAssertEqualObjects(paymentMethod.auBECSDebit.last4, @"3456", @"Incorrect last4");
        XCTAssertNotNil(paymentMethod.auBECSDebit.fingerprint, @"Missing fingerprint");
    }];

    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

@end
