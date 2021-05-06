//
//  UIFont+DefaultFonts.h
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/18/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIFont (DefaultFonts)

+ (UIFont *)_stds_defaultHeadingTextFont;

+ (UIFont *)_stds_defaultLabelTextFontWithScale:(CGFloat)scale;
+ (UIFont *)_stds_defaultButtonTextFontWithScale:(CGFloat)scale;
+ (UIFont *)_stds_defaultBoldLabelTextFontWithScale:(CGFloat)scale;

@end

NS_ASSUME_NONNULL_END

void _stds_import_uifont_defaultfonts(void);
