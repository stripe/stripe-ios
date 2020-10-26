//
//  STPPaymentMethodEPSParamsTests.m
//  StripeiOS Tests
//
//  Created by Shengwei Wu on 5/15/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>


#import "STPTestingAPIClient.h"

@interface STPPaymentMethodEPSParamsTests : XCTestCase

@end

@implementation STPPaymentMethodEPSParamsTests

- (void)testCreateEPSPaymentMethod {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    STPPaymentMethodEPSParams *epsParams = [STPPaymentMethodEPSParams new];

    STPPaymentMethodBillingDetails *billingDetails = [STPPaymentMethodBillingDetails new];
    billingDetails.name = @"Jenny Rosen";

    STPPaymentMethodParams *params = [STPPaymentMethodParams paramsWithEPS:epsParams
                                                                billingDetails:billingDetails
                                                                      metadata:@{@"test_key": @"test_value"}];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Method EPS create"];

    [client createPaymentMethodWithParams:params
                               completion:^(STPPaymentMethod * _Nullable paymentMethod, NSError * _Nullable error) {
        [expectation fulfill];

        XCTAssertNil(error, @"Unexpected error creating EPS PaymentMethod: %@", error);
        XCTAssertNotNil(paymentMethod, @"Failed to create EPS PaymentMethod");
        XCTAssertNotNil(paymentMethod.stripeId, @"Missing stripeId");
        XCTAssertNotNil(paymentMethod.created, @"Missing created");
        XCTAssertFalse(paymentMethod.liveMode, @"Incorrect livemode");
        XCTAssertEqual(paymentMethod.type, STPPaymentMethodTypeEPS, @"Incorrect PaymentMethod type");

        // Billing Details
        XCTAssertEqualObjects(paymentMethod.billingDetails.name, @"Jenny Rosen", @"Incorrect name");

        // EPS Details
        XCTAssertNotNil(paymentMethod.eps, @"Missing eps");
    }];

    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

@end
