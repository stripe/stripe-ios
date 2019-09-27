//
//  STPPaymentResult.h
//  Stripe
//
//  Created by Jack Flintermann on 1/15/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol STPPaymentOption;
@class STPPaymentMethod;
@class STPPaymentMethodParams;

/**
 When you're using `STPPaymentContext` to request your user's payment details, this is the object that will be returned to your application when they've successfully made a payment.
 See https://stripe.com/docs/mobile/ios/standard#submit-payment-intents.
 */
@interface STPPaymentResult : NSObject

/**
 The payment method that the user has selected. This may come from a variety of different payment methods, such as an Apple Pay payment or a stored credit card. @see STPPaymentMethod.h
 If paymentMethod is nil, paymentMethodParams will be populated instead.
 */
@property (nonatomic, nullable, readonly) STPPaymentMethod *paymentMethod;

/**
 The parameters for a payment method that the user has selected. This is
 populated for non-reusable payment methods, such as FPX and iDEAL. @see STPPaymentMethodParams.h
 If paymentMethodParams is nil, paymentMethod will be populated instead.
 */
@property (nonatomic, nullable, readonly) STPPaymentMethodParams *paymentMethodParams;

/**
 The STPPaymentOption that was used to initialize this STPPaymentResult, either an STPPaymentMethod or an STPPaymentMethodParams.
 */
@property (nonatomic, nonnull, readonly) id<STPPaymentOption> paymentOption;

/**
 Initializes the payment result with a given payment option. This is invoked by `STPPaymentContext` internally; you shouldn't have to call it directly.
 */
- (instancetype)initWithPaymentOption:(id<STPPaymentOption>)paymentOption;

@end

NS_ASSUME_NONNULL_END
