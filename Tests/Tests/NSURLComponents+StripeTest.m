//
//  NSURLComponents+StripeTest.m
//  Stripe
//
//  Created by Brian Dorfman on 1/26/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NSURLComponents+Stripe.h"

@interface NSURLComponents_StripeTest : XCTestCase

@end

@implementation NSURLComponents_StripeTest


- (void)testMatchesURLComponents {
    NSURLComponents *componentsToMatchAgainst = [NSURLComponents componentsWithString:@"test://foo?one=1"];


    XCTAssertTrue([componentsToMatchAgainst stp_matchesURLComponents:[NSURLComponents componentsWithString:@"test://foo?one=1"]]);
    XCTAssertTrue([componentsToMatchAgainst stp_matchesURLComponents:[NSURLComponents componentsWithString:@"test://foo?one=1&two=2"]]);
    XCTAssertTrue([componentsToMatchAgainst stp_matchesURLComponents:[NSURLComponents componentsWithString:@"test://foo?two=2&one=1"]]);
    XCTAssertFalse([componentsToMatchAgainst stp_matchesURLComponents:[NSURLComponents componentsWithString:@"test://foo"]]);
    XCTAssertFalse([componentsToMatchAgainst stp_matchesURLComponents:[NSURLComponents componentsWithString:@"test://foo?one=one"]]);
    XCTAssertFalse([componentsToMatchAgainst stp_matchesURLComponents:[NSURLComponents componentsWithString:@"test://bar?one=1"]]);
    XCTAssertFalse([componentsToMatchAgainst stp_matchesURLComponents:[NSURLComponents componentsWithString:@"foo://foo?one=1"]]);


    componentsToMatchAgainst = [NSURLComponents componentsWithString:@"test://"];
    XCTAssertTrue([componentsToMatchAgainst stp_matchesURLComponents:[NSURLComponents componentsWithString:@"test://"]]);
    XCTAssertTrue([componentsToMatchAgainst stp_matchesURLComponents:[NSURLComponents componentsWithString:@"test://?one=1"]]);
}

- (void)testSetQueryItemsDictionary {

    NSURLComponents *components = [NSURLComponents componentsWithString:@"test://foo"];
    components.stp_queryItemsDictionary = @{@"one": @"1",
                                            @"two": @"dos",
                                            };

    // Order is not deterministic so can't just check the final string

    BOOL foundOne = NO;
    BOOL foundTwo = NO;

    XCTAssertTrue((components.queryItems.count == 2));
    for (NSURLQueryItem *item in components.queryItems) {
        if ([item.name isEqualToString:@"one"]) {
            foundOne = YES;
            XCTAssertEqualObjects(@"1", item.value);
        }
        else if ([item.name isEqualToString:@"two"]) {
            foundTwo = YES;
            XCTAssertEqualObjects(@"dos", item.value);
        }
    }

    XCTAssertTrue((foundOne && foundTwo));
}

- (void)testGetQueryItemsDictionary {
    NSURLComponents *components = [NSURLComponents componentsWithString:@"test://foo?one=1&two=dos"];
    NSDictionary *queryitems = components.stp_queryItemsDictionary;

    XCTAssertEqualObjects(queryitems[@"one"], @"1");
    XCTAssertEqualObjects(queryitems[@"two"], @"dos");
    XCTAssertTrue((queryitems.count == 2));
}

@end
