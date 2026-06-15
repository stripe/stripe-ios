//
//  UIButton+CustomInitialization.m
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/18/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "UIButton+CustomInitialization.h"
#import "STDSVisionSupport.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIButton (CustomInitialization)

static const CGFloat kDefaultButtonContentInset = (CGFloat)12.0;

+ (UIButton *)_stds_buttonWithTitle:(NSString * _Nullable)title customization:(STDSButtonCustomization * _Nullable)customization {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.clipsToBounds = YES;
    UIButtonConfiguration *config = [UIButtonConfiguration plainButtonConfiguration];
    config.contentInsets = NSDirectionalEdgeInsetsMake(kDefaultButtonContentInset, 0, kDefaultButtonContentInset, 0);
    button.configuration = config;
    [[self class] _stds_configureButton:button withTitle:title customization:customization];
    
    return button;
}

+ (void)_stds_configureButton:(UIButton *)button withTitle:(NSString * _Nullable)buttonTitle customization:(STDSButtonCustomization *  _Nullable)buttonCustomization {
    button.backgroundColor = buttonCustomization.backgroundColor;
    button.layer.cornerRadius = buttonCustomization.cornerRadius;

    UIFont *font = buttonCustomization.font;
    UIColor *textColor = buttonCustomization.textColor;

    if (buttonTitle != nil) {
        NSMutableDictionary *attributesDictionary = [NSMutableDictionary dictionary];

        if (font != nil) {
            attributesDictionary[NSFontAttributeName] = font;
        }

        if (textColor != nil) {
            attributesDictionary[NSForegroundColorAttributeName] = textColor;
        }
        switch (buttonCustomization.titleStyle) {
            case STDSButtonTitleStyleDefault:
                break;
            case STDSButtonTitleStyleSentenceCapitalized:
                buttonTitle = [buttonTitle localizedCapitalizedString];
                break;
            case STDSButtonTitleStyleLowercase:
                buttonTitle = [buttonTitle localizedLowercaseString];
                break;
            case STDSButtonTitleStyleUppercase:
                buttonTitle = [buttonTitle localizedUppercaseString];
                break;
        }

        NSAttributedString *title = [[NSAttributedString alloc] initWithString:buttonTitle attributes:attributesDictionary];
        [button setAttributedTitle:title forState:UIControlStateNormal];
    }
}

@end

NS_ASSUME_NONNULL_END
