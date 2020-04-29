//
//  STPPaymentIntentParams.h
//  Stripe
//
//  Created by Daniel Jackson on 7/3/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPFormEncodable.h"

NS_ASSUME_NONNULL_BEGIN

@class STPConfirmPaymentMethodOptions,
STPMandateDataParams,
STPSourceParams,
STPPaymentMethodParams,
STPPaymentResult,
STPPaymentIntentShippingDetailsParams;

/**
 An object representing parameters used to confirm a PaymentIntent object.

 A PaymentIntent must have a PaymentMethod or Source associated in order to successfully confirm it.

 That PaymentMethod or Source can either be:

 - created during confirmation, by passing in a `STPPaymentMethodParams` or `STPSourceParams` object in the `paymentMethodParams` or `sourceParams` field
 - a pre-existing PaymentMethod or Source can be associated by passing its id in the `paymentMethodId` or `sourceId` field
 - or already set via your backend, either when creating or updating the PaymentIntent

 @see https://stripe.com/docs/api#confirm_payment_intent
 */
@interface STPPaymentIntentParams : NSObject <NSCopying, STPFormEncodable>

/**
 Initialize this `STPPaymentIntentParams` with a `clientSecret`, which is the only required
 field.

 @param clientSecret the client secret for this PaymentIntent
 */
- (instancetype)initWithClientSecret:(NSString *)clientSecret;

/**
 The Stripe id of the PaymentIntent, extracted from the clientSecret.
 */
@property (nonatomic, copy, nullable, readonly) NSString *stripeId;

/**
 The client secret of the PaymentIntent. Required
 */
@property (nonatomic, copy) NSString *clientSecret;

/**
 Provide a supported `STPPaymentMethodParams` object, and Stripe will create a
 PaymentMethod during PaymentIntent confirmation.
 
 @note alternative to `paymentMethodId`
 */
@property (nonatomic, strong, nullable) STPPaymentMethodParams *paymentMethodParams;

/**
 Provide an already created PaymentMethod's id, and it will be used to confirm the PaymentIntent.
 
 @note alternative to `paymentMethodParams`
 */
@property (nonatomic, copy, nullable) NSString *paymentMethodId;

/**
 Provide an STPPaymentResult from STPPaymentContext, and this will populate
 the proper field (either paymentMethodId or paymentMethodParams) for your PaymentMethod.
 */
- (void)configureWithPaymentResult:(STPPaymentResult *)paymentResult;

/**
 Provide a supported `STPSourceParams` object into here, and Stripe will create a Source
 during PaymentIntent confirmation.

 @note alternative to `sourceId`
 */
@property (nonatomic, strong, nullable) STPSourceParams *sourceParams;

/**
 Provide an already created Source's id, and it will be used to confirm the PaymentIntent.

 @note alternative to `sourceParams`
 */
@property (nonatomic, copy, nullable) NSString *sourceId;

/**
 Email address that the receipt for the resulting payment will be sent to.
 */
@property (nonatomic, copy, nullable) NSString *receiptEmail;

/**
 `@YES` to save this PaymentIntent’s PaymentMethod or Source to the associated Customer,
 if the PaymentMethod/Source is not already attached.
 
 This should be a boolean NSNumber, so that it can be `nil`
 */
@property (nonatomic, strong, nullable) NSNumber *savePaymentMethod;

/**
 The URL to redirect your customer back to after they authenticate or cancel
 their payment on the payment method’s app or site.
 This should probably be a URL that opens your iOS app.
 */
@property (nonatomic, copy, nullable) NSString *returnURL;

/**
 When provided, this property indicates how you intend to use the payment method that your customer provides after the current payment completes.
 
 If applicable, additional authentication may be performed to comply with regional legislation or network rules required to enable the usage of the same payment method for additional payments.
 
 @see STPPaymentIntentSetupFutureUsage for more details on what values you can provide.
 */
@property (nonatomic, nullable) NSNumber *setupFutureUsage;

/**
 A boolean number to indicate whether you intend to use the Stripe SDK's functionality to handle any PaymentIntent next actions.
 If set to false, STPPaymentIntent.nextAction will only ever contain a redirect url that can be opened in a webview or mobile browser.
 When set to true, the nextAction may contain information that the Stripe SDK can use to perform native authentication within your
 app.
 */
@property (nonatomic, nullable) NSNumber *useStripeSDK;

/**
 Details about the Mandate to create.
 @note If this value is null and the (self.paymentMethod.type == STPPaymentMethodTypeSEPADebit | | self.paymentMethodParams.type == STPPaymentMethodTypeAUBECSDebit || self.paymentMethodParams.type == STPPaymentMethodTypeBacsDebit) && self.mandate == nil`, the SDK will set this to an internal value indicating that the mandate data should be inferred from the current context.
 */
@property (nonatomic, nullable) STPMandateDataParams *mandateData;

/**
 The ID of the Mandate to be used for this payment.
 */
@property (nonatomic, nullable) NSString *mandate;

/**
 Options to update the associated PaymentMethod during confirmation.
 @see STPPaymentMethodOptions
 */
@property (nonatomic, nullable) STPConfirmPaymentMethodOptions *paymentMethodOptions;

/**
 Shipping information.
 */
@property (nonatomic, nullable) STPPaymentIntentShippingDetailsParams *shipping;

/**
 The URL to redirect your customer back to after they authenticate or cancel
 their payment on the payment method’s app or site.

 This property has been renamed to `returnURL` and deprecated.
 */
@property (nonatomic, copy, nullable) NSString *returnUrl __attribute__((deprecated("returnUrl has been renamed to returnURL", "returnURL")));


/**
 `@YES` to save this PaymentIntent’s Source to the associated Customer,
 if the Source is not already attached.
 
 This should be a boolean NSNumber, so that it can be `nil`
 
 This property has been renamed to `savePaymentMethod` and deprecated.
 */
@property (nonatomic, strong, nullable) NSNumber *saveSourceToCustomer __attribute__((deprecated("saveSourceToCustomer has been renamed to savePaymentMethod", "saveSourceToCustomer")));

@end

NS_ASSUME_NONNULL_END
