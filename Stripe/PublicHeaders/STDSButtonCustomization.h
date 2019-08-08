//
//  STDSButtonCustomization.h
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/14/19.
//  Copyright © 2019 Stripe. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "STDSCustomization.h"

/// An enum that defines the different types of buttons that are able to be customized.
typedef NS_ENUM(NSInteger, STDSUICustomizationButtonType) {
    
    /// The submit button type.
    STDSUICustomizationButtonTypeSubmit = 0,
    
    /// The continue button type.
    STDSUICustomizationButtonTypeContinue = 1,
    
    /// The next button type.
    STDSUICustomizationButtonTypeNext = 2,
    
    /// The cancel button type.
    STDSUICustomizationButtonTypeCancel = 3,
    
    /// The resend button type.
    STDSUICustomizationButtonTypeResend = 4,
};

/// An enumeration of the case transformations that can be applied to the button's title
typedef NS_ENUM(NSInteger, STDSButtonTitleStyle) {
    /// Default style, doesn't modify the title
    STDSButtonTitleStyleDefault,
    
    /// Applies localizedUppercaseString to the title
    STDSButtonTitleStyleUppercase,
    
    /// Applies localizedLowercaseString to the title
    STDSButtonTitleStyleLowercase,
    
    /// Applies localizedCapitalizedString to the title
    STDSButtonTitleStyleSentenceCapitalized,
};

NS_ASSUME_NONNULL_BEGIN

/// A customization object to use to configure the UI of a button.
@interface STDSButtonCustomization: STDSCustomization

/// The default settings for the provided button type.
+ (instancetype)defaultSettingsForButtonType:(STDSUICustomizationButtonType)type;

/**
 Initializes an instance of STDSButtonCustomization with the given backgroundColor and colorRadius.
 */
- (instancetype)initWithBackgroundColor:(UIColor *)backgroundColor cornerRadius:(CGFloat)cornerRadius;

/**
 This is unavailable because there are no sensible default property values without a button type.
 Use `defaultSettingsForButtonType:` or `initWithBackgroundColor:cornerRadius:` instead.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 The background color of the button.
 The default for .resend and .cancel is clear.
 The default for .submit, .continue, and .next is blue.
 */
@property (nonatomic) UIColor *backgroundColor;

/// The corner radius of the button. Defaults to 8.
@property (nonatomic) CGFloat cornerRadius;

/**
 The capitalization style of the button title
 @note This has no effect < iOS 9.0
 */
@property (nonatomic) STDSButtonTitleStyle titleStyle;

@end

NS_ASSUME_NONNULL_END
