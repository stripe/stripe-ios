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

/**
 *  This category lets you access card icons used by the Stripe SDK. All icons are 32 x 20 points.
 */
@interface UIImage (Stripe)

/**
 *  An icon representing Apple Pay.
 */
+ (UIImage *)stp_applePayCardImage;

/**
 *  An icon representing American Express.
 */
+ (UIImage *)stp_amexCardImage;

/**
 *  An icon representing Diners Club.
 */
+ (UIImage *)stp_dinersClubCardImage;

/**
 *  An icon representing Discover.
 */
+ (UIImage *)stp_discoverCardImage;

/**
 *  An icon representing JCB.
 */
+ (UIImage *)stp_jcbCardImage;

/**
 *  An icon representing MasterCard.
 */
+ (UIImage *)stp_masterCardCardImage;

/**
 *  An icon representing Visa.
 */
+ (UIImage *)stp_visaCardImage;

/**
 *  An icon to use when the type of the card is unknown.
 */
+ (UIImage *)stp_unknownCardCardImage;

/**
 *  This returns the appropriate icon for the specified card brand.
 */
+ (UIImage *)stp_brandImageForCardBrand:(STPCardBrand)brand;

/**
 *  This returns a small icon indicating the CVC location for the given card brand.
 */
+ (UIImage *)stp_cvcImageForCardBrand:(STPCardBrand)brand;

@end

NS_ASSUME_NONNULL_END

void linkUIImageCategory(void);
