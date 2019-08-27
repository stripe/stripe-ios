//
//  STDSTextFieldCustomization.h
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/14/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "STDSCustomization.h"

NS_ASSUME_NONNULL_BEGIN

/**
 A customization object to use to configure the UI of a text field.

 The font and textColor inherited from `STDSCustomization` configure
 the user input text.
 */
@interface STDSTextFieldCustomization : STDSCustomization

/**
 The default settings.
 
 The default textColor is black.
 */
+ (instancetype)defaultSettings;

/// The border width of the text field. Defaults to 2.
@property (nonatomic) CGFloat borderWidth;

/// The color of the border of the text field. Defaults to clear.
@property (nonatomic) UIColor *borderColor;

/// The corner radius of the edges of the text field. Defaults to 8.
@property (nonatomic) CGFloat cornerRadius;

/// The appearance of the keyboard. Defaults to UIKeyboardAppearanceDefault.
@property (nonatomic) UIKeyboardAppearance keyboardAppearance;

/// The color of the placeholder text. Defaults to light gray.
@property (nonatomic) UIColor *placeholderTextColor;

@end

NS_ASSUME_NONNULL_END
