//
//  Stripe+ApplePay.h
//  Stripe
//
//  Created by Jack Flintermann on 9/17/14.
//

#import <Foundation/Foundation.h>
#import <PassKit/PassKit.h>

#import "Stripe.h"
#import "STPAPIClient+ApplePay.h"


@class Stripe;

@interface Stripe (ApplePay)

/**
 *  Whether or not this device is capable of using Apple Pay. This checks both whether the user is running an iPhone 6/6+ or later, iPad Air 2 or later, or iPad
 *mini 3 or later, as well as whether or not they have stored any cards in Apple Pay on their device.
 *
 *  @param paymentRequest The return value of this method depends on the supportedNetworks property of this payment request, which by default should be
 *@[PKPaymentNetworkAmex, PKPaymentNetworkMasterCard, PKPaymentNetworkVisa].
 *
 *  @return whether or not the user is currently able to pay with Apple Pay.
 */
+ (BOOL)canSubmitPaymentRequest:(nullable PKPaymentRequest *)paymentRequest;

/**
 *  A convenience method to return a PKPaymentRequest with sane default values. You will still need to configure the paymentSummaryItems property to indicate
 *what the user is purchasing, as well as the optional requiredShippingAddressFields, requiredBillingAddressFields, and shippingMethods properties to indicate
 *what contact information your application requires.
 *
 *  @param merchantIdentifier Your Apple Merchant ID, as obtained at https://developer.apple.com/account/ios/identifiers/merchant/merchantCreate.action
 *
 *  @return a PKPaymentRequest with proper default values. Returns nil if running on < iOS8.
 */
+ (nullable PKPaymentRequest *)paymentRequestWithMerchantIdentifier:(nonnull NSString *)merchantIdentifier;

#pragma mark - deprecated methods

/**
 *  Securely convert your user's Apple Pay payment information into a Stripe token, which you can then safely store on your server and use to charge the user.
 *  The URL connection will run on the main queue. Uses the value of [Stripe defaultPublishableKey] for authentication.
 *
 *  @param payment The PKPayment instance to convert, as returned from a PKPaymentAuthorizationViewController
 *  @param handler Code to run when the token has been returned (along with any errors encountered).
 *  @deprecated use [[STPAPIClient sharedClient] createTokenWithPayment:completion:] instead.
 */
+ (void)createTokenWithPayment:(nonnull PKPayment *)payment completion:(nonnull STPCompletionBlock)handler __attribute__((deprecated));

/**
 *  Securely convert your user's Apple Pay payment information into a Stripe token, which you can then safely store on your server and use to charge the user.
 *  The URL connection will run on the main queue. Uses the value of [Stripe defaultPublishableKey] for authentication.
 *
 *  @param payment The PKPayment instance to convert, as returned from a PKPaymentAuthorizationViewController
 *  @param queue   The operation queue on which to run completion blocks passed to the api client. 
 *  @param handler Code to run when the token has been returned (along with any errors encountered).
 *  @deprecated use [[STPAPIClient sharedClient] createTokenWithPayment:completion:] instead.
 */
+ (void)createTokenWithPayment:(nonnull PKPayment *)payment operationQueue:(nonnull NSOperationQueue *)queue completion:(nonnull STPCompletionBlock)handler __attribute__((deprecated));

@end

void linkStripeApplePayCategory(void);
