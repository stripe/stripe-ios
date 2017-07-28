//
//  NSArray+StripeTest.m
//  Stripe
//
//  Created by Jack Flintermann on 1/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NSArray+Stripe.h"

@interface NSArray_StripeTest : XCTestCase

@end

@implementation NSArray_StripeTest

- (void)test_boundSafeObjectAtIndex_emptyArray {
    NSArray *test = @[];
    XCTAssertNil([test stp_boundSafeObjectAtIndex:5]);
}

- (void)test_boundSafeObjectAtIndex_tooHighIndex {
    NSArray *test = @[@1, @2, @3];
    XCTAssertNil([test stp_boundSafeObjectAtIndex:5]);
}

- (void)test_boundSafeObjectAtIndex_withinBoundsIndex {
    NSArray *test = @[@1, @2, @3];
    XCTAssertEqual([test stp_boundSafeObjectAtIndex:1], @2);
}

- (void)test_arrayByRemovingNulls_removesNullsDeeply {
    NSArray *array = @[
                       @"id",
                       [NSNull null], // null in root
                       @{
                           @"user": @"user_123",
                           @"country": [NSNull null], // null in dictionary
                           @"nicknames": @[
                                   @"john",
                                   @"johnny",
                                   [NSNull null], // null in array in dictionary
                                   ],
                           @"profiles": @{
                                   @"facebook": @"fb_123",
                                   @"twitter": [NSNull null], // null in dictionary in dictionary
                                   }
                           },
                       @[
                           [NSNull null], // null in array
                           @{
                               @"id": @"fee_123",
                               @"frequency": [NSNull null], // null in dictionary in array
                               },
                           @[
                               @"payment",
                               [NSNull null], // null in array in array
                               ],
                           ],
                       ];

    NSArray *expected = @[
                       @"id",
                       @{
                           @"user": @"user_123",
                           @"nicknames": @[
                                   @"john",
                                   @"johnny",
                                   ],
                           @"profiles": @{
                                   @"facebook": @"fb_123",
                                   }
                           },
                       @[
                           @{
                               @"id": @"fee_123",
                               },
                           @[
                               @"payment",
                               ],
                           ],
                       ];

    NSArray *result = [array stp_arrayByRemovingNulls];

    XCTAssertEqualObjects(result, expected);
}

- (void)test_arrayByRemovingNulls_keepsEmptyLeaves {
    NSArray *array = @[[NSNull null]];
    NSArray *result = [array stp_arrayByRemovingNulls];

    XCTAssertEqualObjects(result, @[]);
}

- (void)test_arrayByRemovingNulls_returnsImmutableCopy {
    NSArray *array = @[@"id", @"type"];
    NSArray *result = [array stp_arrayByRemovingNulls];

    XCTAssert(result);
    XCTAssertNotEqual(result, array);
    XCTAssertFalse([result isKindOfClass:[NSMutableArray class]]);
}

@end
