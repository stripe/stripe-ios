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

@class STPMandateDataParams, STPPaymentMethodParams;

/**
 An object representing parameters to confirm a SetupIntent object.
 
 For example, you would confirm a SetupIntent when a customer hits the “Save” button on a payment method management view in your app.
 
 If the selected payment method does not require any additional steps from the customer, the SetupIntent's status will transition to `STPSetupIntentStatusSucceeded`.  Otherwise, it will transition to `STPSetupIntentStatusRequiresAction`, and suggest additional actions via `nextAction`.
 Instead of passing this to `[STPAPIClient confirmSetupIntent...]` directly, we recommend using `STPPaymentHandler` to handle any additional steps for you.

 @see https://stripe.com/docs/api/setup_intents/confirm
 */
@interface STPSetupIntentConfirmParams : NSObject <NSCopying, STPFormEncodable>

/**
 Initialize this `STPSetupIntentConfirmParams` with a `clientSecret`.
 
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

/**
 A boolean number to indicate whether you intend to use the Stripe SDK's functionality to handle any SetupIntent next actions.
 If set to false, STPSetupIntent.nextAction will only ever contain a redirect url that can be opened in a webview or mobile browser.
 When set to true, the nextAction may contain information that the Stripe SDK can use to perform native authentication within your
 app.
 */
@property (nonatomic, nullable) NSNumber *useStripeSDK;

/**
 Details about the Mandate to create.
 @note If this value is null and the `(self.paymentMethod.type == STPPaymentMethodTypeSEPADebit | | self.paymentMethodParams.type == STPPaymentMethodTypeAUBECSDebit || self.paymentMethodParams.type == STPPaymentMethodTypeBacsDebit) && self.mandate == nil`, the SDK will set this to an internal value indicating that the mandate data should be inferred from the current context.
 */
@property (nonatomic, nullable) STPMandateDataParams *mandateData;

/**
 The ID of the Mandate to be used for this payment.
 
 @deprecated This parameter is not usable with publishable keys and will be ignored.
 */
@property (nonatomic, nullable) NSString *mandate DEPRECATED_MSG_ATTRIBUTE("Mandate IDs are not usable with publishable keys. Set them on your server using your secret key instead.");

@end

NS_ASSUME_NONNULL_END
