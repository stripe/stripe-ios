//
//  STPPaymentContext.h
//  Stripe
//
//  Created by Jack Flintermann on 4/20/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "STPPaymentMethod.h"
#import "STPBlocks.h"
#import "STPAddress.h"
#import "STPPaymentConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@class STPPaymentContext, STPAPIClient, STPTheme;
@protocol STPBackendAPIAdapter, STPPaymentMethod;

/**
 *  This is invoked by an STPPaymentContext when it's done obtaining a valid `source` with which to complete a payment. Inside this block, you should make a call to your backend API to make a charge with that source, and invoke the sourceCompletion block when that is done.
 *
 *  @param paymentMethod    the type of payment method that the user selected.
 *  @param source           the source that the user selected - this might be a card that is already attached to a customer (e.g. "card_abc123") or an Apple Pay token (e.g. "tok_def456") but either way you can pass this value directly into the Charge Create API: https://stripe.com/docs/api#create_charge
 *  @param sourceCompletion call this block when you're done creating a charge on your backend. If it succeeded, call sourceCompletion(nil). If it failed with an errorm call sourceCompletion(error).
 */
typedef void (^STPSourceHandlerBlock)(STPPaymentMethodType paymentMethod, id<STPSource> __nonnull source, STPErrorBlock __nonnull sourceCompletion);

/**
 *  This is invoked by an STPPaymentContext when a payment is completed.
 *
 *  @param status the status of the payment - STPPaymentStatusSuccess if it succeeded, STPPaymentStatusError if it failed with an error (in which case the `error` parameter will be non-nil), STPPaymentStatusUserCanceled if the user canceled the payment.
 *  @param error  an error that occurred when finishing the payment, if any.
 *  @see the documentation for requestPaymentFromViewController in STPPaymentContext
 */
typedef void (^STPPaymentCompletionBlock)(STPPaymentStatus status, NSError * __nullable error);

/**
 *  Implement STPPaymentContextDelegate to get notified when a payment context's contents change. In practice, if your app has a "checkout page view controller", that is a good candidate to implement this protocol.
 */
@protocol STPPaymentContextDelegate <NSObject>

/**
 *  Called when the payment context begins loading. You could tell a UIActivityIndicatorView to start animating when this is called.
 *
 *  @param paymentContext the payment context that began loading.
 */
- (void)paymentContextDidBeginLoading:(STPPaymentContext *)paymentContext;

/**
 *  Called when the payment context encounters an error when fetching its initial set of data. If you're showing the user a checkout page, you could dismiss the checkout page when this is called and present the error to the user. To make it harder to get your UI into an inconsistent state, this won't be called until you've called -didAppear on the payment context.
 *
 *  @param paymentContext the payment context that encountered the error
 *  @param error          the error that was encountered
 */
- (void)paymentContext:(STPPaymentContext *)paymentContext didFailToLoadWithError:(NSError *)error;

/**
 *  Called when the payment context is done loading. You could tell a UIActivityIndicatorView to stop animating when this is called.
 *
 *  @param paymentContext the payment context that finished loading.
 */
- (void)paymentContextDidEndLoading:(STPPaymentContext *)paymentContext;

/**
 *  This is called every time the contents of the payment context change. When this is called, you should update your app's UI to reflect the current state of the payment context. For example, if you have a checkout page with a "selected payment method" row, you should update its payment method with `paymentContext.selectedPaymentMethod.label`. If that checkout page has a "buy" button, you should enable/disable it depending on the result of [paymentContext isReadyForPayment].
 *
 *  @param paymentContext the payment context that changed
 */
- (void)paymentContextDidChange:(STPPaymentContext *)paymentContext;

@end

/**
 An STPPaymentContext keeps track of all of the state around a payment. It will manage fetching a user's saved payment methods, tracking any information they select, and prompting them for required additional information before completing their purchase. It can be used to power your application's "payment confirmation" page with just a few lines of code. It requires an "API Adapter" to communicate with your backend API to retrieve and modify a customer's payment methods - see STPBackendAPIAdapter.h for how to implement this. You can also see CheckoutViewController.swift in our example app to see STPPaymentContext in action.
 */
@interface STPPaymentContext : NSObject

