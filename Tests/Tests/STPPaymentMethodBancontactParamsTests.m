//
//  STPPaymentMethodBancontactParamsTests.m
//  StripeiOS Tests
//
//  Created by Vineet Shah on 4/29/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPTestingAPIClient.h"

@interface STPPaymentMethodBancontactParamsTests : XCTestCase

@end

@implementation STPPaymentMethodBancontactParamsTests

- (void)testCreateBancontactPaymentMethod {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    STPPaymentMethodBancontactParams *bancontactParams = [STPPaymentMethodBancontactParams new];

    STPPaymentMethodBillingDetails *billingDetails = [STPPaymentMethodBillingDetails new];
    billingDetails.name = @"Jane Doe";

    STPPaymentMethodParams *params = [STPPaymentMethodParams paramsWithBancontact:bancontactParams
                                                                   billingDetails:billingDetails
                                                                         metadata:@{@"test_key": @"test_value"}];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Method Bancontact create"];

    [client createPaymentMethodWithParams:params
                               completion:^(STPPaymentMethod * _Nullable paymentMethod, NSError * _Nullable error) {
        [expectation fulfill];

        XCTAssertNil(error, @"Unexpected error creating Bancontact PaymentMethod: %@", error);
        XCTAssertNotNil(paymentMethod, @"Failed to create Bancontact PaymentMethod");
        XCTAssertNotNil(paymentMethod.stripeId, @"Missing stripeId");
        XCTAssertNotNil(paymentMethod.created, @"Missing created");
        XCTAssertFalse(paymentMethod.liveMode, @"Incorrect livemode");
        XCTAssertEqual(paymentMethod.type, STPPaymentMethodTypeBancontact, @"Incorrect PaymentMethod type");

        // Billing Details
        XCTAssertEqualObjects(paymentMethod.billingDetails.name, @"Jane Doe", @"Incorrect name");

        // Bancontact Details
        XCTAssertNotNil(paymentMethod.bancontact, @"Missing Bancontact");
    }];

    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

@end
