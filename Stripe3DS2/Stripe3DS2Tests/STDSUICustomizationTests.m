//
//  STDSUICustomizationTests.m
//  Stripe3DS2Tests
//
//  Created by Andrew Harrison on 3/14/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STDSUICustomization.h"

@interface STDSUICustomizationTests : XCTestCase

@end

@implementation STDSUICustomizationTests

// The following helper methods return customization objects with properties different than the default.

- (STDSNavigationBarCustomization *)_customNavigationBar {
    STDSNavigationBarCustomization *custom = [STDSNavigationBarCustomization new];
    custom.font = [UIFont italicSystemFontOfSize:1];
    custom.textColor = UIColor.blueColor;
    custom.barTintColor = UIColor.redColor;
    custom.barStyle = UIBarStyleBlack;
    custom.translucent = NO;
    custom.headerText = @"foo";
    custom.buttonText = @"bar";
    return custom;
}

- (STDSLabelCustomization *)_customLabel {
    STDSLabelCustomization *custom = [STDSLabelCustomization new];
    custom.font = [UIFont italicSystemFontOfSize:1];
    custom.textColor = UIColor.blueColor;
    custom.headingTextColor = UIColor.redColor;
    custom.headingFont = [UIFont italicSystemFontOfSize:2];
    return custom;
}

- (STDSTextFieldCustomization *)_customTextField {
    STDSTextFieldCustomization *custom = [STDSTextFieldCustomization new];
    custom.font = [UIFont italicSystemFontOfSize:1];
    custom.textColor = UIColor.blueColor;
    custom.borderWidth = -1;
    custom.borderColor = UIColor.redColor;
    custom.cornerRadius = -8;
    custom.keyboardAppearance = UIKeyboardAppearanceAlert;
    custom.placeholderTextColor = UIColor.greenColor;
    return custom;
}

- (STDSButtonCustomization *)_customButton {
    STDSButtonCustomization *custom = [[STDSButtonCustomization alloc] initWithBackgroundColor:UIColor.redColor cornerRadius:-1];
    custom.font = [UIFont italicSystemFontOfSize:1];
    custom.textColor = UIColor.blueColor;
    custom.titleStyle = STDSButtonTitleStyleLowercase;
    return custom;
}

- (STDSFooterCustomization *)_customFooter {
    STDSFooterCustomization *custom = [STDSFooterCustomization new];
    custom.font = [UIFont italicSystemFontOfSize:1];
    custom.textColor = UIColor.blueColor;
    custom.backgroundColor = UIColor.redColor;
    custom.chevronColor = UIColor.greenColor;
    custom.headingTextColor = UIColor.grayColor;
    custom.headingFont = [UIFont italicSystemFontOfSize:2];
    return custom;
}

- (STDSSelectionCustomization *)_customSelection {
    STDSSelectionCustomization *custom = [STDSSelectionCustomization new];
    custom.primarySelectedColor = UIColor.redColor;
    custom.secondarySelectedColor = UIColor.blueColor;
    custom.unselectedBorderColor = UIColor.brownColor;
    custom.unselectedBackgroundColor = UIColor.cyanColor;
    return custom;
}

#pragma mark - Copying

