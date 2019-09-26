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
 */
@property (nonatomic, nullable, readonly) STPPaymentMethod *paymentMethod;

/**
 tktktktktktktktktk
 */
@property (nonatomic, nullable, readonly) STPPaymentMethodParams *paymentMethodParams;

/**
 tktktktktktktktktk
 */
@property (nonatomic, nonnull, readonly) id<STPPaymentOption> paymentOption;

/**
 Initializes the payment result with a given source. This is invoked by `STPPaymentContext` internally; you shouldn't have to call it directly.
 */
- (instancetype)initWithPaymentOption:(id<STPPaymentOption>)paymentOption;

@end

NS_ASSUME_NONNULL_END
