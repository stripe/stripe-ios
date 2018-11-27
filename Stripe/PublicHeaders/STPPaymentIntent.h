//
//  STPPaymentIntent.h
//  Stripe
//
//  Created by Daniel Jackson on 6/27/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"
#import "STPPaymentIntentEnums.h"

NS_ASSUME_NONNULL_BEGIN

@class STPPaymentIntentSourceAction;

/**
 A PaymentIntent tracks the process of collecting a payment from your customer.

 @see https://stripe.com/docs/api#payment_intents
 @see https://stripe.com/docs/payments/dynamic-authentication
 */
@interface STPPaymentIntent : NSObject<STPAPIResponseDecodable>

/**
 You cannot directly instantiate an `STPPaymentIntent`. You should only use one that
 has been returned from an `STPAPIClient` callback.
 */
- (instancetype)init __attribute__((unavailable("You cannot directly instantiate an STPPaymentIntent. You should only use one that has been returned from an STPAPIClient callback.")));

/**
 The Stripe ID of the PaymentIntent.
 */
@property (nonatomic, readonly) NSString *stripeId;

/**
 The client secret used to fetch this PaymentIntent
 */
@property (nonatomic, readonly) NSString *clientSecret;

/**
 Amount intended to be collected by this PaymentIntent.
 */
@property (nonatomic, readonly) NSNumber *amount;

/**
 If status is `STPPaymentIntentStatusCanceled`, when the PaymentIntent was canceled.
 */
@property (nonatomic, nullable, readonly) NSDate *canceledAt;

/**
 Capture method of this PaymentIntent
 */
@property (nonatomic, readonly) STPPaymentIntentCaptureMethod captureMethod;

/**
 Confirmation method of this PaymentIntent
 */
@property (nonatomic, readonly) STPPaymentIntentConfirmationMethod confirmationMethod;

/**
 When the PaymentIntent was created.
 */
@property (nonatomic, nullable, readonly) NSDate *created;

/**
 The currency associated with the PaymentIntent.
 */
@property (nonatomic, readonly) NSString *currency;

/**
 The `description` field of the PaymentIntent.
 An arbitrary string attached to the object. Often useful for displaying to users.
 */
@property (nonatomic, nullable, readonly) NSString *stripeDescription;

/**
 Whether or not this PaymentIntent was created in livemode.
 */
@property (nonatomic, readonly) BOOL livemode;

/**
 If `status == STPPaymentIntentStatusRequiresSourceAction`, this
 property contains the next action to take for this PaymentIntent.
 */
@property (nonatomic, nullable, readonly) STPPaymentIntentSourceAction* nextSourceAction;

/**
 Email address that the receipt for the resulting payment will be sent to.
 */
@property (nonatomic, nullable, readonly) NSString *receiptEmail;

/**
 The Stripe ID of the Source used in this PaymentIntent.
 */
@property (nonatomic, nullable, readonly) NSString *sourceId;

/**
 Status of the PaymentIntent
 */
@property (nonatomic, readonly) STPPaymentIntentStatus status;

@end

NS_ASSUME_NONNULL_END
