//
//  STPPaymentPresenter.h
//  Stripe
//
//  Created by Jack Flintermann on 11/25/14.
//  Copyright (c) 2014 Stripe, Inc. All rights reserved.
//

#ifdef STRIPE_ENABLE_APPLEPAY

#import <Foundation/Foundation.h>
#import "STPCheckoutOptions.h"
#import "STPToken.h"
#import "STPCheckoutProtocols.h"

typedef NS_ENUM(NSInteger, STPPaymentStatus) {
    STPPaymentStatusSuccess,      // The transaction was a success.
    STPPaymentStatusError,        // The transaction failed.
    STPPaymentStatusUserCanceled, // The user canceled the payment sheet.
};

@class PKPaymentRequest, STPPaymentPresenter;
@protocol STPPaymentPresenterDelegate;

/**
 *  This class allows you to request your user's payment details in the form of a Stripe token. If you give it a PKPaymentRequest and the user's device is
 capable of using Apple Pay, it'll automatically use that. If not, it will fall back to use Stripe Checkout. For both methods, it'll automatically turn the
 user's credit card into a Stripe token and give the token to its delegate.

 You'll need to add STRIPE_ENABLE_APPLEPAY to your app's build settings under "Preprocessor Macros" before using this class. For more information,
 see https://stripe.com/docs/mobile/ios#applepay

 Example use:

 // In your view controller
 PKPaymentRequest *paymentRequest = ...;
 STPCheckoutOptions *options = ...;
 STPPaymentPresenter *presenter = [[STPPaymentPresenter alloc] initWithCheckoutOptions:options
                                                                        paymentRequest:paymentRequest
                                                                              delegate:self];
 [presenter requestPaymentFromPresentingViewController:self];

 For more context, see ViewController.m in the StripeExample app (which uses STPPaymentPresenter).

 Other notes:
 - Stripe Checkout doesn't currently support collecting shipping address. If the `requiredShippingAddressFields` property of your PKPaymentRequest is non-nil,
 calling requestPaymentFromPresentingViewController: will raise an exception. Instead, collect this information ahead of time.
 */
@interface STPPaymentPresenter : NSObject

- (instancetype)initWithCheckoutOptions:(STPCheckoutOptions *)checkoutOptions
                         paymentRequest:(PKPaymentRequest *)paymentRequest
                               delegate:(id<STPPaymentPresenterDelegate>)delegate;

/**
 *  @param presentingViewController Calling this method will tell this view controller to present an appropriate payment view controller (either a
 * PKPaymentViewController or STPCheckoutViewController, depending on what the user's device supports) and collect payment details.
 */
- (void)requestPaymentFromPresentingViewController:(UIViewController *)presentingViewController;

@end

@protocol STPPaymentPresenterDelegate<NSObject>

/**
 *  This method will be called after the user successfully enters their payment information and it's turned into a Stripe token.
    Here, you should connect to your backend and use that token to charge the user. When your API call is finished, invoke the completion handler with either
 STPBackendChargeResultSuccess or STPBackendChargeResultFailure (optionally, including the NSError that caused the failure) depending on the results of your API
 call.
 *
 *  @param presenter  The payment presenter that has returned a token
 *  @param token      The returned Stripe token. See https://stripe.com/docs/tutorials/charges for more information on what to do with this on your backend.
 *  @param completion call this block when you're done talking to your backend.
 */
- (void)paymentPresenter:(STPPaymentPresenter *)presenter didCreateStripeToken:(STPToken *)token completion:(STPTokenSubmissionHandler)completion;

/**
 *  Here, you should respond to the results of the payment request. IMPORTANT: you are responsible for dismissing the payment view controller here. This gives
 you time to set up your UI depending on the results of the payment.

 Example use:
 [self dismissViewControllerAnimated:YES completion:^{
     if (error) {
         // alert the user to the error
     } else if (status == STPPaymentStatusSuccess) {
         // yay!
     } else {
        do nothing, as this means the user cancelled the request.
     }
 }];

 *
 *  @param presenter The payment presenter that has finished.
 *  @param status    This will be one of STPPaymentStatusSuccess, STPPaymentStatusError, or STPPaymentStatusUserCanceled depending on what happened with the
 user's transaction.
 *  @param error     This will only be set if status == STPPaymentStatusError. If you returned STPBackendChargeResultFailure from your API call above, this will
 be the error you (optionally) included there. If not, see StripeError.h for the possible values it may contain.
 */
- (void)paymentPresenter:(STPPaymentPresenter *)presenter didFinishWithStatus:(STPPaymentStatus)status error:(NSError *)error;

@optional

@end

#endif