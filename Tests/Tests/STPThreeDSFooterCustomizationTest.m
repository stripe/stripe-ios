//
//  STPThreeDSFooterCustomizationTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 6/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <Stripe/STDSFooterCustomization.h>

#import "STPThreeDSFooterCustomization.h"
#import "STPThreeDSCustomization+Private.h"

@interface STPThreeDSFooterCustomizationTest : XCTestCase
@end

@implementation STPThreeDSFooterCustomizationTest

- (void)testPropertiesAreForwarded {
    STPThreeDSFooterCustomization *customization = [STPThreeDSFooterCustomization defaultSettings];
    customization.backgroundColor = UIColor.redColor;
    customization.chevronColor = UIColor.blueColor;
    customization.headingTextColor = UIColor.greenColor;
    customization.headingFont = [UIFont systemFontOfSize:1];
    customization.font = [UIFont systemFontOfSize:2];
    customization.textColor = UIColor.magentaColor;
    
    STDSFooterCustomization *stdsCustomization = customization.footerCustomization;
    
    XCTAssertEqual(UIColor.redColor, stdsCustomization.backgroundColor);
    XCTAssertEqual(stdsCustomization.backgroundColor, customization.backgroundColor);
    
    XCTAssertEqual(UIColor.blueColor, stdsCustomization.chevronColor);
    XCTAssertEqual(stdsCustomization.chevronColor, customization.chevronColor);
    
    XCTAssertEqual(UIColor.greenColor, stdsCustomization.headingTextColor);
    XCTAssertEqual(stdsCustomization.headingTextColor, customization.headingTextColor);
    
    XCTAssertEqual([UIFont systemFontOfSize:1], stdsCustomization.headingFont);
    XCTAssertEqual(stdsCustomization.headingFont, customization.headingFont);
    
    XCTAssertEqual([UIFont systemFontOfSize:2], stdsCustomization.font);
    XCTAssertEqual(stdsCustomization.font, customization.font);
    
    XCTAssertEqual(UIColor.magentaColor, stdsCustomization.textColor);
    XCTAssertEqual(stdsCustomization.textColor, customization.textColor);
}

@end
