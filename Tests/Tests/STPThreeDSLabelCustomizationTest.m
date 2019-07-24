//
//  STPThreeDSLabelCustomizationTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 6/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <Stripe/STDSLabelCustomization.h>

#import "STPThreeDSLabelCustomization.h"
#import "STPThreeDSCustomization+Private.h"


@interface STPThreeDSLabelCustomizationTest : XCTestCase

@end

@implementation STPThreeDSLabelCustomizationTest

- (void)testPropertiesAreForwarded {
    STPThreeDSLabelCustomization *customization = [STPThreeDSLabelCustomization defaultSettings];
    customization.headingFont = [UIFont systemFontOfSize:1];
    customization.headingTextColor = UIColor.redColor;
    customization.font = [UIFont systemFontOfSize:2];
    customization.textColor = UIColor.blueColor;
    
    STDSLabelCustomization *stdsCustomization = customization.labelCustomization;
    
    XCTAssertEqual([UIFont systemFontOfSize:1], stdsCustomization.headingFont);
    XCTAssertEqual(stdsCustomization.headingFont, customization.headingFont);
    
    XCTAssertEqual(UIColor.redColor, stdsCustomization.headingTextColor);
    XCTAssertEqual(stdsCustomization.headingTextColor, customization.headingTextColor);
    
    XCTAssertEqual([UIFont systemFontOfSize:2], stdsCustomization.font);
    XCTAssertEqual(stdsCustomization.font, customization.font);
    
    XCTAssertEqual(UIColor.blueColor, stdsCustomization.textColor);
    XCTAssertEqual(stdsCustomization.textColor, customization.textColor);
}

@end
