//
//  UIImage+Stripe.h
//  Stripe
//
//  Created by Ben Guo on 1/4/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STPCardBrand.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (Stripe)

+ (UIImage *)stp_applePayCardImage;
+ (UIImage *)stp_amexCardImage;
+ (UIImage *)stp_dinersClubCardImage;
+ (UIImage *)stp_discoverCardImage;
+ (UIImage *)stp_jcbCardImage;
+ (UIImage *)stp_masterCardCardImage;
+ (UIImage *)stp_visaCardImage;
+ (UIImage *)stp_unknownCardCardImage;

+ (UIImage *)stp_brandImageForCardBrand:(STPCardBrand)brand;
+ (UIImage *)stp_cvcImageForCardBrand:(STPCardBrand)brand;

+ (UIImage *)stp_addIcon;
+ (UIImage *)stp_largeCardFrontImage;
+ (UIImage *)stp_largeCardBackImage;

@end

NS_ASSUME_NONNULL_END

void linkUIImageCategory(void);
