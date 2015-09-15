//
//  STPPaymentCardTextFieldTest.m
//  Stripe
//
//  Created by Jack Flintermann on 8/26/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

@import UIKit;
@import XCTest;

#import "Stripe.h"

@interface STPPaymentCardTextFieldTest : XCTestCase
@end

@implementation STPPaymentCardTextFieldTest

- (void)testIntrinsicContentSize {
    STPPaymentCardTextField *textField = [STPPaymentCardTextField new];
    
    UIFont *iOS8SystemFont = [UIFont fontWithName:@"HelveticaNeue" size:18];
    textField.font = iOS8SystemFont;
    XCTAssertEqualWithAccuracy(textField.intrinsicContentSize.height, 44, 0.1);
    XCTAssertEqualWithAccuracy(textField.intrinsicContentSize.width, 252, 0.1);
    
    UIFont *iOS9SystemFont = [UIFont fontWithName:@".SFUIText-Regular" size:18];
    if (iOS9SystemFont) {
        textField.font = iOS9SystemFont;
        XCTAssertEqualWithAccuracy(textField.intrinsicContentSize.height, 44, 0.1);
        XCTAssertEqualWithAccuracy(textField.intrinsicContentSize.width, 265, 0.1);
    }
    
    textField.font = [UIFont fontWithName:@"Avenir" size:44];
    XCTAssertEqualWithAccuracy(textField.intrinsicContentSize.height, 60, 0.1);
    XCTAssertEqualWithAccuracy(textField.intrinsicContentSize.width, 483, 0.1);
}

@end
