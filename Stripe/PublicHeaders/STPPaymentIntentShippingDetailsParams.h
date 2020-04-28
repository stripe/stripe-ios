//
//  STPPaymentIntentShippingDetailsParams.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 4/27/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPFormEncodable.h"

@class STPPaymentIntentShippingDetailsAddressParams;

NS_ASSUME_NONNULL_BEGIN

/**
Shipping information for a PaymentIntent

@see https://stripe.com/docs/api/payment_intents/confirm#confirm_payment_intent-shipping
*/
@interface STPPaymentIntentShippingDetailsParams : NSObject <NSCopying, STPFormEncodable>

/**
 Shipping address.
 */
@property (nonatomic) STPPaymentIntentShippingDetailsAddressParams *address;

/**
 Recipient name.
 */
@property (nonatomic, copy) NSString *name;

/**
 The delivery service that shipped a physical product, such as Fedex, UPS, USPS, etc.
 */
@property (nonatomic, nullable, copy) NSString *carrier;

/**
 Recipient phone (including extension).
 */
@property (nonatomic, nullable, copy) NSString *phone;

/**
 The tracking number for a physical product, obtained from the delivery service. If multiple tracking numbers were generated for this purchase, please separate them with commas.
 */
@property (nonatomic, nullable, copy) NSString *trackingNumber;

/**
 Initialize an `STPPaymentIntentShippingDetailsParams` with required properties.
 */
- (instancetype)initWithAddress:(STPPaymentIntentShippingDetailsAddressParams *)address name:(NSString *)name;

/**
 Use `initWithAddress:name:` instead.
 */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
