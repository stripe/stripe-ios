//
//  STPPaymentMethodSofortParamsTests.m
//  StripeiOS Tests
//
//  Created by David Estes on 8/7/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPTestingAPIClient.h"

@interface STPPaymentMethodSofortParamsTests : XCTestCase

@end

@implementation STPPaymentMethodSofortParamsTests

- (void)testCreateSofortPaymentMethod {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    STPPaymentMethodSofortParams *sofortParams = [STPPaymentMethodSofortParams new];
    sofortParams.country = @"DE";
    STPPaymentMethodBillingDetails *billingDetails = [STPPaymentMethodBillingDetails new];
    billingDetails.name = @"Jenny Rosen";

    STPPaymentMethodParams *params = [STPPaymentMethodParams paramsWithSofort:sofortParams
                                                                billingDetails:billingDetails
                                                                      metadata:@{@"test_key": @"test_value"}];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Method Sofort create"];

    [client createPaymentMethodWithParams:params
                               completion:^(STPPaymentMethod * _Nullable paymentMethod, NSError * _Nullable error) {
        [expectation fulfill];

        XCTAssertNil(error, @"Unexpected error creating Sofort PaymentMethod: %@", error);
        XCTAssertNotNil(paymentMethod, @"Failed to create Sofort PaymentMethod");
        XCTAssertNotNil(paymentMethod.stripeId, @"Missing stripeId");
        XCTAssertNotNil(paymentMethod.created, @"Missing created");
        XCTAssertFalse(paymentMethod.liveMode, @"Incorrect livemode");
        XCTAssertEqual(paymentMethod.type, STPPaymentMethodTypeSofort, @"Incorrect PaymentMethod type");

        // Billing Details
        XCTAssertEqualObjects(paymentMethod.billingDetails.name, @"Jenny Rosen", @"Incorrect name");

        // Sofort Details
        XCTAssertNotNil(paymentMethod.sofort, @"Missing Sofort");
        XCTAssertEqualObjects(paymentMethod.sofort.country, @"DE", @"Incorrect country");
    }];

    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

@end
