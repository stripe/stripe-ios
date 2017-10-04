//
//  NSDictionary+StripeTest.m
//  Stripe
//
//  Created by Joey Dong on 7/24/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NSDictionary+Stripe.h"

@interface NSDictionary_StripeTest : XCTestCase

@end

@implementation NSDictionary_StripeTest

#pragma mark - dictionaryByRemovingNullsValidatingRequiredFields

- (void)test_dictionaryByRemovingNullsValidatingRequiredFields_removesNullsDeeply {
    NSDictionary *dictionary = @{
                                 @"id": @"card_123",
                                 @"tokenization_method": [NSNull null], // null in root
                                 @"metadata": @{
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
                                 @"fees": @[
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
                                 };

    NSDictionary *expected = @{
                               @"id": @"card_123",
                               @"metadata": @{
                                       @"user": @"user_123",
                                       @"nicknames": @[
                                               @"john",
                                               @"johnny",
                                               ],
                                       @"profiles": @{
                                               @"facebook": @"fb_123",
                                               },
                                       },
                               @"fees": @[
                                       @{
                                           @"id": @"fee_123",
                                           },
                                       @[
                                           @"payment",
                                           ],
                                       ],
                               };

    NSDictionary *result = [dictionary stp_dictionaryByRemovingNullsValidatingRequiredFields:@[]];

    XCTAssertEqualObjects(result, expected);
}

- (void)test_dictionaryByRemovingNullsValidatingRequiredFields_keepsEmptyLeaves {
    NSDictionary *dictionary = @{@"id": [NSNull null]};
    NSDictionary *result = [dictionary stp_dictionaryByRemovingNullsValidatingRequiredFields:@[]];

    XCTAssertEqualObjects(result, @{});
}

- (void)test_dictionaryByRemovingNullsValidatingRequiredFields_returnsImmutableCopy {
    NSDictionary *dictionary = @{@"id": @"card_123"};
    NSDictionary *result = [dictionary stp_dictionaryByRemovingNullsValidatingRequiredFields:@[]];

    XCTAssert(result);
    XCTAssertNotEqual(result, dictionary);
    XCTAssertFalse([result isKindOfClass:[NSMutableDictionary class]]);
}

- (void)test_dictionaryByRemovingNullsValidatingRequiredFields_missingRequiredFieldReturnsNil {
    NSDictionary *dictionary = @{
                                 @"id": @"card_123",
                                 @"metadata": @{
                                         @"user": @"user_123",
                                         },
                                 };

    NSArray *requiredFields = @[@"id", @"object"];

    XCTAssertNil([dictionary stp_dictionaryByRemovingNullsValidatingRequiredFields:requiredFields]);
}

#pragma mark - dictionaryByRemovingNonStrings

- (void)test_dictionaryByRemovingNonStrings_basicCases {
    NSDictionary *dictionary;
    NSDictionary *expected;
    NSDictionary *result;

    // Empty dictionary
    dictionary = @{};
    expected = @{};
    result = [dictionary stp_dictionaryByRemovingNonStrings];
    XCTAssertEqualObjects(result, expected);

    // Regular case
    dictionary = @{
                   @"user": @"user_123",
                   @"nicknames": @"John, Johnny",
                   };
    expected = @{
                 @"user": @"user_123",
                 @"nicknames": @"John, Johnny",
                 };
    result = [dictionary stp_dictionaryByRemovingNonStrings];
    XCTAssertEqualObjects(result, expected);

    // Strips non-NSString keys and values
    dictionary = @{
                   @"user": @"user_123",
                   @"nicknames": @"John, Johnny",
                   @"profiles": [NSNull null],
                   [NSNull null]: @"San Francisco, CA",
                   [NSNull null]: [NSNull null],
                   @"age": @(21),
                   @(21): @"age",
                   @(21): @(21),
                   @"fees": @{
                           @"plan": @"monthly",
                           },
                   @"visits": @[
                           @"january",
                           @"february",
                           ],
                   };
    expected = @{
                 @"user": @"user_123",
                 @"nicknames": @"John, Johnny",
                 };
    result = [dictionary stp_dictionaryByRemovingNonStrings];
    XCTAssertEqualObjects(result, expected);
}

- (void)test_dictionaryByRemovingNonStrings_returnsImmutableCopy {
    NSDictionary *dictionary = @{@"user": @"user_123"};
    NSDictionary *result = [dictionary stp_dictionaryByRemovingNonStrings];

    XCTAssert(result);
    XCTAssertNotEqual(result, dictionary);
    XCTAssertFalse([result isKindOfClass:[NSMutableDictionary class]]);
}

@end
