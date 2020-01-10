//
//  STPConfirmPaymentMethodOptions.h
//  Stripe
//
//  Created by Cameron Sabol on 1/10/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPFormEncodable.h"

@class STPConfirmCardOptions;

NS_ASSUME_NONNULL_BEGIN

/**
 Options to update the associated PaymentMethod during PaymentIntent confirmation.
 @see https://stripe.com/docs/api/payment_intents/confirm#confirm_payment_intent-payment_method_options
 */
@interface STPConfirmPaymentMethodOptions : NSObject <STPFormEncodable>

/**
 Options to update a Card PaymentMethod.
 @see STPConfirmCardOptions
 */
@property (nonatomic, nullable) STPConfirmCardOptions *cardOptions;

@end

NS_ASSUME_NONNULL_END
