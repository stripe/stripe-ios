//
//  STDSSelectionCustomization.m
//  Stripe3DS2
//
//  Created by Yuki Tokuhiro on 6/11/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSSelectionCustomization.h"

#import "UIColor+DefaultColors.h"
#import "UIColor+ThirteenSupport.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STDSSelectionCustomization

+ (instancetype)defaultSettings {
    return [self new];
}

- (instancetype)init {
    self = [super init];
    if (self) {
            if (@available(iOS 12.0, *)) {
                _primarySelectedColor = [UIColor _stds_blueColor];
                _secondarySelectedColor = UIColor.whiteColor;
                _unselectedBackgroundColor = [UIColor _stds_colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
                    return (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) ?
                    [UIColor colorWithRed:(CGFloat)231.0 / (CGFloat)255.0
                    green:(CGFloat)241.0 / (CGFloat)255.0
                     blue:(CGFloat)254.0 / (CGFloat)255.0
                                                                                                               alpha:1.0] :
                    [UIColor colorWithRed:(CGFloat)30.0 / (CGFloat)255.0
                                                                                                               green:(CGFloat)63.0 / (CGFloat)255.0
                                                                                                                blue:(CGFloat)84.0 / (CGFloat)255.0
                                                                                                                                            alpha:1.0];
                }];
                _unselectedBorderColor = [UIColor _stds_colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
                    return (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) ?
                    [UIColor colorWithRed:(CGFloat)131.0 / (CGFloat)255.0
                    green:(CGFloat)191.0 / (CGFloat)255.0
                     blue:(CGFloat)250.0 / (CGFloat)255.0
                    alpha:1] :
                    [UIColor colorWithRed:(CGFloat)65.0 / (CGFloat)255.0
                    green:(CGFloat)94.0 / (CGFloat)255.0
                     blue:(CGFloat)123.0 / (CGFloat)255.0
                    alpha:1];
                }];
            } else {
                _primarySelectedColor = [UIColor _stds_blueColor];
                _secondarySelectedColor = UIColor.whiteColor;
                _unselectedBackgroundColor = [UIColor colorWithRed:(CGFloat)231.0 / (CGFloat)255.0
                                                             green:(CGFloat)241.0 / (CGFloat)255.0
                                                              blue:(CGFloat)254.0 / (CGFloat)255.0
                                                             alpha:1.0];
                _unselectedBorderColor = [UIColor colorWithRed:(CGFloat)131.0 / (CGFloat)255.0
                                                         green:(CGFloat)191.0 / (CGFloat)255.0
                                                          blue:(CGFloat)250.0 / (CGFloat)255.0
                                                         alpha:1];
            }
    }
    return self;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    STDSSelectionCustomization *copy = [STDSSelectionCustomization new];
    copy.primarySelectedColor = self.primarySelectedColor;
    copy.secondarySelectedColor = self.secondarySelectedColor;
    copy.unselectedBackgroundColor = self.unselectedBackgroundColor;
    copy.unselectedBorderColor = self.unselectedBorderColor;
    return copy;
}

@end

NS_ASSUME_NONNULL_END
