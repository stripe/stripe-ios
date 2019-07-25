//
//  STPThreeDSButtonCustomizationTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 6/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Stripe/STDSButtonCustomization.h>

#import "STPThreeDSButtonCustomization.h"
#import "STPThreeDSCustomization+Private.h"

@interface STPThreeDSButtonCustomizationTest: XCTestCase
@end

@implementation STPThreeDSButtonCustomizationTest

- (void)testPropertiesAreForwarded {
    STPThreeDSButtonCustomization *customization = [STPThreeDSButtonCustomization defaultSettingsForButtonType:STPThreeDSCustomizationButtonTypeNext];
    customization.backgroundColor = UIColor.redColor;
    customization.cornerRadius = -1;
    customization.titleStyle = STPThreeDSButtonTitleStyleLowercase;
    customization.font = [UIFont italicSystemFontOfSize:1];
    customization.textColor = UIColor.blueColor;
    
    STDSButtonCustomization *stdsCustomization = customization.buttonCustomization;
    XCTAssertEqual(UIColor.redColor, stdsCustomization.backgroundColor);
    XCTAssertEqual(stdsCustomization.backgroundColor, customization.backgroundColor);
    
    XCTAssertEqualWithAccuracy(-1, stdsCustomization.cornerRadius, 0.1);
    XCTAssertEqualWithAccuracy(stdsCustomization.cornerRadius, customization.cornerRadius, 0.1);

    XCTAssertEqual(STPThreeDSButtonTitleStyleLowercase, stdsCustomization.titleStyle);
    XCTAssertEqual(@(stdsCustomization.titleStyle).intValue, @(customization.titleStyle).intValue);

    XCTAssertEqual([UIFont italicSystemFontOfSize:1], stdsCustomization.font);
    XCTAssertEqual(stdsCustomization.font, customization.font);
    
    XCTAssertEqual(UIColor.blueColor, stdsCustomization.textColor);
    XCTAssertEqual(stdsCustomization.textColor, customization.textColor);
}

@end
