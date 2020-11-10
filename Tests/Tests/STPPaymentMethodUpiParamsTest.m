//
//  STPPaymentMethodUpiParamsTest.m
//  StripeiOS Tests
//
//  Created by Anirudh Bhargava on 11/6/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPTestingAPIClient.h"

@interface STPPaymentMethodUpiParamsTests : XCTestCase

@end

@implementation STPPaymentMethodUpiParamsTests

- (void)testCreateUpiPaymentMethod {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingINPublishableKey];
    STPPaymentMethodUpiParams *upiParams = [STPPaymentMethodUpiParams new];
    upiParams.vpa = @"somevpa@hdfcbank";
    STPPaymentMethodBillingDetails *billingDetails = [STPPaymentMethodBillingDetails new];
    billingDetails.name = @"Jenny Rosen";

    STPPaymentMethodParams *params = [STPPaymentMethodParams paramsWithUpi:upiParams
                                                                billingDetails:billingDetails
                                                                      metadata:@{@"test_key": @"test_value"}];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Method Upi create"];

    [client createPaymentMethodWithParams:params
                               completion:^(STPPaymentMethod * _Nullable paymentMethod, NSError * _Nullable error) {
        [expectation fulfill];

        XCTAssertNil(error, @"Unexpected error creating Upi PaymentMethod: %@", error);
        XCTAssertNotNil(paymentMethod, @"Failed to create Upi PaymentMethod");
        XCTAssertNotNil(paymentMethod.stripeId, @"Missing stripeId");
        XCTAssertNotNil(paymentMethod.created, @"Missing created");
        XCTAssertFalse(paymentMethod.liveMode, @"Incorrect livemode");
        XCTAssertEqual(paymentMethod.type, STPPaymentMethodTypeUpi, @"Incorrect PaymentMethod type");

        // Billing Details
        XCTAssertEqualObjects(paymentMethod.billingDetails.name, @"Jenny Rosen", @"Incorrect name");

        // Upi Details
        XCTAssertNotNil(paymentMethod.upi, @"Missing Upi");
        XCTAssertEqualObjects(paymentMethod.upi.vpa, @"somevpa@hdfcbank", @"Incorrect vpa");
    }];

    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

@end
