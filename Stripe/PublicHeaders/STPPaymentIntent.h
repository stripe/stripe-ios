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
#import "STPPaymentMethodEnums.h"

NS_ASSUME_NONNULL_BEGIN

@class STPIntentAction;

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
 If `status == STPPaymentIntentStatusRequiresAction`, this
 property contains the next action to take for this PaymentIntent.
*/
@property (nonatomic, nullable, readonly) STPIntentAction *nextAction;

/**
 Email address that the receipt for the resulting payment will be sent to.
 */
@property (nonatomic, nullable, readonly) NSString *receiptEmail;

/**
 The Stripe ID of the Source used in this PaymentIntent.
 */
@property (nonatomic, nullable, readonly) NSString *sourceId;

/**
 The Stripe ID of the PaymentMethod used in this PaymentIntent.
 */
@property (nonatomic, nullable, readonly) NSString *paymentMethodId;

/**
 Status of the PaymentIntent
 */
@property (nonatomic, readonly) STPPaymentIntentStatus status;

/**
 The list of payment method types (e.g. `@[@(STPPaymentMethodTypeCard)]`) that this PaymentIntent is allowed to use.
 */
@property (nonatomic, nullable, readonly) NSArray<NSNumber *> *paymentMethodTypes;

/**
 When provided, this property indicates how you intend to use the payment method that your customer provides after the current payment completes. If applicable, additional authentication may be performed to comply with regional legislation or network rules required to enable the usage of the same payment method for additional payments.
 Use on_session if you intend to only reuse the payment method when the customer is in your checkout flow. Use off_session if your customer may or may not be in your checkout flow.
 */
@property (nonatomic, readonly) STPPaymentIntentSetupFutureUsage setupFutureUsage;

#pragma mark - Deprecated

/**
 If `status == STPPaymentIntentStatusRequiresAction`, this
 property contains the next source action to take for this PaymentIntent.
 
 @deprecated Use nextAction instead
 */
@property (nonatomic, nullable, readonly) STPIntentAction *nextSourceAction __attribute__((deprecated("Use nextAction instead", "nextAction")));

@end

NS_ASSUME_NONNULL_END
