//
//  STPFormTextFieldTest.m
//  Stripe
//
//  Created by Ben Guo on 3/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPFormTextField.h"

@interface STPFormTextFieldTest : XCTestCase

@end

@implementation STPFormTextFieldTest

- (void)testAutoFormattingBehavior_None {
    STPFormTextField *sut = [STPFormTextField new];
    sut.autoFormattingBehavior = STPFormTextFieldAutoFormattingBehaviorNone;
    sut.text = @"123456789";
    XCTAssertEqualObjects(sut.text, @"123456789");
}

- (void)testAutoFormattingBehavior_PhoneNumbers {
    STPFormTextField *sut = [STPFormTextField new];
    sut.autoFormattingBehavior = STPFormTextFieldAutoFormattingBehaviorPhoneNumbers;
    sut.text = @"123456789";
    XCTAssertEqualObjects(sut.text, @"(123) 456-789");
}

- (void)testAutoFormattingBehavior_CardNumbers {
    STPFormTextField *sut = [STPFormTextField new];
    sut.autoFormattingBehavior = STPFormTextFieldAutoFormattingBehaviorCardNumbers;
    sut.text = @"4242424242424242";
    XCTAssertEqualObjects(sut.text, @"4242424242424242");
    NSRange range;
    id value = [sut.attributedText attribute:NSKernAttributeName atIndex:0 effectiveRange:&range];
    XCTAssertEqualObjects(value, @(0));
    XCTAssertEqual(range.length, (NSUInteger)3);
    value = [sut.attributedText attribute:NSKernAttributeName atIndex:3 effectiveRange:&range];
    XCTAssertEqualObjects(value, @(5));
    XCTAssertEqual(range.length, (NSUInteger)1);
    value = [sut.attributedText attribute:NSKernAttributeName atIndex:4 effectiveRange:&range];
    XCTAssertEqualObjects(value, @(0));
    XCTAssertEqual(range.length, (NSUInteger)3);
    value = [sut.attributedText attribute:NSKernAttributeName atIndex:7 effectiveRange:&range];
    XCTAssertEqualObjects(value, @(5));
    XCTAssertEqual(range.length, (NSUInteger)1);
    value = [sut.attributedText attribute:NSKernAttributeName atIndex:8 effectiveRange:&range];
    XCTAssertEqualObjects(value, @(0));
    XCTAssertEqual(range.length, (NSUInteger)3);
    value = [sut.attributedText attribute:NSKernAttributeName atIndex:11 effectiveRange:&range];
    XCTAssertEqualObjects(value, @(5));
    XCTAssertEqual(range.length, (NSUInteger)1);
    value = [sut.attributedText attribute:NSKernAttributeName atIndex:12 effectiveRange:&range];
    XCTAssertEqualObjects(value, @(0));
    XCTAssertEqual(range.length, (NSUInteger)4);
    XCTAssertEqual(sut.attributedText.length, (NSUInteger)16);
    
    sut.placeholder = @"enteracardnumber";
    value = [sut.attributedPlaceholder attribute:NSKernAttributeName atIndex:3 effectiveRange:&range];
    XCTAssertNil(value);
}

@end
