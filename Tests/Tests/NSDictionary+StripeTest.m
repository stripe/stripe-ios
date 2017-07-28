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


@end
