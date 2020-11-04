//
//  STPPaymentMethodPayPalParamsTests.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/7/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPTestingAPIClient.h"

@interface STPPaymentMethodPayPalParamsTests : XCTestCase

@end

@implementation STPPaymentMethodPayPalParamsTests

- (void)testCreatePayPalPaymentMethod {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    STPPaymentMethodPayPalParams *payPalParams = [STPPaymentMethodPayPalParams new];

    STPPaymentMethodBillingDetails *billingDetails = [STPPaymentMethodBillingDetails new];
    billingDetails.name = @"Jane Doe";

    STPPaymentMethodParams *params = [STPPaymentMethodParams paramsWithPayPal:payPalParams
                                                                   billingDetails:billingDetails
                                                                         metadata:@{@"test_key": @"test_value"}];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Method PayPal create"];

    [client createPaymentMethodWithParams:params
                               completion:^(STPPaymentMethod * _Nullable paymentMethod, NSError * _Nullable error) {
        [expectation fulfill];

        XCTAssertNil(error, @"Unexpected error creating PayPal PaymentMethod: %@", error);
        XCTAssertNotNil(paymentMethod, @"Failed to create PayPal PaymentMethod");
        XCTAssertNotNil(paymentMethod.stripeId, @"Missing stripeId");
        XCTAssertNotNil(paymentMethod.created, @"Missing created");
        XCTAssertFalse(paymentMethod.liveMode, @"Incorrect livemode");
        XCTAssertEqual(paymentMethod.type, STPPaymentMethodTypePayPal, @"Incorrect PaymentMethod type");

        // Billing Details
        XCTAssertEqualObjects(paymentMethod.billingDetails.name, @"Jane Doe", @"Incorrect name");

        // PayPal Details
        XCTAssertNotNil(paymentMethod.payPal, @"Missing PayPal");
    }];

    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

@end
