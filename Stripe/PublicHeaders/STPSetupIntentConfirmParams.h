//
//  STPSetupIntentConfirmParams.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 6/27/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPFormEncodable.h"

NS_ASSUME_NONNULL_BEGIN

@class STPPaymentMethodParams;

/**
 An object representing parameters to confirm a SetupIntent object.
 
 For example, you would confirm a SetupIntent when a customer hits the “Save” button on a payment method management view in your app.
 
 If the selected payment method does not require any additional steps from the customer, the SetupIntent's status will transition to `STPSetupIntentStatusSucceeded`.  Otherwise, it will transition to `STPSetupIntentStatusRequiresAction`, and suggest additional actions via `nextAction`.
 Instead of passing this to `[STPAPIClient confirmSetupIntent...]` directly, we recommend using `STPPaymentHandler` to handle any additional steps for you.

 @see https://stripe.com/docs/api/setup_intents/confirm
 */
@interface STPSetupIntentConfirmParams : NSObject <STPFormEncodable>

/**
 Initialize this `STPSetupIntentParams` with a `clientSecret`.
 
 @param clientSecret the client secret for this SetupIntent
 */
- (instancetype)initWithClientSecret:(NSString *)clientSecret;

/**
 The client secret of the SetupIntent. Required.
 */
@property (nonatomic, copy) NSString *clientSecret;

/**
 Provide a supported `STPPaymentMethodParams` object, and Stripe will create a
 PaymentMethod during PaymentIntent confirmation.
 
 @note alternative to `paymentMethodId`
 */
@property (nonatomic, strong, nullable) STPPaymentMethodParams *paymentMethodParams;

/**
 Provide an already created PaymentMethod's id, and it will be used to confirm the SetupIntent.
 
 @note alternative to `paymentMethodParams`
 */
@property (nonatomic, copy, nullable) NSString *paymentMethodID;

/**
 The URL to redirect your customer back to after they authenticate or cancel
 their payment on the payment method’s app or site.
 
 This should probably be a URL that opens your iOS app.
 */
@property (nonatomic, copy, nullable) NSString *returnURL;

@end

NS_ASSUME_NONNULL_END
