//
//  STPStringUtilsTest.m
//  Stripe
//
//  Created by Brian Dorfman on 9/8/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPStringUtils.h"

@interface STPStringUtilsTest : XCTestCase

@end

@implementation STPStringUtilsTest

- (void)testParseRangeSingleTagSuccess1 {
    [STPStringUtils parseRangeFromString:@"Test <b>string</b>"
                                 withTag:@"b"
                              completion:^(NSString *string, NSRange range) {
                                  XCTAssertTrue(NSEqualRanges(range, 
                                                              NSMakeRange(5, 6)));
                                  XCTAssertTrue([string isEqualToString:@"Test string"]);
                              }];    
}

- (void)testParseRangeSingleTagSuccess2 {
    [STPStringUtils parseRangeFromString:@"<a>Test <b>str</a>ing</b>"
                                 withTag:@"b"
                              completion:^(NSString *string, NSRange range) {
                                  XCTAssertTrue(NSEqualRanges(range, 
                                                              NSMakeRange(8, 10)));
                                  XCTAssertTrue([string isEqualToString:@"<a>Test str</a>ing"]);
                              }];    
}

- (void)testParseRangeSingleTagFailure1 {
    [STPStringUtils parseRangeFromString:@"Test <b>string</b>"
                                 withTag:@"a"
                              completion:^(NSString *string, NSRange range) {
                                  XCTAssertTrue(range.location == NSNotFound);
                                  XCTAssertTrue([string isEqualToString:@"Test <b>string</b>"]);
                              }];
}

- (void)testParseRangeSingleTagFailure2 {
    [STPStringUtils parseRangeFromString:@"Test <b>string"
                                 withTag:@"b"
                              completion:^(NSString *string, NSRange range) {
                                  XCTAssertTrue(range.location == NSNotFound);
                                  XCTAssertTrue([string isEqualToString:@"Test <b>string"]);
                              }];
}

- (void)testParseRangesMultiTag1 {
    [STPStringUtils parseRangesFromString:@"<a>Test</a> <b>string</b>"
                                 withTags:[NSSet setWithArray:@[@"a", @"b", @"c"]]
                               completion:^(NSString *string, NSDictionary<NSString *,NSValue *> *tagMap) {
                                   XCTAssertTrue(NSEqualRanges(tagMap[@"a"].rangeValue, 
                                                               NSMakeRange(0, 4)));
                                   XCTAssertTrue(NSEqualRanges(tagMap[@"b"].rangeValue, 
                                                               NSMakeRange(5, 6)));
                                   XCTAssertTrue(tagMap[@"c"].rangeValue.location == NSNotFound);
                                   XCTAssertTrue([string isEqualToString:@"Test string"]);
                               }];
}

- (void)testParseRangesMultiTag2 {
    [STPStringUtils parseRangesFromString:@"Test string"
                                 withTags:[NSSet setWithArray:@[@"a", @"b", @"c"]]
                               completion:^(NSString *string, NSDictionary<NSString *,NSValue *> *tagMap) {
                                   XCTAssertTrue(tagMap[@"a"].rangeValue.location == NSNotFound);
                                   XCTAssertTrue(tagMap[@"b"].rangeValue.location == NSNotFound);
                                   XCTAssertTrue(tagMap[@"c"].rangeValue.location == NSNotFound);
                                   XCTAssertTrue([string isEqualToString:@"Test string"]);
                               }];
}


@end
