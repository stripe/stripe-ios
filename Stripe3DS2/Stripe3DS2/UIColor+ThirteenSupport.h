//
//  UIColor+ThirteenSupport.h
//  Stripe3DS2
//
//  Created by David Estes on 8/21/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (STDSThirteenSupport)

+ (UIColor *)_stds_colorWithDynamicProvider:(UIColor * _Nonnull (^)(UITraitCollection *traitCollection))dynamicProvider;
+ (UIColor *)_stds_systemGray5Color;
+ (UIColor *)_stds_systemGray2Color;
+ (UIColor *)_stds_systemBackgroundColor;
+ (UIColor *)_stds_labelColor;


@end

NS_ASSUME_NONNULL_END