- (void)testUICustomizationDeepCopy {
    // Make a STDSUICustomization instance with all non-default properties
    STDSButtonCustomization *submitButtonCustomization = [self _customButton];
    STDSButtonCustomization *continueButtonCustomization = [self _customButton];
    continueButtonCustomization.cornerRadius = -2;
    STDSButtonCustomization *nextButtonCustomization = [self _customButton];
    nextButtonCustomization.cornerRadius = -3;
    STDSButtonCustomization *cancelButtonCustomization = [self _customButton];
    cancelButtonCustomization.cornerRadius = -4;
    STDSButtonCustomization *resendButtonCustomization = [self _customButton];
    resendButtonCustomization.cornerRadius = -5;
    
    STDSNavigationBarCustomization *navigationBarCustomization = [self _customNavigationBar];
    STDSLabelCustomization *labelCustomization = [self _customLabel];
    STDSTextFieldCustomization *textFieldCustomization = [self _customTextField];
    STDSFooterCustomization *footerCustomization = [self _customFooter];
    STDSSelectionCustomization *selectionCustomization = [self _customSelection];
    
    STDSUICustomization *uiCustomization = [[STDSUICustomization alloc] init];
    uiCustomization.footerCustomization = footerCustomization;
    uiCustomization.selectionCustomization = selectionCustomization;
    [uiCustomization setButtonCustomization:submitButtonCustomization forType:STDSUICustomizationButtonTypeSubmit];
    [uiCustomization setButtonCustomization:continueButtonCustomization forType:STDSUICustomizationButtonTypeContinue];
    [uiCustomization setButtonCustomization:nextButtonCustomization forType:STDSUICustomizationButtonTypeNext];
    [uiCustomization setButtonCustomization:cancelButtonCustomization forType:STDSUICustomizationButtonTypeCancel];
    [uiCustomization setButtonCustomization:resendButtonCustomization forType:STDSUICustomizationButtonTypeResend];
    uiCustomization.navigationBarCustomization = navigationBarCustomization;
    uiCustomization.labelCustomization = labelCustomization;
    uiCustomization.textFieldCustomization = textFieldCustomization;
    uiCustomization.backgroundColor = UIColor.redColor;
    uiCustomization.activityIndicatorViewStyle = UIActivityIndicatorViewStyleLarge;
    uiCustomization.blurStyle = UIBlurEffectStyleDark;
    uiCustomization.preferredStatusBarStyle = UIStatusBarStyleLightContent;
    
    STDSUICustomization *copy = [uiCustomization copy];
    XCTAssertNotNil([copy buttonCustomizationForButtonType:STDSUICustomizationButtonTypeNext]);
    XCTAssertNotNil(copy.navigationBarCustomization);
    XCTAssertNotNil(copy.labelCustomization);
    XCTAssertNotNil(copy.textFieldCustomization);
    XCTAssertNotNil(copy.footerCustomization);
    XCTAssertNotNil(copy.selectionCustomization);
    
    /// The pointers do not reference the same objects.
    XCTAssertNotEqual([uiCustomization buttonCustomizationForButtonType:STDSUICustomizationButtonTypeSubmit], [copy buttonCustomizationForButtonType:STDSUICustomizationButtonTypeSubmit]);
    XCTAssertNotEqual([uiCustomization buttonCustomizationForButtonType:STDSUICustomizationButtonTypeContinue], [copy buttonCustomizationForButtonType:STDSUICustomizationButtonTypeContinue]);
    XCTAssertNotEqual([uiCustomization buttonCustomizationForButtonType:STDSUICustomizationButtonTypeNext], [copy buttonCustomizationForButtonType:STDSUICustomizationButtonTypeNext]);
    XCTAssertNotEqual([uiCustomization buttonCustomizationForButtonType:STDSUICustomizationButtonTypeCancel], [copy buttonCustomizationForButtonType:STDSUICustomizationButtonTypeCancel]);
    XCTAssertNotEqual([uiCustomization buttonCustomizationForButtonType:STDSUICustomizationButtonTypeResend], [copy buttonCustomizationForButtonType:STDSUICustomizationButtonTypeResend]);
    XCTAssertNotEqual(uiCustomization.navigationBarCustomization, copy.navigationBarCustomization);
    XCTAssertNotEqual(uiCustomization.labelCustomization, copy.labelCustomization);
    XCTAssertNotEqual(uiCustomization.textFieldCustomization, copy.textFieldCustomization);
    XCTAssertNotEqual(uiCustomization.footerCustomization, copy.footerCustomization);
    XCTAssertNotEqual(uiCustomization.selectionCustomization, copy.selectionCustomization);
    
    /// The properties have been successfully copied.
    XCTAssertEqualObjects(uiCustomization.backgroundColor, copy.backgroundColor);
    XCTAssertEqual(uiCustomization.activityIndicatorViewStyle, copy.activityIndicatorViewStyle);
    XCTAssertEqual(uiCustomization.blurStyle, copy.blurStyle);
    // A different test case will cover that our custom classes implemented copy correctly; just sanity check one property here
    XCTAssertEqual([uiCustomization buttonCustomizationForButtonType:STDSUICustomizationButtonTypeSubmit].cornerRadius, submitButtonCustomization.cornerRadius);
    XCTAssertEqual([uiCustomization buttonCustomizationForButtonType:STDSUICustomizationButtonTypeContinue].cornerRadius, continueButtonCustomization.cornerRadius);
    XCTAssertEqual([uiCustomization buttonCustomizationForButtonType:STDSUICustomizationButtonTypeNext].cornerRadius, nextButtonCustomization.cornerRadius);
    XCTAssertEqual([uiCustomization buttonCustomizationForButtonType:STDSUICustomizationButtonTypeCancel].cornerRadius, cancelButtonCustomization.cornerRadius);
    XCTAssertEqual([uiCustomization buttonCustomizationForButtonType:STDSUICustomizationButtonTypeResend].cornerRadius, resendButtonCustomization.cornerRadius);
    XCTAssertEqualObjects(uiCustomization.navigationBarCustomization.font, copy.navigationBarCustomization.font);
    XCTAssertEqualObjects(uiCustomization.labelCustomization.font, copy.labelCustomization.font);
    XCTAssertEqualObjects(uiCustomization.textFieldCustomization.font, copy.textFieldCustomization.font);
    XCTAssertEqualObjects(uiCustomization.footerCustomization.font, copy.footerCustomization.font);
    XCTAssertEqualObjects(uiCustomization.selectionCustomization.primarySelectedColor, copy.selectionCustomization.primarySelectedColor);
    XCTAssertEqual(uiCustomization.preferredStatusBarStyle, copy.preferredStatusBarStyle);
}

