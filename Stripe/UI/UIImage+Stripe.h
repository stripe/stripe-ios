//
//  UIImage+Stripe.h
//  Stripe
//
//  Created by Ben Guo on 1/4/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STPCardBrand.h"

@interface UIImage (Stripe)

+ (nonnull UIImage *)stp_amexCardImage;
+ (nonnull UIImage *)stp_dinersClubCardImage;
+ (nonnull UIImage *)stp_discoverCardImage;
+ (nonnull UIImage *)stp_jcbCardImage;
+ (nonnull UIImage *)stp_masterCardCardImage;
+ (nonnull UIImage *)stp_visaCardImage;
+ (nonnull UIImage *)stp_unknownCardCardImage;

+ (nullable UIImage *)stp_brandImageForCardBrand:(STPCardBrand)brand;
+ (nullable UIImage *)stp_cvcImageForCardBrand:(STPCardBrand)brand;
+ (nullable UIImage *)stp_safeImageNamed:(nonnull NSString *)imageName;

@end

void linkUIImageCategory(void);
