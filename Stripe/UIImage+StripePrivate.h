//
//  UIImage+StripePrivate.h
//  Stripe
//
//  Created by Jack Flintermann on 6/30/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "UIImage+Stripe.h"

@interface UIImage (StripePrivate)

+ (UIImage *)stp_addIcon;
+ (UIImage *)stp_leftChevronIcon;
+ (UIImage *)stp_smallRightChevronIcon;
+ (UIImage *)stp_largeCardFrontImage;
+ (UIImage *)stp_largeCardBackImage;
+ (UIImage *)stp_largeCardApplePayImage;

- (UIImage *)stp_imageWithTintColor:(UIColor *)color;
- (UIImage *)stp_paddedImageWithInsets:(UIEdgeInsets)insets;

@end
