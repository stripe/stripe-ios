//
//  STPErrorBridgeTest.m
//  StripeiOS Tests
//
//  Created by David Estes on 9/23/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@import Stripe;
@import XCTest;
@import PassKit;
@import StripePaymentsObjcTestUtils;

@interface STPErrorBridgeTest : XCTestCase

@end

@implementation STPErrorBridgeTest

- (void)testCollectUSBankAccountParamsAddressSelector {
    STPPaymentMethodAddress *address = [[STPPaymentMethodAddress alloc] init];
    address.line1 = @"123 Main Street";
    address.city = @"Test City";
    address.state = @"TS";
    address.postalCode = @"12345";
    address.country = @"US";

    STPCollectBankAccountParams *params = [STPCollectBankAccountParams
                                           collectUSBankAccountParamsWithName:@"Test Customer"
                                           email:@"customer@example.com"
                                           address:address];

    XCTAssertNotNil(params);
}

- (void)testSTPErrorBridge {
    // Grab a constant from each class, just to make sure we didn't forget to include the bridge:
    XCTAssertEqual(STPInvalidRequestError, 50);
    XCTAssertEqualObjects(STPError.errorMessageKey, @"com.stripe.lib:ErrorMessageKey");
    NSDictionary *json = @{
        @"error": @{
            @"type": @"invalid_request_error",
            @"message": @"Your card number is incorrect.",
            @"code": @"incorrect_number"
        }
    };
    
    // Make sure we can parse a Stripe response
    NSError *expectedError = [NSError stp_errorFromStripeResponse:json];
    XCTAssertEqualObjects(expectedError.domain, STPError.stripeDomain);
}

@end
