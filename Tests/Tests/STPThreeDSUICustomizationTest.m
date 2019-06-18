//
//  STPThreeDSUICustomizationTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 6/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Stripe3DS2/STDSUICustomization.h>

#import "STPThreeDSCustomization+Private.h"

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
    
    STPThreeDSFooterCustomization *footer = [STPThreeDSFooterCustomization defaultSettings];
    customization.footerCustomization = footer;
    XCTAssertEqual(customization.uiCustomization.footerCustomization, footer.footerCustomization);
    
    STPThreeDSLabelCustomization *label = [STPThreeDSLabelCustomization defaultSettings];
    customization.labelCustomization = label;
    XCTAssertEqual(customization.uiCustomization.labelCustomization, label.labelCustomization);
    
    STPThreeDSNavigationBarCustomization *navigationBar = [STPThreeDSNavigationBarCustomization defaultSettings];
    customization.navigationBarCustomization = navigationBar;
    XCTAssertEqual(customization.uiCustomization.navigationBarCustomization, navigationBar.navigationBarCustomization);
    
    STPThreeDSSelectionCustomization *selection = [STPThreeDSSelectionCustomization defaultSettings];
    customization.selectionCustomization = selection;
    XCTAssertEqual(customization.uiCustomization.selectionCustomization, selection.selectionCustomization);
    
    STPThreeDSTextFieldCustomization *textField = [STPThreeDSTextFieldCustomization defaultSettings];
    customization.textFieldCustomization = textField;
    XCTAssertEqual(customization.uiCustomization.textFieldCustomization, textField.textFieldCustomization);
    
    customization.backgroundColor = UIColor.redColor;
    customization.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    customization.blurStyle = UIBlurEffectStyleDark;
    
    XCTAssertEqual(UIColor.redColor, customization.backgroundColor);
    XCTAssertEqual(customization.backgroundColor, customization.uiCustomization.backgroundColor);
    
    XCTAssertEqual(UIActivityIndicatorViewStyleWhiteLarge, customization.activityIndicatorViewStyle);
    XCTAssertEqual(customization.activityIndicatorViewStyle, customization.uiCustomization.activityIndicatorViewStyle);
    
    XCTAssertEqual(UIBlurEffectStyleDark, customization.blurStyle);
    XCTAssertEqual(customization.blurStyle, customization.uiCustomization.blurStyle);
}

@end
