//
//  STPThreeDSTextFieldCustomization.h
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/18/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A customization object to use to configure the UI of a text field.
 */
@interface STPThreeDSTextFieldCustomization : NSObject

/// The default settings.
+ (instancetype)defaultSettings;

/// The border width of the text field. Defaults to 2.
@property (nonatomic) CGFloat borderWidth;

/// The color of the border of the text field. Defaults to clear.
@property (nonatomic, strong) UIColor *borderColor;

/// The corner radius of the edges of the text field. Defaults to 8.
@property (nonatomic) CGFloat cornerRadius;

/// The appearance of the keyboard. Defaults to UIKeyboardAppearanceDefault.
@property (nonatomic) UIKeyboardAppearance keyboardAppearance;

/// The color of the placeholder text. Defaults to light gray.
@property (nonatomic, strong) UIColor *placeholderTextColor;

/// The font to use for text.
@property (nonatomic, strong) UIFont *font;

/// The color to use for the text. Defaults to black.
@property (nonatomic, strong) UIColor *textColor;

@end

NS_ASSUME_NONNULL_END
