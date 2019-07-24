//
//  NSURLComponents_StripeTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 5/24/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSURLComponents+Stripe.h"

@interface NSURLComponents_StripeTest : XCTestCase

@end

@implementation NSURLComponents_StripeTest

- (void)testCaseInsensitiveSchemeComparison {
    NSURLComponents *lhs = [NSURLComponents componentsWithString:@"com.bar.foo://host"];
    NSURLComponents *rhs = [NSURLComponents componentsWithString:@"COM.BAR.FOO://HOST"];
    XCTAssert([lhs stp_matchesURLComponents:lhs]); // sanity
    XCTAssert([lhs stp_matchesURLComponents:rhs]);
    XCTAssert([rhs stp_matchesURLComponents:lhs]);
}

- (void)testMatchesURLsWithQueryString {
    // e.g. STPSourceFunctionalTest passes "https://shop.example.com/crtABC" for the return_url,
    // but the Source object returned by the API comes has "https://shop.example.com/crtABC?redirect_merchant_name=xctest"
    NSURLComponents *expectedComponents = [[NSURLComponents alloc] initWithString:@"https://shop.example.com/crtABC?redirect_merchant_name=xctest"];
    NSURLComponents *components = [[NSURLComponents alloc] initWithString:@"https://shop.example.com/crtABC"];
    XCTAssertTrue([components stp_matchesURLComponents:expectedComponents]);
}

@end
