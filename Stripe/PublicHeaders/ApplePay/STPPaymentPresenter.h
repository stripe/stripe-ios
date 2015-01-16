//
//  STPPaymentPresenter.h
//  Stripe
//
//  Created by Jack Flintermann on 11/25/14.
//

#import <Foundation/Foundation.h>
#import "STPCheckoutOptions.h"
#import "STPToken.h"
#import "STPCheckoutViewController.h"

@class PKPaymentRequest, PKPayment, STPPaymentPresenter;
@protocol STPPaymentPresenterDelegate;

/**
 *  This class allows you to request your user's payment details in the form of a Stripe token. If you give it a PKPaymentRequest and the user's device is
 capable of using Apple Pay, it'll automatically use that. If not, it will fall back to use Stripe Checkout. For both methods, it'll automatically turn the
 user's credit card into a Stripe token and give the token to its delegate.

 Example use:

 // In your view controller
 STPCheckoutOptions *options = ...;
 STPPaymentPresenter *presenter = [[STPPaymentPresenter alloc] initWithCheckoutOptions:options
                                                                              delegate:self];
 [presenter requestPaymentFromPresentingViewController:self];

 For more context, see ViewController.swift in the Simple iOS Example app (which uses STPPaymentPresenter).

 */
@interface STPPaymentPresenter : NSObject

/**
 *  Initializes a payment presenter.
 *
 *  @param checkoutOptions These options will configure the appearance of Apple Pay and Stripe Checkout. Cannot be nil.
 *  @param delegate        A delegate to receive callbacks around payment creation events. Cannot be nil. For more information see STPPaymentPresenterDelegate
 *below.
 *
 *  @return The presenter. After initialization, one cannot modify the checkoutOptions or delegate properties.
 */
- (instancetype)initWithCheckoutOptions:(STPCheckoutOptions *)checkoutOptions delegate:(id<STPPaymentPresenterDelegate>)delegate;
@property (nonatomic, weak, readonly) id<STPPaymentPresenterDelegate> delegate;
@property (nonatomic, copy, readonly) STPCheckoutOptions *checkoutOptions;

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
 *  @param token      The returned Stripe token. See https://stripe.com/docs/tutorials/charges for more information on what to do with this on your backend. If
 the user used Apple Pay to purchase, the returned PKPayment will be attached to the token. Otherwise, it will be nil.
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
 *  @param status    This will be one of STPPaymentStatusSuccess, STPPaymentStatusError, or STPPaymentStatusUserCancelled depending on what happened with the
 user's transaction.
 *  @param error     This will only be set if status == STPPaymentStatusError. If you returned STPBackendChargeResultFailure from your API call above, this will
 be the error you (optionally) included there. If not, see StripeError.h for the possible values it may contain.
 */
- (void)paymentPresenter:(STPPaymentPresenter *)presenter didFinishWithStatus:(STPPaymentStatus)status error:(NSError *)error;

@optional

/**
 *  When the user's device is capable of using Apple Pay, STPPaymentPresenter will automatically generate a PKPaymentRequest object based on the
 *STPCheckoutOptions you initialized it with. The default is for the request to have 2 PKPaymentSummaryItems: one for the item being purchased (e.g. "BEATS
 *HEADPHONES - $200"), followed one with the name of your company for the total amount (e.g. "PAY APPLE $200"). If you'd like to change this (for example, to
 *display a more itemized receipt that breaks down the sales tax, etc), you can modify the
 *paymentSummaryItems property of the paymentRequest here.

 *
 *  @param  presenter the presenter that is deciding which payment UI to display.
 *  @param  request   the payment request that has been generated from the presenters checkoutOptions
 *  @return the modified payment request to display.
 */
- (PKPaymentRequest *)paymentPresenter:(STPPaymentPresenter *)presenter didPreparePaymentRequest:(PKPaymentRequest *)request;

@end
