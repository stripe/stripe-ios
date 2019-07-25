//
//  STPThreeDSTextFieldCustomizationTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 6/18/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Stripe/STDSTextFieldCustomization.h>

#import "STPThreeDSTextFieldCustomization.h"
#import "STPThreeDSCustomization+Private.h"

@interface STPThreeDSTextFieldCustomizationTest : XCTestCase

@end

@implementation STPThreeDSTextFieldCustomizationTest

- (void)testPropertiesAreForwarded {
    STPThreeDSTextFieldCustomization *customization = [STPThreeDSTextFieldCustomization defaultSettings];
    customization.font = [UIFont italicSystemFontOfSize:1];
    customization.textColor = UIColor.blueColor;
    customization.borderWidth = -1;
    customization.borderColor = UIColor.redColor;
    customization.cornerRadius = -8;
    customization.keyboardAppearance = UIKeyboardAppearanceAlert;
    customization.placeholderTextColor = UIColor.greenColor;
    
    STDSTextFieldCustomization *stdsCustomization = customization.textFieldCustomization;
    XCTAssertEqual([UIFont italicSystemFontOfSize:1], stdsCustomization.font);
    XCTAssertEqual(stdsCustomization.font, customization.font);
    
    XCTAssertEqual(UIColor.blueColor, stdsCustomization.textColor);
    XCTAssertEqual(stdsCustomization.textColor, customization.textColor);
    
    XCTAssertEqualWithAccuracy(-1, stdsCustomization.borderWidth, 0.1);
    XCTAssertEqualWithAccuracy(stdsCustomization.borderWidth, customization.borderWidth, 0.1);
    
    XCTAssertEqual(UIColor.redColor, stdsCustomization.borderColor);
    XCTAssertEqual(stdsCustomization.borderColor, customization.borderColor);
    
    XCTAssertEqualWithAccuracy(-8, stdsCustomization.cornerRadius, 0.1);
    XCTAssertEqualWithAccuracy(stdsCustomization.cornerRadius, customization.cornerRadius, 0.1);
    
    XCTAssertEqual(UIKeyboardAppearanceAlert, stdsCustomization.keyboardAppearance);
    XCTAssertEqual(stdsCustomization.keyboardAppearance, customization.keyboardAppearance);
    
    XCTAssertEqual(UIColor.greenColor, stdsCustomization.placeholderTextColor);
    XCTAssertEqual(stdsCustomization.placeholderTextColor, customization.placeholderTextColor);
}

@end
