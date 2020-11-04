//
//  STPPaymentMethodGiropayParamsTests.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 4/21/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPTestingAPIClient.h"

@interface STPPaymentMethodGiropayParamsTests : XCTestCase

@end

@implementation STPPaymentMethodGiropayParamsTests

- (void)testCreateGiropayPaymentMethod {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    STPPaymentMethodGiropayParams *giropayParams = [STPPaymentMethodGiropayParams new];

    STPPaymentMethodBillingDetails *billingDetails = [STPPaymentMethodBillingDetails new];
    billingDetails.name = @"Jenny Rosen";

    STPPaymentMethodParams *params = [STPPaymentMethodParams paramsWithGiropay:giropayParams
                                                                billingDetails:billingDetails
                                                                      metadata:@{@"test_key": @"test_value"}];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Method giropay create"];

    [client createPaymentMethodWithParams:params
                               completion:^(STPPaymentMethod * _Nullable paymentMethod, NSError * _Nullable error) {
        [expectation fulfill];

        XCTAssertNil(error, @"Unexpected error creating giropay PaymentMethod: %@", error);
        XCTAssertNotNil(paymentMethod, @"Failed to create giropay PaymentMethod");
        XCTAssertNotNil(paymentMethod.stripeId, @"Missing stripeId");
        XCTAssertNotNil(paymentMethod.created, @"Missing created");
        XCTAssertFalse(paymentMethod.liveMode, @"Incorrect livemode");
        XCTAssertEqual(paymentMethod.type, STPPaymentMethodTypeGiropay, @"Incorrect PaymentMethod type");

        // Billing Details
        XCTAssertEqualObjects(paymentMethod.billingDetails.name, @"Jenny Rosen", @"Incorrect name");

        // giropay Details
        XCTAssertNotNil(paymentMethod.giropay, @"Missing giropay");
    }];

    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

@end
