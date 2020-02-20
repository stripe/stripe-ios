//
//  STPApplePayContext.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 2/20/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPBlocks.h"

@class STPAPIClient, STPApplePayContext;

NS_ASSUME_NONNULL_BEGIN

@protocol STPApplePayContextDelegate <NSObject>

/**
 Implement this method to call the completion block with the client secret of a PaymentIntent representing the payment, created on your backend.
 
 @param paymentMethodID       The identifier of the PaymentMethod that represents the customer's Apple Pay payment method. You may optionally use this to confirm the PaymentIntent server-side.
 If you create the PaymentIntent with confirmation_method=manual, pass this as the payment_method and confirm=true.
 @param completion                  Call this with the PaymentIntent's client secret or an error.

 The SDK will call this method when the user attempts to complete the payment.
 */
- (void)applePayContextNeedsPaymentIntent:(STPApplePayContext *)context
                            paymentMethod:(NSString *)paymentMethodID
                               completion:(STPPaymentIntentClientSecretCompletionBlock)completion;

/**
 Called after the Apple Pay sheet is dismissed with the result of the payment.
 
 Your implementation could stop a spinner and display a receipt view or error to the customer, for example.
 
 @param status The status of the payment
 @param error The error that occurred, if any.
 */
- (void)applePayContextDidComplete:(STPApplePayContext *)context
                            status:(STPPaymentStatus)status
                             error:(nullable NSError *)error;

@optional

/**
  Called when the user selects a new shipping method.  The delegate should determine
  shipping costs based on the shipping method and either the shipping address supplied in the original
  PKPaymentRequest or the address fragment provided by the last call to paymentAuthorizationViewController:
  didSelectShippingContact:completion:.
 
  The delegate must invoke the completion block with an updated array of PKPaymentSummaryItem objects.
 */
- (void)applePayContext:(STPApplePayContext *)context
didSelectShippingMethod:(PKShippingMethod *)shippingMethod
                handler:(void (^)(PKPaymentRequestShippingMethodUpdate *update))completion API_AVAILABLE(ios(11.0), watchos(4.0));

/**
 Implement this to let the user
 Sent when the user has selected a new shipping address.  The delegate should inspect the
 address and must invoke the completion block with an updated array of PKPaymentSummaryItem objects.
 */
- (void)applePayContext:(STPApplePayContext *)context
didSelectShippingContact:(PKContact *)contact
                handler:(void (^)(PKPaymentRequestShippingContactUpdate *update))completion API_AVAILABLE(ios(11.0), watchos(4.0));

/**
 A pre-iOS 11 version of paymentAuthorizationViewController:didSelectShippingContact:handler:
 */
- (void)applePayContext:(STPApplePayContext *)context
didSelectShippingContact:(PKContact *)contact
             completion:(void (^)(PKPaymentAuthorizationStatus status, NSArray<PKShippingMethod *> *shippingMethods,
                                  NSArray<PKPaymentSummaryItem *> *summaryItems))completion API_DEPRECATED("Use paymentAuthorizationViewController:didSelectShippingContact:handler: instead to provide more granular errors", ios(9.0, 11.0));

/**
 A pre-iOS 11 version of paymentAuthorizationViewController:didSelectShippingMethod:handler:
 */
- (void)applePayContext:(STPApplePayContext *)context
didSelectShippingMethod:(PKShippingMethod *)shippingMethod
             completion:(void (^)(PKPaymentAuthorizationStatus status, NSArray<PKPaymentSummaryItem *> *summaryItems))completion API_DEPRECATED("Use paymentAuthorizationViewController:didSelectShippingMethod:handler: instead to provide more granular errors", ios(8.0, 11.0));

@end

@interface STPApplePayContext : NSObject

- (nullable instancetype)initWithPaymentRequest:(PKPaymentRequest *)paymentRequest
                                                  delegate:(id<STPApplePayContextDelegate>)delegate;

- (instancetype)init NS_UNAVAILABLE;

- (void)presentApplePayOnViewController:(UIViewController *)viewController completion:(nullable STPVoidBlock)completion;

@property (nonatomic, null_resettable) STPAPIClient *apiClient;

@end

NS_ASSUME_NONNULL_END
