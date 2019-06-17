//
//  STPThreeDSUICustomizationTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 6/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPThreeDSUICustomization.h"
#import "STPThreeDSButtonCustomization.h"

@interface STPThreeDSUICustomizationTest : XCTestCase

@end

@implementation STPThreeDSUICustomizationTest

- (void)testPropertiesPassedThrough {
    STPThreeDSUICustomization *customization = [STPThreeDSUICustomization defaultSettings];
    // Maintains button customization objects
    STPThreeDSButtonCustomization *button = [customization buttonCustomizationForButtonType:STPThreeDSCustomizationButtonTypeNext];
    button.backgroundColor = UIColor.redColor;
    [customization setButtonCustomization:button forType:STPThreeDSCustomizationButtonTypeNext];
    XCTAssertEqual([customization buttonCustomizationForButtonType:STPThreeDSCustomizationButtonTypeNext], button);
}

@end
