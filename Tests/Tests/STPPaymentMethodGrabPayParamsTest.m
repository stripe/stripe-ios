//
//  STPPaymentMethodGrabPayParamsTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 7/21/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPTestingAPIClient.h"

@interface STPPaymentMethodGrabPayParamsTest : XCTestCase

@end

@implementation STPPaymentMethodGrabPayParamsTest


- (void)testCreateGrabPayPaymentMethod {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingSGPublishableKey];
    STPPaymentMethodGrabPayParams *grabPayParams = [STPPaymentMethodGrabPayParams new];
    
    STPPaymentMethodBillingDetails *billingDetails = [STPPaymentMethodBillingDetails new];
    billingDetails.name = @"Jenny Rosen";
    
    STPPaymentMethodParams *params = [STPPaymentMethodParams paramsWithGrabPay:grabPayParams
                                                                billingDetails:billingDetails
                                                                      metadata:@{@"test_key": @"test_value"}];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Payment Method GrabPay create"];
    
    [client createPaymentMethodWithParams:params
                               completion:^(STPPaymentMethod * _Nullable paymentMethod, NSError * _Nullable error) {
        [expectation fulfill];
        
        XCTAssertNil(error, @"Unexpected error creating GrabPay PaymentMethod: %@", error);
        XCTAssertNotNil(paymentMethod, @"Failed to create GrabPay PaymentMethod");
        XCTAssertNotNil(paymentMethod.stripeId, @"Missing stripeId");
        XCTAssertNotNil(paymentMethod.created, @"Missing created");
        XCTAssertFalse(paymentMethod.liveMode, @"Incorrect livemode");
        XCTAssertEqual(paymentMethod.type, STPPaymentMethodTypeGrabPay, @"Incorrect PaymentMethod type");
        
        // Billing Details
        XCTAssertEqualObjects(paymentMethod.billingDetails.name, @"Jenny Rosen", @"Incorrect name");
        
        // GrabPay Details
        XCTAssertNotNil(paymentMethod.grabPay, @"Missing grabPay");
    }];
    
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

@end
