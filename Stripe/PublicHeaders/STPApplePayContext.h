//
//  STPApplePayContext.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 2/20/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPBlocks.h"

@class STPAPIClient, STPApplePayContext, STPPaymentMethod;

NS_ASSUME_NONNULL_BEGIN

/**
 Implement the required methods of this delegate to supply a PaymentIntent to STPApplePayContext and be notified of the completion of the Apple Pay payment.
 
 You may also implement the optional delegate methods to handle shipping methods and shipping address changes e.g. to verify you can ship to the address, or update the payment amount.
 */
@protocol STPApplePayContextDelegate <NSObject>

/**
 Called after the customer has authorized Apple Pay.  Implement this method to call the completion block with the client secret of a PaymentIntent representing the payment.
 
 @param paymentMethod                 The PaymentMethod that represents the customer's Apple Pay payment method.
 If you create the PaymentIntent with confirmation_method=manual, pass `paymentMethod.stripeId` as the payment_method and confirm=true. Otherwise, you can ignore this parameter.
 
 @param paymentInformation      The underlying PKPayment created by Apple Pay.
 If you create the PaymentIntent with confirmation_method=manual, you can collect shipping information using its `shippingContact` and `shippingMethod` properties.
 
 @param completion                        Call this with the PaymentIntent's client secret, or the error that occurred creating the PaymentIntent.
 */
- (void)applePayContext:(STPApplePayContext *)context
 didCreatePaymentMethod:(STPPaymentMethod *)paymentMethod
     paymentInformation:(PKPayment *)paymentInformation
             completion:(STPIntentClientSecretCompletionBlock)completion;

/**
 Called after the Apple Pay sheet is dismissed with the result of the payment.
 
 Your implementation could stop a spinner and display a receipt view or error to the customer, for example.
 
 @param status The status of the payment
 @param error The error that occurred, if any.
 */
- (void)applePayContext:(STPApplePayContext *)context
  didCompleteWithStatus:(STPPaymentStatus)status
                  error:(nullable NSError *)error;

@optional

/**
  Called when the user selects a new shipping method.  The delegate should determine
  shipping costs based on the shipping method and either the shipping address supplied in the original
  PKPaymentRequest or the address fragment provided by the last call to paymentAuthorizationViewController:
  didSelectShippingContact:completion:.
 
  You must invoke the completion block with an updated array of PKPaymentSummaryItem objects.
 */
- (void)applePayContext:(STPApplePayContext *)context
didSelectShippingMethod:(PKShippingMethod *)shippingMethod
                handler:(void (^)(PKPaymentRequestShippingMethodUpdate *update))handler;

/**
 Called when the user has selected a new shipping address.  You should inspect the
 address and must invoke the completion block with an updated array of PKPaymentSummaryItem objects.
 
 @note To maintain privacy, the shipping information is anonymized. For example, in the United States it only includes the city, state, and zip code. This provides enough information to calculate shipping costs, without revealing sensitive information until the user actually approves the purchase.
 Receive full shipping information in the paymentInformation passed to `applePayContext:didCreatePaymentMethod:paymentInformation:completion:`
 */
- (void)applePayContext:(STPApplePayContext *)context
didSelectShippingContact:(PKContact *)contact
                handler:(void (^)(PKPaymentRequestShippingContactUpdate *update))handler;

@end

/**
 A helper class that implements Apple Pay.
 
 Usage looks like this:
 1. Initialize this class with a PKPaymentRequest describing the payment request (amount, line items, required shipping info, etc)
 2. Call presentApplePayOnViewController:completion: to present the Apple Pay sheet and begin the payment process
 3 (optional): If you need to respond to the user changing their shipping information/shipping method, implement the optional delegate methods
 4. When the user taps 'Buy', this class uses the PaymentIntent that you supply in the applePayContext:didCreatePaymentMethod:completion: delegate method to complete the payment
 5. After payment completes/errors and the sheet is dismissed, this class informs you in the applePayContext:didCompleteWithStatus: delegate method
 
 @see https://stripe.com/docs/apple-pay#native for a full guide
 @see ApplePayExampleViewController for an example
 */
@interface STPApplePayContext : NSObject

/**
 Initializes this class.
 @note This may return nil if the request is invalid e.g. the user is restricted by parental controls, or can't make payments on any of the request's supported networks
  
 @param paymentRequest      The payment request to use with Apple Pay.
 @param delegate                    The delegate.
 */
- (nullable instancetype)initWithPaymentRequest:(PKPaymentRequest *)paymentRequest delegate:(id<STPApplePayContextDelegate>)delegate;

/**
 Use initWithPaymentRequest:delegate: instead.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 Use initWithPaymentRequest:delegate: instead.
 */
+ (instancetype)new NS_UNAVAILABLE;

/**
 Presents the Apple Pay sheet, starting the payment process.
 
 @note This method should only be called once; create a new instance of STPApplePayContext every time you present Apple Pay.
 @param viewController      The UIViewController instance to present the Apple Pay sheet on
 @param completion               Called after the Apple Pay sheet is presented
 */
- (void)presentApplePayOnViewController:(UIViewController *)viewController completion:(nullable STPVoidBlock)completion;

/**
 The STPAPIClient instance to use to make API requests to Stripe.
 Defaults to [STPAPIClient sharedClient].
 */
@property (nonatomic, null_resettable) STPAPIClient *apiClient;

@end

NS_ASSUME_NONNULL_END
