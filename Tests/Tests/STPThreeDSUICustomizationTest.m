//
//  STPThreeDSUICustomizationTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 6/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Stripe/STDSUICustomization.h>

#import "STPThreeDSCustomization+Private.h"

@interface STPThreeDSUICustomizationTest : XCTestCase

@end

@implementation STPThreeDSUICustomizationTest

- (void)testPropertiesPassedThrough {
    STPThreeDSUICustomization *customization = [STPThreeDSUICustomization defaultSettings];
    
    // Maintains button customization objects
    [customization buttonCustomizationForButtonType:STPThreeDSCustomizationButtonTypeNext].backgroundColor = UIColor.cyanColor;
    [customization buttonCustomizationForButtonType:STPThreeDSCustomizationButtonTypeResend].backgroundColor = UIColor.cyanColor;
    [customization buttonCustomizationForButtonType:STPThreeDSCustomizationButtonTypeSubmit].backgroundColor = UIColor.cyanColor;
    [customization buttonCustomizationForButtonType:STPThreeDSCustomizationButtonTypeContinue].backgroundColor = UIColor.cyanColor;
    [customization buttonCustomizationForButtonType:STPThreeDSCustomizationButtonTypeCancel].backgroundColor = UIColor.cyanColor;
    XCTAssertEqual([customization.uiCustomization buttonCustomizationForButtonType:STDSUICustomizationButtonTypeNext].backgroundColor, UIColor.cyanColor);
    XCTAssertEqual([customization.uiCustomization buttonCustomizationForButtonType:STDSUICustomizationButtonTypeResend].backgroundColor, UIColor.cyanColor);
    XCTAssertEqual([customization.uiCustomization buttonCustomizationForButtonType:STDSUICustomizationButtonTypeSubmit].backgroundColor, UIColor.cyanColor);
    XCTAssertEqual([customization.uiCustomization buttonCustomizationForButtonType:STDSUICustomizationButtonTypeContinue].backgroundColor, UIColor.cyanColor);
    XCTAssertEqual([customization.uiCustomization buttonCustomizationForButtonType:STDSUICustomizationButtonTypeCancel].backgroundColor, UIColor.cyanColor);
    
    STPThreeDSButtonCustomization *buttonCustomization = [STPThreeDSButtonCustomization defaultSettingsForButtonType:STPThreeDSCustomizationButtonTypeNext];
    [customization setButtonCustomization:buttonCustomization forType:STPThreeDSCustomizationButtonTypeNext];
    XCTAssertEqual([customization.uiCustomization buttonCustomizationForButtonType:STDSUICustomizationButtonTypeNext], buttonCustomization.buttonCustomization);

    // Footer
    customization.footerCustomization.backgroundColor = UIColor.cyanColor;
    XCTAssertEqual(customization.uiCustomization.footerCustomization.backgroundColor, UIColor.cyanColor);
    
    STPThreeDSFooterCustomization *footerCustomization = [STPThreeDSFooterCustomization defaultSettings];
    customization.footerCustomization = footerCustomization;
    XCTAssertEqual(customization.uiCustomization.footerCustomization, footerCustomization.footerCustomization);

    // Label
    customization.labelCustomization.textColor = UIColor.cyanColor;
    XCTAssertEqual(customization.uiCustomization.labelCustomization.textColor, UIColor.cyanColor);
    
    STPThreeDSLabelCustomization *labelCustomization = [STPThreeDSLabelCustomization defaultSettings];
    customization.labelCustomization = labelCustomization;
    XCTAssertEqual(customization.uiCustomization.labelCustomization, labelCustomization.labelCustomization);
    
    // Navigation Bar
    customization.navigationBarCustomization.textColor = UIColor.cyanColor;
    XCTAssertEqual(customization.uiCustomization.navigationBarCustomization.textColor, UIColor.cyanColor);
    
    STPThreeDSNavigationBarCustomization *navigationBar = [STPThreeDSNavigationBarCustomization defaultSettings];
    customization.navigationBarCustomization = navigationBar;
    XCTAssertEqual(customization.uiCustomization.navigationBarCustomization, navigationBar.navigationBarCustomization);
    
    // Selection
    customization.selectionCustomization.primarySelectedColor = UIColor.cyanColor;
    XCTAssertEqual(customization.uiCustomization.selectionCustomization.primarySelectedColor, UIColor.cyanColor);
    
    STPThreeDSSelectionCustomization *selection = [STPThreeDSSelectionCustomization defaultSettings];
    customization.selectionCustomization = selection;
    XCTAssertEqual(customization.uiCustomization.selectionCustomization, selection.selectionCustomization);
    
    // Text Field
    customization.textFieldCustomization.textColor = UIColor.cyanColor;
    XCTAssertEqual(customization.uiCustomization.textFieldCustomization.textColor, UIColor.cyanColor);
    
    STPThreeDSTextFieldCustomization *textField = [STPThreeDSTextFieldCustomization defaultSettings];
    customization.textFieldCustomization = textField;
    XCTAssertEqual(customization.uiCustomization.textFieldCustomization, textField.textFieldCustomization);
    
    // Other
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
