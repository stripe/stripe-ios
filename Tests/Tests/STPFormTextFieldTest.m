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
    [sut setText:@"123456789"];
    XCTAssertEqualObjects(sut.text, @"123456789");
}

- (void)testAutoFormattingBehavior_PhoneNumbers {
    STPFormTextField *sut = [STPFormTextField new];
    sut.autoFormattingBehavior = STPFormTextFieldAutoFormattingBehaviorPhoneNumbers;
    [sut setText:@"123456789"];
    XCTAssertEqualObjects(sut.text, @"(123) 456-789");
}

- (void)testAutoFormattingBehavior_CardNumbers {
    STPFormTextField *sut = [STPFormTextField new];
    sut.autoFormattingBehavior = STPFormTextFieldAutoFormattingBehaviorCardNumbers;
    [sut setText:@"4242424242424242"];
    XCTAssertEqualObjects(sut.text, @"4242424242424242");
}

@end
