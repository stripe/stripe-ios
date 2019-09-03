//
//  STPAPIClient+ApplePay.h
//  Stripe
//
//  Created by Jack Flintermann on 12/19/14.
//

#import <Foundation/Foundation.h>
#import <PassKit/PassKit.h>

#import "STPAPIClient.h"

NS_ASSUME_NONNULL_BEGIN

/**
 STPAPIClient extensions to create Stripe Tokens, Sources, or PaymentMethods from Apple Pay PKPayment objects.
 */
@interface STPAPIClient (ApplePay)

/**
 Converts a PKPayment object into a Stripe token using the Stripe API.

 @param payment     The user's encrypted payment information as returned from a PKPaymentAuthorizationViewController. Cannot be nil.
 @param completion  The callback to run with the returned Stripe token (and any errors that may have occurred).
 */
- (void)createTokenWithPayment:(PKPayment *)payment
                    completion:(STPTokenCompletionBlock)completion;

/**
 Converts a PKPayment object into a Stripe source using the Stripe API.

 @param payment     The user's encrypted payment information as returned from a PKPaymentAuthorizationViewController. Cannot be nil.
 @param completion  The callback to run with the returned Stripe source (and any errors that may have occurred).
 */
- (void)createSourceWithPayment:(PKPayment *)payment
                     completion:(STPSourceCompletionBlock)completion;

/**
 Converts a PKPayment object into a Stripe Payment Method using the Stripe API.
 
 @param payment     The user's encrypted payment information as returned from a PKPaymentAuthorizationViewController. Cannot be nil.
 @param completion  The callback to run with the returned Stripe source (and any errors that may have occurred).
 */
- (void)createPaymentMethodWithPayment:(PKPayment *)payment
                            completion:(STPPaymentMethodCompletionBlock)completion;

/**
 Converts Stripe errors into the appropriate Apple Pay error, for use in `PKPaymentAuthorizationResult`. The error is displayed in the Apple Pay sheet, and the user can try again.
 
 We can convert billing address related errors into a PKPaymentError that helpfully points to the billing address field in the Apple Pay sheet.
 All other errors map to PKPaymentUnknownError, resulting in a generic error message in the Apple Pay sheet.
 
 Apple Pay should prevent most card errors (e.g. invalid CVC) when you add a card to the wallet.
 
 @param stripeError   An error from the Stripe SDK.
 @see ApplePayExampleViewController for an example of how to use this method in your Apple Pay integration.
 */
+ (nullable NSError *)pkPaymentErrorForStripeError:(nullable NSError *)stripeError API_AVAILABLE(ios(11.0), watchos(4.0));

@end

NS_ASSUME_NONNULL_END

/**
 This function should not be called directly.
 
 It is used by the SDK when it is built as a static library to force the
 compiler to link in category methods regardless of the integrating
 app's compiler flags.
 */
void linkSTPAPIClientApplePayCategory(void);
