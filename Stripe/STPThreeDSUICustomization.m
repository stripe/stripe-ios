//
//  STPThreeDSUICustomization.m
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPThreeDSUICustomization.h"
#import "STPThreeDSCustomization+Private.h"
#import "STPThreeDSFooterCustomization.h"

#import <Stripe/STDSUICustomization.h>

@interface STPThreeDSUICustomization()
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, STPThreeDSButtonCustomization *> *buttonCustomizationDictionary;
@end

@implementation STPThreeDSUICustomization

+ (instancetype)defaultSettings {
    return [STPThreeDSUICustomization new];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Initialize defaults for all properties
        _footerCustomization = [STPThreeDSFooterCustomization defaultSettings];
        _labelCustomization = [STPThreeDSLabelCustomization defaultSettings];
        _navigationBarCustomization = [STPThreeDSNavigationBarCustomization defaultSettings];
        _selectionCustomization = [STPThreeDSSelectionCustomization defaultSettings];
        _textFieldCustomization = [STPThreeDSTextFieldCustomization defaultSettings];
        
        STPThreeDSButtonCustomization *nextButton = [STPThreeDSButtonCustomization defaultSettingsForButtonType:STPThreeDSCustomizationButtonTypeNext];
        STPThreeDSButtonCustomization *cancelButton = [STPThreeDSButtonCustomization defaultSettingsForButtonType:STPThreeDSCustomizationButtonTypeCancel];
        STPThreeDSButtonCustomization *resendButton = [STPThreeDSButtonCustomization defaultSettingsForButtonType:STPThreeDSCustomizationButtonTypeResend];
        STPThreeDSButtonCustomization *submitButton = [STPThreeDSButtonCustomization defaultSettingsForButtonType:STPThreeDSCustomizationButtonTypeSubmit];
        STPThreeDSButtonCustomization *continueButton = [STPThreeDSButtonCustomization defaultSettingsForButtonType:STPThreeDSCustomizationButtonTypeContinue];
        _buttonCustomizationDictionary = [@{
                                           @(STPThreeDSCustomizationButtonTypeNext): nextButton,
                                           @(STPThreeDSCustomizationButtonTypeCancel): cancelButton,
                                           @(STPThreeDSCustomizationButtonTypeResend): resendButton,
                                           @(STPThreeDSCustomizationButtonTypeSubmit): submitButton,
                                           @(STPThreeDSCustomizationButtonTypeContinue): continueButton,
                                           } mutableCopy];
        
        // Initialize the underlying STDS class we are wrapping
        _uiCustomization = [STDSUICustomization new];
        [_uiCustomization setButtonCustomization:nextButton.buttonCustomization forType:STDSUICustomizationButtonTypeNext];
        [_uiCustomization setButtonCustomization:cancelButton.buttonCustomization forType:STDSUICustomizationButtonTypeCancel];
        [_uiCustomization setButtonCustomization:resendButton.buttonCustomization forType:STDSUICustomizationButtonTypeResend];
        [_uiCustomization setButtonCustomization:submitButton.buttonCustomization forType:STDSUICustomizationButtonTypeSubmit];
        [_uiCustomization setButtonCustomization:continueButton.buttonCustomization forType:STDSUICustomizationButtonTypeContinue];
        
        _uiCustomization.footerCustomization = _footerCustomization.footerCustomization;
        _uiCustomization.labelCustomization = _labelCustomization.labelCustomization;
        _uiCustomization.navigationBarCustomization = _navigationBarCustomization.navigationBarCustomization;
        _uiCustomization.selectionCustomization = _selectionCustomization.selectionCustomization;
        _uiCustomization.textFieldCustomization = _textFieldCustomization.textFieldCustomization;
    }
    return self;
}

- (void)setButtonCustomization:(STPThreeDSButtonCustomization *)buttonCustomization forType:(STPThreeDSCustomizationButtonType)buttonType {
    self.buttonCustomizationDictionary[@(buttonType)] = buttonCustomization;
    [self.uiCustomization setButtonCustomization:buttonCustomization.buttonCustomization forType:(STDSUICustomizationButtonType)buttonType];
}

- (STPThreeDSButtonCustomization *)buttonCustomizationForButtonType:(STPThreeDSCustomizationButtonType)buttonType {
    return self.buttonCustomizationDictionary[@(buttonType)];
}

- (void)setFooterCustomization:(STPThreeDSFooterCustomization *)footerCustomization {
    _footerCustomization = footerCustomization;
    self.uiCustomization.footerCustomization = footerCustomization.footerCustomization;
}

- (void)setLabelCustomization:(STPThreeDSLabelCustomization *)labelCustomization {
    _labelCustomization = labelCustomization;
    self.uiCustomization.labelCustomization = labelCustomization.labelCustomization;
}

- (void)setNavigationBarCustomization:(STPThreeDSNavigationBarCustomization *)navigationBarCustomization {
    _navigationBarCustomization = navigationBarCustomization;
    self.uiCustomization.navigationBarCustomization = navigationBarCustomization.navigationBarCustomization;
}

- (void)setSelectionCustomization:(STPThreeDSSelectionCustomization *)selectionCustomization {
    _selectionCustomization = selectionCustomization;
    self.uiCustomization.selectionCustomization = selectionCustomization.selectionCustomization;
}

- (void)setTextFieldCustomization:(STPThreeDSTextFieldCustomization *)textFieldCustomization {
    _textFieldCustomization = textFieldCustomization;
    self.uiCustomization.textFieldCustomization = textFieldCustomization.textFieldCustomization;
}

- (UIColor *)backgroundColor {
    return self.uiCustomization.backgroundColor;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    self.uiCustomization.backgroundColor = backgroundColor;
}

- (UIActivityIndicatorViewStyle)activityIndicatorViewStyle {
   return self.uiCustomization.activityIndicatorViewStyle;
}

- (void)setActivityIndicatorViewStyle:(UIActivityIndicatorViewStyle)activityIndicatorViewStyle {
   self.uiCustomization.activityIndicatorViewStyle = activityIndicatorViewStyle;
}

- (UIBlurEffectStyle)blurStyle {
   return self.uiCustomization.blurStyle;
}

- (void)setBlurStyle:(UIBlurEffectStyle)blurStyle {
   self.uiCustomization.blurStyle = blurStyle;
}

@end
