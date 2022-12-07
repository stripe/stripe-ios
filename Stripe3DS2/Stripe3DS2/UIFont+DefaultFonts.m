//
//  UIFont+DefaultFonts.m
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/18/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "UIFont+DefaultFonts.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIFont (DefaultFonts)

+ (UIFont *)_stds_defaultHeadingTextFont {
    UIFontDescriptor *fontDescriptor = [[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleHeadline] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    
    return [UIFont fontWithDescriptor:fontDescriptor size:fontDescriptor.pointSize * (CGFloat)1.1];
}

+ (UIFont *)_stds_defaultLabelTextFontWithScale:(CGFloat)scale {
    UIFontDescriptor *fontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];

    return [UIFont fontWithDescriptor:fontDescriptor size:fontDescriptor.pointSize * scale];
}

+ (UIFont *)_stds_defaultBoldLabelTextFontWithScale:(CGFloat)scale  {
    UIFontDescriptor *fontDescriptor = [[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    
    return [UIFont fontWithDescriptor:fontDescriptor size:fontDescriptor.pointSize * scale];
}

+ (UIFont *)_stds_defaultButtonTextFontWithScale:(CGFloat)scale  {
    UIFontDescriptor *fontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleHeadline];
    
    return [UIFont fontWithDescriptor:fontDescriptor size:fontDescriptor.pointSize * scale];
}

@end

NS_ASSUME_NONNULL_END

void _stds_import_uifont_defaultfonts() {}
