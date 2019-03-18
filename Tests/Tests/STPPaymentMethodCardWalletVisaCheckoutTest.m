//
//  STPPaymentMethodCardWalletVisaCheckoutTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPPaymentMethodCardWalletVisaCheckout.h"
#import "STPFixtures.h"
#import "STPTestUtils.h"

@interface STPPaymentMethodCardWalletVisaCheckoutTest : XCTestCase

@end

@implementation STPPaymentMethodCardWalletVisaCheckoutTest

- (void)testDecodedObjectFromAPIResponseMapping {
    NSDictionary *response = [STPTestUtils jsonNamed:STPTestJSONPaymentMethod][@"card"][@"wallet"][@"visa_checkout"];
    STPPaymentMethodCardWalletVisaCheckout *visaCheckout = [STPPaymentMethodCardWalletVisaCheckout decodedObjectFromAPIResponse:response];
    XCTAssertNotNil(visaCheckout);
    XCTAssertEqualObjects(visaCheckout.name, @"Jenny");
    XCTAssertEqualObjects(visaCheckout.email, @"jenny@example.com");
    XCTAssertNotNil(visaCheckout.billingAddress);
    XCTAssertNotNil(visaCheckout.shippingAddress);
}

@end
