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

- (void)test_dictionaryByRemovingNulls_removesNullsDeeply {
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

    NSDictionary *result = [dictionary stp_dictionaryByRemovingNulls];

    XCTAssertEqualObjects(result, expected);
}

- (void)test_dictionaryByRemovingNullsValidatingRequiredFields_keepsEmptyLeaves {
    NSDictionary *dictionary = @{@"id": [NSNull null]};
    NSDictionary *result = [dictionary stp_dictionaryByRemovingNulls];

    XCTAssertEqualObjects(result, @{});
}

- (void)test_dictionaryByRemovingNullsValidatingRequiredFields_returnsImmutableCopy {
    NSDictionary *dictionary = @{@"id": @"card_123"};
    NSDictionary *result = [dictionary stp_dictionaryByRemovingNulls];

    XCTAssert(result);
    XCTAssertNotEqual(result, dictionary);
    XCTAssertFalse([result isKindOfClass:[NSMutableDictionary class]]);
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

#pragma mark - Getters

- (void)testArrayForKey {
    NSDictionary *dict = @{
                           @"a": @[@"foo"],
                           };

    XCTAssertEqualObjects([dict stp_arrayForKey:@"a"], @[@"foo"]);
    XCTAssertNil([dict stp_arrayForKey:@"b"]);
}

- (void)testBoolForKey {
    NSDictionary *dict = @{
                           @"a": @1,
                           @"b": @0,
                           @"c": @"true",
                           @"d": @"false",
                           @"e": @"1",
                           @"f": @"foo",
                           };

    XCTAssertTrue([dict stp_boolForKey:@"a" or:NO]);
    XCTAssertFalse([dict stp_boolForKey:@"b" or:YES]);
    XCTAssertTrue([dict stp_boolForKey:@"c" or:NO]);
    XCTAssertFalse([dict stp_boolForKey:@"d" or:YES]);
    XCTAssertTrue([dict stp_boolForKey:@"e" or:NO]);
    XCTAssertFalse([dict stp_boolForKey:@"f" or:NO]);
}

- (void)testIntForKey {
    NSDictionary *dict = @{
                           @"a": @1,
                           @"b": @-1,
                           @"c": @"1",
                           @"d": @"-1",
                           @"e": @"10.0",
                           @"f": @"10.5",
                           @"g": @(10.0),
                           @"h": @(10.5),
                           @"i": @"foo",
                           };

    XCTAssertEqual([dict stp_intForKey:@"a" or:0], 1);
    XCTAssertEqual([dict stp_intForKey:@"b" or:0], -1);
    XCTAssertEqual([dict stp_intForKey:@"c" or:0], 1);
    XCTAssertEqual([dict stp_intForKey:@"d" or:0], -1);
    XCTAssertEqual([dict stp_intForKey:@"e" or:0], 10);
    XCTAssertEqual([dict stp_intForKey:@"f" or:0], 10);
    XCTAssertEqual([dict stp_intForKey:@"g" or:0], 10);
    XCTAssertEqual([dict stp_intForKey:@"h" or:0], 10);
    XCTAssertEqual([dict stp_intForKey:@"i" or:0], 0);
}

- (void)testDateForKey {
    NSDictionary *dict = @{
                           @"a": @0,
                           @"b": @"0",
                           };
    NSDate *expectedDate = [NSDate dateWithTimeIntervalSince1970:0];

    XCTAssertEqualObjects([dict stp_dateForKey:@"a"], expectedDate);
    XCTAssertEqualObjects([dict stp_dateForKey:@"b"], expectedDate);
    XCTAssertNil([dict stp_dateForKey:@"c"]);
}

- (void)testDictionaryForKey {
    NSDictionary *dict = @{
                           @"a": @{@"foo": @"bar"},
                           };

    XCTAssertEqualObjects([dict stp_dictionaryForKey:@"a"], @{@"foo": @"bar"});
    XCTAssertNil([dict stp_dictionaryForKey:@"b"]);
}

- (void)testNumberForKey {
    NSDictionary *dict = @{
                           @"a": @1,
                           };

    XCTAssertEqualObjects([dict stp_numberForKey:@"a"], @1);
    XCTAssertNil([dict stp_numberForKey:@"b"]);
}

- (void)testStringForKey {
    NSDictionary *dict = @{@"a": @"foo"};
    XCTAssertEqualObjects([dict stp_stringForKey:@"a"], @"foo");
    XCTAssertNil([dict stp_stringForKey:@"b"]);
}

- (void)testURLForKey {
    NSDictionary *dict = @{
                           @"a": @"https://example.com",
                           @"b": @"not a url"
                           };
    XCTAssertEqualObjects([dict stp_urlForKey:@"a"], [NSURL URLWithString:@"https://example.com"]);
    XCTAssertNil([dict stp_urlForKey:@"b"]);
    XCTAssertNil([dict stp_urlForKey:@"c"]);
}

@end
