//
//  STPPaymentIntentShippingDetails.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 4/27/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

@class STPPaymentIntentShippingDetailsAddress;

NS_ASSUME_NONNULL_BEGIN

/**
 Shipping information for a PaymentIntent
 
 @see https://stripe.com/docs/api/payment_intents/object#payment_intent_object-shipping
 */
@interface STPPaymentIntentShippingDetails : NSObject <STPAPIResponseDecodable>

/**
 Shipping address.
 */
@property (nonatomic, nullable, readonly) STPPaymentIntentShippingDetailsAddress *address;

/**
 Recipient name.
 */
@property (nonatomic, nullable, copy, readonly) NSString *name;

/**
 The delivery service that shipped a physical product, such as Fedex, UPS, USPS, etc.
 */
@property (nonatomic, nullable, copy, readonly) NSString *carrier;

/**
 Recipient phone (including extension).
 */
@property (nonatomic, nullable, copy, readonly) NSString *phone;

/**
 The tracking number for a physical product, obtained from the delivery service. If multiple tracking numbers were generated for this purchase, please separate them with commas.
 */
@property (nonatomic, nullable, copy, readonly) NSString *trackingNumber;

/**
 You cannot directly instantiate an `STPPaymentIntentShippingDetails`.
 You should only use one that is part of an existing `STPPaymentMethod` object.
 */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
