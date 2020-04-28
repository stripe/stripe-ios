//
//  STPPaymentIntentShippingDetailsAddress.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 4/27/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Shipping address for a PaymentIntent's shipping details.
 
 @see https://stripe.com/docs/api/payment_intents/object#payment_intent_object-shipping
 */
@interface STPPaymentIntentShippingDetailsAddress : NSObject <STPAPIResponseDecodable>

/**
 City/District/Suburb/Town/Village.
*/
@property (nonatomic, copy, nullable, readonly) NSString *city;

/**
 Two-letter country code (ISO 3166-1 alpha-2).
 */
@property (nonatomic, copy, nullable, readonly) NSString *country;

/**
 Address line 1 (Street address/PO Box/Company name).
 */
@property (nonatomic, copy, nullable, readonly) NSString *line1;

/**
 Address line 2 (Apartment/Suite/Unit/Building).
 */
@property (nonatomic, copy, nullable, readonly) NSString *line2;

/**
 ZIP or postal code.
 */
@property (nonatomic, copy, nullable, readonly) NSString *postalCode;

/**
 State/County/Province/Region.
 */
@property (nonatomic, copy, nullable, readonly) NSString *state;

/**
 You cannot directly instantiate an `STPPaymentIntentShippingDetailsAddress`.
 You should only use one that is part of an existing `STPPaymentMethod` object.
 */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
