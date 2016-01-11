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

+ (nullable UIImage *)stp_brandImageForCardBrand:(STPCardBrand)brand;
+ (nullable UIImage *)stp_cvcImageForCardBrand:(STPCardBrand)brand;

@end

void linkUIImageCategory(void);
