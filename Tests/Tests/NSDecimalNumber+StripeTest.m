//
//  NSDecimalNumber+StripeTest.m
//  Stripe
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSDecimalNumber+Stripe_Currency.h"

@interface NSDecimalNumberStripeTest : XCTestCase

@end

@implementation NSDecimalNumberStripeTest

- (void)testDecimalAmount_hasDecimal {
    NSDecimalNumber *decimalNumber = [NSDecimalNumber stp_decimalNumberWithAmount:1000 currency:@"usd"];
    XCTAssertEqualObjects(decimalNumber, [NSDecimalNumber decimalNumberWithString:@"10.00"]);
}

- (void)testDecimalAmount_noDecimal {
    NSDecimalNumber *decimalNumber = [NSDecimalNumber stp_decimalNumberWithAmount:1000 currency:@"jpy"];
    XCTAssertEqualObjects(decimalNumber, [NSDecimalNumber decimalNumberWithString:@"1000"]);
}


@end
