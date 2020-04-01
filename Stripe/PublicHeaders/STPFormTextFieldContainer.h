//
//  STPFormTextFieldContainer.h
//  Stripe
//
//  Created by Cameron Sabol on 3/12/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 STPFormTextFieldContainer is a protocol that views can conform to to provide customization properties for the field form views that they contain.
 */
@protocol STPFormTextFieldContainer <NSObject>

/**
 The font used in each child field. Default is [UIFont preferredFontForTextStyle:UIFontTextStyleBody].

 Set this property to nil to reset to the default.
 */
@property (nonatomic, copy, null_resettable) UIFont *formFont UI_APPEARANCE_SELECTOR;

/**
 The text color to be used when entering valid text. Default is [UIColor labelColor] on iOS 13.0 and later an [UIColor darkTextColor] on earlier versions.

 Set this property to nil to reset to the default.
 */
@property (nonatomic, copy, null_resettable) UIColor *formTextColor UI_APPEARANCE_SELECTOR;

/**
 The text color to be used when the user has entered invalid information,
 such as an invalid card number.

 Default is [UIColor redColor]. Set this property to nil to reset to the default.
 */
@property (nonatomic, copy, null_resettable) UIColor *formTextErrorColor UI_APPEARANCE_SELECTOR;

/**
 The text placeholder color used in each child field.

 This will also set the color of the card placeholder icon.

 Default is [UIColor placeholderTextColor] on iOS 13.0 and [UIColor lightGrayColor] on earlier versions. Set this property to nil to reset to the default.
 */
@property (nonatomic, copy, null_resettable) UIColor *formPlaceholderColor UI_APPEARANCE_SELECTOR;

/**
 The cursor color for the field.

 This is a proxy for the view's tintColor property, exposed for clarity only
 (in other words, calling setCursorColor is identical to calling setTintColor).
 */
@property (nonatomic, copy, null_resettable) UIColor *formCursorColor UI_APPEARANCE_SELECTOR;

/**
 The keyboard appearance for the field.

 Default is UIKeyboardAppearanceDefault.
 */
@property (nonatomic, assign) UIKeyboardAppearance formKeyboardAppearance UI_APPEARANCE_SELECTOR;

@end
