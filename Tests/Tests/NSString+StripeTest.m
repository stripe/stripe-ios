//
//  NSString+StripeTest.m
//  Stripe
//
//  Created by Ben Guo on 3/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSString+Stripe.h"

@interface NSString_StripeTest : XCTestCase

@end

@implementation NSString_StripeTest

- (void)testSafeSubstringToIndex {
    XCTAssertEqualObjects([@"foo" stp_safeSubstringToIndex:0], @"");
    XCTAssertEqualObjects([@"foo" stp_safeSubstringToIndex:500], @"foo");
    XCTAssertEqualObjects([@"foo" stp_safeSubstringToIndex:1], @"f");
    XCTAssertEqualObjects([@"" stp_safeSubstringToIndex:0], @"");
    XCTAssertEqualObjects([@"" stp_safeSubstringToIndex:1], @"");
}

- (void)testSafeSubstringFromIndex {
    XCTAssertEqualObjects([@"foo" stp_safeSubstringFromIndex:0], @"foo");
    XCTAssertEqualObjects([@"foo" stp_safeSubstringFromIndex:1], @"oo");
    XCTAssertEqualObjects([@"foo" stp_safeSubstringFromIndex:3], @"");
    XCTAssertEqualObjects([@"" stp_safeSubstringFromIndex:0], @"");
    XCTAssertEqualObjects([@"" stp_safeSubstringFromIndex:1], @"");
}

- (void)testReversedString {
    XCTAssertEqualObjects([@"foo" stp_reversedString], @"oof");
    XCTAssertEqualObjects([@"12345" stp_reversedString], @"54321");
    XCTAssertEqualObjects([@"" stp_reversedString], @"");
}

@end
