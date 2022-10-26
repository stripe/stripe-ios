//
//  STDSUICustomization.m
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/14/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSUICustomization.h"
#import "UIColor+ThirteenSupport.h"

NS_ASSUME_NONNULL_BEGIN

@interface STDSUICustomization()

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, STDSButtonCustomization *> *buttonCustomizationDictionary;

@end

@implementation STDSUICustomization

+ (instancetype)defaultSettings {
    return [[STDSUICustomization alloc] init];
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _buttonCustomizationDictionary = [@{
                                            @(STDSUICustomizationButtonTypeNext): [STDSButtonCustomization defaultSettingsForButtonType:STDSUICustomizationButtonTypeNext
                                                                                   ],
                                            @(STDSUICustomizationButtonTypeCancel): [STDSButtonCustomization defaultSettingsForButtonType:STDSUICustomizationButtonTypeCancel],
                                            @(STDSUICustomizationButtonTypeResend): [STDSButtonCustomization defaultSettingsForButtonType:STDSUICustomizationButtonTypeResend],
                                            @(STDSUICustomizationButtonTypeSubmit): [STDSButtonCustomization defaultSettingsForButtonType:STDSUICustomizationButtonTypeSubmit],
                                            @(STDSUICustomizationButtonTypeContinue): [STDSButtonCustomization defaultSettingsForButtonType:STDSUICustomizationButtonTypeContinue],
                                            } mutableCopy];
        _navigationBarCustomization = [STDSNavigationBarCustomization defaultSettings];
        _labelCustomization = [STDSLabelCustomization defaultSettings];
        _textFieldCustomization = [STDSTextFieldCustomization defaultSettings];
        _footerCustomization = [STDSFooterCustomization defaultSettings];
        _selectionCustomization = [STDSSelectionCustomization defaultSettings];
        _backgroundColor = UIColor._stds_systemBackgroundColor;
        _activityIndicatorViewStyle = UIActivityIndicatorViewStyleMedium;
        _blurStyle = UIBlurEffectStyleRegular;
        _preferredStatusBarStyle = UIStatusBarStyleDefault;
    }
    
    return self;
}

- (void)setButtonCustomization:(STDSButtonCustomization *)buttonCustomization forType:(STDSUICustomizationButtonType)buttonType {
    self.buttonCustomizationDictionary[@(buttonType)] = buttonCustomization;
}

- (STDSButtonCustomization *)buttonCustomizationForButtonType:(STDSUICustomizationButtonType)buttonType {
    return self.buttonCustomizationDictionary[@(buttonType)];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(nullable NSZone *)zone {
    STDSUICustomization *copy = [[[self class] allocWithZone:zone] init];
    copy.navigationBarCustomization = [self.navigationBarCustomization copy];
    copy.labelCustomization = [self.labelCustomization copy];
    copy.textFieldCustomization = [self.textFieldCustomization copy];
    NSMutableDictionary<NSNumber *, STDSButtonCustomization *> *buttonCustomizationDictionary = [NSMutableDictionary new];
    for (NSNumber *buttonCustomization in self.buttonCustomizationDictionary) {
        buttonCustomizationDictionary[buttonCustomization] = [self.buttonCustomizationDictionary[buttonCustomization] copy];
    }
    copy.buttonCustomizationDictionary = buttonCustomizationDictionary;
    copy.footerCustomization = [self.footerCustomization copy];
    copy.selectionCustomization = [self.selectionCustomization copy];
    copy.backgroundColor = self.backgroundColor;
    copy.activityIndicatorViewStyle = self.activityIndicatorViewStyle;
    copy.blurStyle = self.blurStyle;
    copy.preferredStatusBarStyle = self.preferredStatusBarStyle;
    return copy;
}

@end

NS_ASSUME_NONNULL_END
