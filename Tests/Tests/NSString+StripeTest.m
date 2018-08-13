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

- (void)testStringByRemovingSuffix {
    XCTAssertEqualObjects([@"foobar" stp_stringByRemovingSuffix:@"bar"], @"foo");
    XCTAssertEqualObjects([@"foobar" stp_stringByRemovingSuffix:@"baz"], @"foobar");
    XCTAssertEqualObjects([@"foobar" stp_stringByRemovingSuffix:nil], @"foobar");
    XCTAssertEqualObjects([@"foobar" stp_stringByRemovingSuffix:@"foobar"], @"");
    XCTAssertEqualObjects([@"foobar" stp_stringByRemovingSuffix:@""], @"foobar");
    XCTAssertEqualObjects([@"foobar" stp_stringByRemovingSuffix:@"oba"], @"foobar");

    XCTAssertEqualObjects([@"foobar☺¿" stp_stringByRemovingSuffix:@"bar☺¿"], @"foo");
    XCTAssertEqualObjects([@"foobar☺¿" stp_stringByRemovingSuffix:@"bar¿"], @"foobar☺¿");

    XCTAssertEqualObjects([@"foobar\u202C" stp_stringByRemovingSuffix:@"bar"], @"foobar\u202C");
    XCTAssertEqualObjects([@"foobar\u202C" stp_stringByRemovingSuffix:@"bar\u202C"], @"foo");

    // e + \u0041 => é
    XCTAssertEqualObjects([@"foobare\u0301" stp_stringByRemovingSuffix:@"bare"], @"foobare\u0301");
    XCTAssertEqualObjects([@"foobare\u0301" stp_stringByRemovingSuffix:@"bare\u0301"], @"foo");
    XCTAssertEqualObjects([@"foobare" stp_stringByRemovingSuffix:@"bare\u0301"], @"foobare");

}

@end
