//
//  STPPaymentMethodPaypalParamsTests.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/7/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPAPIClient.h"
#import "STPPaymentMethod.h"
#import "STPPaymentMethodPaypalParams.h"
#import "STPPaymentMethodBillingDetails.h"
#import "STPPaymentMethodParams.h"
#import "STPTestingAPIClient.h"

@interface STPPaymentMethodPaypalParamsTests : XCTestCase

@end

@implementation STPPaymentMethodPaypalParamsTests

- (void)testCreatePaypalPaymentMethod {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    STPPaymentMethodPaypalParams *paypalParams = [STPPaymentMethodPaypalParams new];

    STPPaymentMethodBillingDetails *billingDetails = [STPPaymentMethodBillingDetails new];
    billingDetails.name = @"Jane Doe";

    STPPaymentMethodParams *params = [STPPaymentMethodParams paramsWithPaypal:paypalParams
                                                                   billingDetails:billingDetails
                                                                         metadata:@{@"test_key": @"test_value"}];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Method Paypal create"];

    [client createPaymentMethodWithParams:params
                               completion:^(STPPaymentMethod * _Nullable paymentMethod, NSError * _Nullable error) {
        [expectation fulfill];

        XCTAssertNil(error, @"Unexpected error creating Paypal PaymentMethod: %@", error);
        XCTAssertNotNil(paymentMethod, @"Failed to create Paypal PaymentMethod");
        XCTAssertNotNil(paymentMethod.stripeId, @"Missing stripeId");
        XCTAssertNotNil(paymentMethod.created, @"Missing created");
        XCTAssertFalse(paymentMethod.liveMode, @"Incorrect livemode");
        XCTAssertEqual(paymentMethod.type, STPPaymentMethodTypePaypal, @"Incorrect PaymentMethod type");

        // Billing Details
        XCTAssertEqualObjects(paymentMethod.billingDetails.name, @"Jane Doe", @"Incorrect name");

        // Paypal Details
        XCTAssertNotNil(paymentMethod.paypal, @"Missing Paypal");
    }];

    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

@end
