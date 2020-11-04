//
//  STPPaymentMethodOXXOParamsTests.m
//  StripeiOS Tests
//
//  Created by Polo Li on 6/16/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPTestingAPIClient.h"

@interface STPPaymentMethodOXXOParamsTests : XCTestCase

@end

@implementation STPPaymentMethodOXXOParamsTests

- (void)testCreateOXXOPaymentMethod {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    STPPaymentMethodOXXOParams *oxxoParams = [STPPaymentMethodOXXOParams new];

    STPPaymentMethodBillingDetails *billingDetails = [STPPaymentMethodBillingDetails new];
    billingDetails.name = @"Jane Doe";
    billingDetails.email = @"test@test.com";

    STPPaymentMethodParams *params = [STPPaymentMethodParams paramsWithOXXO:oxxoParams
                                                             billingDetails:billingDetails
                                                                   metadata:@{@"test_key": @"test_value"}];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Method OXXO create"];

    [client createPaymentMethodWithParams:params
                               completion:^(STPPaymentMethod * _Nullable paymentMethod, NSError * _Nullable error) {
        [expectation fulfill];

        XCTAssertNil(error, @"Unexpected error creating OXXO PaymentMethod: %@", error);
        XCTAssertNotNil(paymentMethod, @"Failed to create OXXO PaymentMethod");
        XCTAssertNotNil(paymentMethod.stripeId, @"Missing stripeId");
        XCTAssertNotNil(paymentMethod.created, @"Missing created");
        XCTAssertFalse(paymentMethod.liveMode, @"Incorrect livemode");
        XCTAssertEqual(paymentMethod.type, STPPaymentMethodTypeOXXO, @"Incorrect PaymentMethod type");

        // Billing Details
        XCTAssertEqualObjects(paymentMethod.billingDetails.name, @"Jane Doe", @"Incorrect name");
        XCTAssertEqualObjects(paymentMethod.billingDetails.email, @"test@test.com", @"Incorrect email");

        // OXXO Details
        XCTAssertNotNil(paymentMethod.oxxo, @"Missing OXXO");
    }];

    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

@end