- (instancetype)initWithAPIAdapter:(id<STPBackendAPIAdapter>)apiAdapter
                     configuration:(STPPaymentConfiguration *)configuration;

@property(nonatomic, readonly)id<STPBackendAPIAdapter> apiAdapter;

@property(nonatomic, readonly)STPPaymentConfiguration *configuration;

/**
 *  This delegate will be notified when the payment context's contents change. @see STPPaymentContextDelegate
 */
@property(nonatomic, weak, nullable)id<STPPaymentContextDelegate> delegate;

/**
 *  Whether or not the payment context is currently loading information from the network.
 */
@property(nonatomic, readonly, getter=isLoading)BOOL loading;

/**
 *  The user's currently selected payment method. May be nil.
 */
@property(nonatomic, readonly, nullable)id<STPPaymentMethod> selectedPaymentMethod;

/**
 *  The available payment methods the user can choose between. May be nil.
 */
@property(nonatomic, readonly, nullable)NSArray<id<STPPaymentMethod>> *paymentMethods;

/**
 *  The amount of money you're requesting from the user, in the smallest currency unit for the selected currency. For example, to indicate $10 USD, use 1000 (i.e. 1000 cents). For more information see https://stripe.com/docs/api#charge_object-amount . This value must be present and greater than zero in order for Apple Pay to be automatically enabled.
 */
@property(nonatomic)NSInteger paymentAmount;

/**
 *  The three-letter currency code for the currency of the payment (i.e. USD, GBP, JPY, etc). Defaults to USD.
 */
@property(nonatomic, copy)NSString *paymentCurrency;

/**
 *  You must call this method on your payment context when the view controller it's powering is about to appear. This tells the payment context to begin fetching the data it needs. A good time to call this is in the -viewWillAppear: method of that view controller.
 */
- (void)willAppear;

/**
 *  You must call this method on your payment context when the view controller it's powering has finished appearing. A good time to call this is in the -viewDidAppear: method of that view controller.
 */
- (void)didAppear;

/**
 *  This creates, configures, and appropriately presents an STPPaymentMethodsViewController on top of the view controller that you specify. It'll be dismissed automatically when the user is done selecting their payment method.
 *
 *  @param viewController the view controller on which to present the STPPaymentMethodsViewController
 */
- (void)presentPaymentMethodsViewControllerOnViewController:(UIViewController *)viewController;

/**
 *  This creates, configures, and appropriately pushes an STPPaymentMethodsViewController onto the navigation stack of the view controller that you specify. It'll be popped automatically when the user is done selecting their payment method.
 *
 *  @param navigationController the view controller on which to present the STPPaymentMethodsViewController
 */
- (void)pushPaymentMethodsViewControllerOntoNavigationController:(UINavigationController *)navigationController;

/**
 *  Whether or not the payment context contains all of the information it needs to complete a payment. For example, you can use the result of this method to enable/disable the "buy" button on a checkout page.
 */
- (BOOL)isReadyForPayment;

/**
 *  Attempts to finalize the payment. This may need to present some supplemental UI to the user. For instance, if they've selected Apple Pay as their payment method, calling this method will show the payment sheet. If the user has a card on file, this will use that without presenting any additional UI. You should create a charge with the provided source in the `sourceHandler` block, and update your UI in the `completion` block. For an example of this, see CheckoutViewController.swift in our example app.
 *
 *  @param fromViewController The view controller that is onscreen when this method is invoked. The payment context may call `presentViewController` on this view controller to show any required additional UI.
 *  @param sourceHandler      This block will yield you the `source` the user has selected, along with the type of payment method they've chosen. You should go to your backend API with this `source` and make a charge to complete the payment, and once that's done call `sourceCompletion` with any error that occurred (or none, if the charge succeeded).
 *  @param completion         This will be called after the payment is done and all necessary UI has been dismissed. You should inspect the `status` of the payment and behave appropriately. For example: if it's STPPaymentStatusSuccess, show the user a receipt. If it's STPPaymentStatusError, inform the user of the error. If it's STPPaymentStatusUserCanceled, do nothing.
 */
- (void)requestPaymentFromViewController:(UIViewController *)fromViewController
                           sourceHandler:(STPSourceHandlerBlock)sourceHandler
                              completion:(STPPaymentCompletionBlock)completion;


@end

NS_ASSUME_NONNULL_END
