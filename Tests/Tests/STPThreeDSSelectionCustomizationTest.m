//
//  STPThreeDSSelectionCustomizationTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 6/18/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Stripe/STDSSelectionCustomization.h>

#import "STPThreeDSSelectionCustomization.h"
#import "STPThreeDSCustomization+Private.h"

@interface STPThreeDSSelectionCustomizationTest : XCTestCase

@end

@implementation STPThreeDSSelectionCustomizationTest

- (void)testPropertiesAreForwarded {
    STPThreeDSSelectionCustomization *customization = [STPThreeDSSelectionCustomization defaultSettings];
    customization.primarySelectedColor = UIColor.redColor;
    customization.secondarySelectedColor = UIColor.blueColor;
    customization.unselectedBorderColor = UIColor.brownColor;
    customization.unselectedBackgroundColor = UIColor.cyanColor;
    
    STDSSelectionCustomization *stdsCustomization = customization.selectionCustomization;
    XCTAssertEqual(UIColor.redColor, stdsCustomization.primarySelectedColor);
    XCTAssertEqual(stdsCustomization.primarySelectedColor, customization.primarySelectedColor);
    
    XCTAssertEqual(UIColor.blueColor, stdsCustomization.secondarySelectedColor);
    XCTAssertEqual(stdsCustomization.secondarySelectedColor, customization.secondarySelectedColor);
    
    XCTAssertEqual(UIColor.brownColor, stdsCustomization.unselectedBorderColor);
    XCTAssertEqual(stdsCustomization.unselectedBorderColor, customization.unselectedBorderColor);
    
    XCTAssertEqual(UIColor.cyanColor, stdsCustomization.unselectedBackgroundColor);
    XCTAssertEqual(stdsCustomization.unselectedBackgroundColor, customization.unselectedBackgroundColor);
}

@end
