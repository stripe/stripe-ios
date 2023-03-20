//
//  STPPaymentMethodUPIParamsTest.m
//  StripeiOS Tests
//
//  Created by Anirudh Bhargava on 11/6/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
@import StripeCoreTestUtils;
#import "STPTestingAPIClient.h"

@interface STPPaymentMethodUPIParamsTests : XCTestCase

@end

@implementation STPPaymentMethodUPIParamsTests

- (void)testCreateUPIPaymentMethod {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingINPublishableKey];
    STPPaymentMethodUPIParams *upiParams = [STPPaymentMethodUPIParams new];
    upiParams.vpa = @"somevpa@hdfcbank";
    STPPaymentMethodBillingDetails *billingDetails = [STPPaymentMethodBillingDetails new];
    billingDetails.name = @"Jenny Rosen";

    STPPaymentMethodParams *params = [STPPaymentMethodParams paramsWithUPI:upiParams
                                                                billingDetails:billingDetails
                                                                      metadata:@{@"test_key": @"test_value"}];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Method UPI create"];

    [client createPaymentMethodWithParams:params
                               completion:^(STPPaymentMethod * _Nullable paymentMethod, NSError * _Nullable error) {
        [expectation fulfill];

        XCTAssertNil(error, @"Unexpected error creating UPI PaymentMethod: %@", error);
        XCTAssertNotNil(paymentMethod, @"Failed to create UPI PaymentMethod");
        XCTAssertNotNil(paymentMethod.stripeId, @"Missing stripeId");
        XCTAssertNotNil(paymentMethod.created, @"Missing created");
        XCTAssertFalse(paymentMethod.liveMode, @"Incorrect livemode");
        XCTAssertEqual(paymentMethod.type, STPPaymentMethodTypeUPI, @"Incorrect PaymentMethod type");

        // Billing Details
        XCTAssertEqualObjects(paymentMethod.billingDetails.name, @"Jenny Rosen", @"Incorrect name");

        // UPI Details
        XCTAssertNotNil(paymentMethod.upi, @"Missing UPI");
        XCTAssertEqualObjects(paymentMethod.upi.vpa, @"somevpa@hdfcbank", @"Incorrect vpa");
    }];

    [self waitForExpectationsWithTimeout:TestConstants.STPTestingNetworkRequestTimeout handler:nil];
}

@end
