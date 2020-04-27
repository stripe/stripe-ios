//
//  STPPaymentIntentShippingDetailsAddressParams.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 4/27/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPFormEncodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
Shipping address for a PaymentIntent's shipping details.

@see https://stripe.com/docs/api/payment_intents/confirm#confirm_payment_intent-shipping-address
*/
@interface STPPaymentIntentShippingDetailsAddressParams : NSObject <STPFormEncodable>

/**
 City/District/Suburb/Town/Village.
*/
@property (nonatomic, copy, nullable, readwrite) NSString *city;

/**
 Two-letter country code (ISO 3166-1 alpha-2).
 */
@property (nonatomic, copy, nullable, readwrite) NSString *country;

/**
 Address line 1 (Street address/PO Box/Company name).
 */
@property (nonatomic, copy, readwrite) NSString *line1;

/**
 Address line 2 (Apartment/Suite/Unit/Building).
 */
@property (nonatomic, copy, nullable, readwrite) NSString *line2;

/**
 ZIP or postal code.
 */
@property (nonatomic, copy, nullable, readwrite) NSString *postalCode;

/**
 State/County/Province/Region.
 */
@property (nonatomic, copy, nullable, readwrite) NSString *state;

@end

NS_ASSUME_NONNULL_END
