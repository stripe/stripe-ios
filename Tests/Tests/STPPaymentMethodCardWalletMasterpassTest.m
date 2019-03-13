//
//  STPPaymentMethodCardWalletMasterpassTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPPaymentMethodCardWalletMasterpass.h"
#import "STPFixtures.h"
#import "STPTestUtils.h"

@interface STPPaymentMethodCardWalletMasterpassTest : XCTestCase

@end

@implementation STPPaymentMethodCardWalletMasterpassTest

- (void)testDecodedObjectFromAPIResponseMapping {
    // We reuse the visa checkout JSON because it's identical to the masterpass version
    NSDictionary *response = [STPTestUtils jsonNamed:STPTestJSONPaymentMethod][@"card"][@"wallet"][@"visa_checkout"];
    STPPaymentMethodCardWalletMasterpass *masterpass = [STPPaymentMethodCardWalletMasterpass decodedObjectFromAPIResponse:response];
    XCTAssertNotNil(masterpass);
    XCTAssertEqualObjects(masterpass.name, @"Jenny");
    XCTAssertEqualObjects(masterpass.email, @"jenny@example.com");
    XCTAssertNotNil(masterpass.billingAddress);
    XCTAssertNotNil(masterpass.shippingAddress);
}

@end
