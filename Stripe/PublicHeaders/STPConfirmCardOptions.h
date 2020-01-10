//
//  STPConfirmCardOptions.h
//  Stripe
//
//  Created by Cameron Sabol on 1/10/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPFormEncodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Options to update a Card PaymentMethod during PaymentIntent confirmation.
 @see https://stripe.com/docs/api/payment_intents/confirm#confirm_payment_intent-payment_method_options-card
 */
@interface STPConfirmCardOptions : NSObject <STPFormEncodable>

/**
 CVC value with which to update the Card PaymentMethod.
 */
@property (nonatomic, nullable, copy) NSString *cvc;

@end

NS_ASSUME_NONNULL_END
