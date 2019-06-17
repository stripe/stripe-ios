//
//  STPThreeDSButtonCustomization.h
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//
@import UIKit;

#import <Foundation/Foundation.h>

/// An enum that defines the different types of buttons that are able to be customized.
typedef NS_ENUM(NSInteger, STPThreeDSCustomizationButtonType) {
    
    /// The submit button type.
    STPThreeDSCustomizationButtonTypeSubmit = 0,
    
    /// The continue button type.
    STPThreeDSCustomizationButtonTypeContinue = 1,
    
    /// The next button type.
    STPThreeDSCustomizationButtonTypeNext = 2,
    
    /// The cancel button type.
    STPThreeDSCustomizationButtonTypeCancel = 3,
    
    /// The resend button type.
    STPThreeDSCustomizationButtonTypeResend = 4,
};

/// An enumeration of the case transformations that can be applied to the button's title
typedef NS_ENUM(NSInteger, STPThreeDSButtonTitleStyle) {
    /// Default style, doesn't modify the title
    STPThreeDSButtonTitleStyleDefault,
    
    /// Applies localizedUppercaseString to the title
    STPThreeDSButtonTitleStyleUppercase,
    
    /// Applies localizedLowercaseString to the title
    STPThreeDSButtonTitleStyleLowercase,
    
    /// Applies localizedCapitalizedString to the title
    STPThreeDSButtonTitleStyleSentenceCapitalized,
};

NS_ASSUME_NONNULL_BEGIN

/// A customization object to use to configure the UI of a button.
@interface STPThreeDSButtonCustomization: NSObject

/// The default settings for the provided button type.
+ (instancetype)defaultSettingsForButtonType:(STPThreeDSCustomizationButtonType)type;

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
@property (nonatomic, strong) UIColor *backgroundColor;

/// The corner radius of the button. Defaults to 8.
@property (nonatomic) CGFloat cornerRadius;

/**
 The capitalization style of the button title.
 @note This has no effect < iOS 9.0.
 */
@property (nonatomic) STPThreeDSButtonTitleStyle titleStyle;

/// The font of the title.
@property (nonatomic, strong) UIFont *font;

/// The text color of the title.
@property (nonatomic, strong) UIColor *textColor;

@end

NS_ASSUME_NONNULL_END
