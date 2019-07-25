//
//  STPThreeDSNavigationBarCustomizationTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 6/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <Stripe/STDSNavigationBarCustomization.h>

#import "STPThreeDSNavigationBarCustomization.h"
#import "STPThreeDSCustomization+Private.h"


@interface STPThreeDSNavigationBarCustomizationTest : XCTestCase

@end

@implementation STPThreeDSNavigationBarCustomizationTest

- (void)testPropertiesAreForwarded {
    STPThreeDSNavigationBarCustomization *customization = [STPThreeDSNavigationBarCustomization defaultSettings];
    customization.font = [UIFont italicSystemFontOfSize:1];
    customization.textColor = UIColor.blueColor;
    customization.barTintColor = UIColor.redColor;
    customization.barStyle = UIBarStyleBlackOpaque;
    customization.translucent = NO;
    customization.headerText = @"foo";
    customization.buttonText = @"bar";
    
    STDSNavigationBarCustomization *stdsCustomization = customization.navigationBarCustomization;
    XCTAssertEqual([UIFont italicSystemFontOfSize:1], stdsCustomization.font);
    XCTAssertEqual(stdsCustomization.font, customization.font);
    
    XCTAssertEqual(UIColor.blueColor, stdsCustomization.textColor);
    XCTAssertEqual(stdsCustomization.textColor, customization.textColor);
    
    XCTAssertEqual(UIColor.redColor, stdsCustomization.barTintColor);
    XCTAssertEqual(stdsCustomization.barTintColor, customization.barTintColor);
    
    XCTAssertEqual(UIBarStyleBlackOpaque, stdsCustomization.barStyle);
    XCTAssertEqual(stdsCustomization.barStyle, customization.barStyle);
    
    XCTAssertEqual(NO, stdsCustomization.translucent);
    XCTAssertEqual(stdsCustomization.translucent, customization.translucent);
    
    XCTAssertEqual(@"foo", stdsCustomization.headerText);
    XCTAssertEqual(stdsCustomization.headerText, customization.headerText);
    
    XCTAssertEqual(@"bar", stdsCustomization.buttonText);
    XCTAssertEqual(stdsCustomization.buttonText, customization.buttonText);
}

@end
