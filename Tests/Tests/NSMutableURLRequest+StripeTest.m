//
//  NSMutableURLRequest+StripeTest.m
//  Stripe
//
//  Created by Ben Guo on 4/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSMutableURLRequest+Stripe.h"

@interface NSMutableURLRequest_StripeTest : XCTestCase

@end

@implementation NSMutableURLRequest_StripeTest

- (void)testAddParametersToURL_noQuery {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://example.com"]];
    [request stp_addParametersToURL:@{@"foo": @"bar"}];

    XCTAssertEqualObjects(request.URL.absoluteString, @"https://example.com?foo=bar");
}

- (void)testAddParametersToURL_hasQuery {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://example.com?a=b"]];
    [request stp_addParametersToURL:@{@"foo": @"bar"}];

    XCTAssertEqualObjects(request.URL.absoluteString, @"https://example.com?a=b&foo=bar");
}

@end