- (void)testButtonCustomizationIsCopied {
    STDSButtonCustomization *buttonCustomization = [self _customButton];

    /// The pointers do not reference the same objects.
    STDSButtonCustomization *copy = [buttonCustomization copy];
    XCTAssertNotEqual(buttonCustomization, copy);

    /// The properties have been successfully copied.
    XCTAssertEqual(buttonCustomization.cornerRadius, copy.cornerRadius);
    XCTAssertEqual(buttonCustomization.backgroundColor, copy.backgroundColor);
    XCTAssertEqual(buttonCustomization.font, copy.font);
    XCTAssertEqual(buttonCustomization.textColor, copy.textColor);
    XCTAssertEqual(buttonCustomization.titleStyle, buttonCustomization.titleStyle);
}

- (void)testNavigationBarCustomizationIsCopied {
    STDSNavigationBarCustomization *navigationBarCustomization = [self _customNavigationBar];
    
    /// The pointers do not reference the same objects.
    STDSNavigationBarCustomization *copy = [navigationBarCustomization copy];
    XCTAssertNotEqual(navigationBarCustomization, copy);

    /// The properties have been successfully copied.
    XCTAssertEqualObjects(navigationBarCustomization.headerText, copy.headerText);
    XCTAssertEqualObjects(navigationBarCustomization.buttonText, copy.buttonText);
    XCTAssertEqualObjects(navigationBarCustomization.barTintColor, copy.barTintColor);
    XCTAssertEqualObjects(navigationBarCustomization.font, copy.font);
    XCTAssertEqualObjects(navigationBarCustomization.textColor, copy.textColor);
    XCTAssertEqual(navigationBarCustomization.barStyle, copy.barStyle);
    XCTAssertEqual(navigationBarCustomization.translucent, copy.translucent);
}

- (void)testLabelCustomizationIsCopied {
    STDSLabelCustomization *labelCustomization = [self _customLabel];

    /// The pointers do not reference the same objects.
    STDSLabelCustomization *copy = [labelCustomization copy];
    XCTAssertNotEqual(labelCustomization, copy);

    /// The properties have been successfully copied.
    XCTAssertEqualObjects(labelCustomization.headingTextColor, copy.headingTextColor);
    XCTAssertEqualObjects(labelCustomization.headingFont, copy.headingFont);
    XCTAssertEqualObjects(labelCustomization.font, copy.font);
    XCTAssertEqualObjects(labelCustomization.textColor, copy.textColor);
}

- (void)testTextFieldCustomizationIsCopied {
    STDSTextFieldCustomization *textFieldCustomization = [self _customTextField];

    /// The pointers do not reference the same objects.
    STDSTextFieldCustomization *copy = [textFieldCustomization copy];
    XCTAssertNotEqual(textFieldCustomization, copy);
    
    /// The properties have been successfully copied.
    XCTAssertEqual(textFieldCustomization.borderWidth, copy.borderWidth);
    XCTAssertEqualObjects(textFieldCustomization.borderColor, copy.borderColor);
    XCTAssertEqual(textFieldCustomization.cornerRadius, copy.cornerRadius);
    XCTAssertEqualObjects(textFieldCustomization.font, copy.font);
    XCTAssertEqualObjects(textFieldCustomization.textColor, copy.textColor);
    XCTAssertEqual(textFieldCustomization.keyboardAppearance, copy.keyboardAppearance);
    XCTAssertEqualObjects(textFieldCustomization.placeholderTextColor, copy.placeholderTextColor);
}

- (void)testFooterCustomizationIsCopied {
    STDSFooterCustomization *footerCustomization = [self _customFooter];
    
    /// The pointers do not reference the same objects.
    STDSFooterCustomization *copy = [footerCustomization copy];
    XCTAssertNotEqual(footerCustomization, copy);
    
    /// The properties have been successfully copied.
    XCTAssertEqualObjects(footerCustomization.textColor, copy.textColor);
    XCTAssertEqualObjects(footerCustomization.font, copy.font);
    XCTAssertEqualObjects(footerCustomization.backgroundColor, copy.backgroundColor);
    XCTAssertEqualObjects(footerCustomization.chevronColor, copy.chevronColor);
    XCTAssertEqualObjects(footerCustomization.headingTextColor, copy.headingTextColor);
    XCTAssertEqualObjects(footerCustomization.headingFont, copy.headingFont);
}

- (void)testSelectionCustomizationIsCopied {
    STDSSelectionCustomization *customization = [self _customSelection];
    
    /// The pointers do not reference the same objects.
    STDSSelectionCustomization *copy = [customization copy];
    XCTAssertNotEqual(customization, copy);
    
    /// The properties have been successfully copied.
    XCTAssertEqualObjects(customization.primarySelectedColor, copy.primarySelectedColor);
    XCTAssertEqualObjects(customization.secondarySelectedColor, copy.secondarySelectedColor);
    XCTAssertEqualObjects(customization.unselectedBorderColor, copy.unselectedBorderColor);
    XCTAssertEqualObjects(customization.unselectedBackgroundColor, copy.unselectedBackgroundColor);

}

@end
