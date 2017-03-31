//
//  STPPaymentContext.h
//  Stripe
//
//  Created by Jack Flintermann on 4/20/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <PassKit/PassKit.h>

#import "STPAddress.h"
#import "STPBlocks.h"
#import "STPPaymentConfiguration.h"
#import "STPPaymentMethod.h"
#import "STPPaymentResult.h"
#import "STPUserInformation.h"

NS_ASSUME_NONNULL_BEGIN

@class STPPaymentContext, STPTheme;
@protocol STPBackendAPIAdapter, STPPaymentMethod, STPPaymentContextDelegate;

/**
 An `STPPaymentContext` keeps track of all of the state around a payment. It will manage fetching a user's saved payment methods, tracking any information they select, and prompting them for required additional information before completing their purchase. It can be used to power your application's "payment confirmation" page with just a few lines of code.
 
 `STPPaymentContext` also provides a unified interface to multiple payment methods - for example, you can write a single integration to accept both credit card payments and Apple Pay.
 
 `STPPaymentContext` requires an "API Adapter" to communicate with your backend API to retrieve and modify a customer's payment methods - see https://stripe.com/docs/mobile/ios/standard#prepare-your-api for how to implement this. You can also look at CheckoutViewController.swift in our example app to see `STPPaymentContext` in action.
 */
NS_EXTENSION_UNAVAILABLE("STPPaymentContext is not available in extensions")
@interface STPPaymentContext : NSObject

/**
 *  This is a convenience initializer; it is equivalent to calling `initWithAPIAdapter:apiAdapter configuration:[STPPaymentConfiguration sharedConfiguration] theme:[STPTheme defaultTheme]`.
 *
 */
- (instancetype)initWithAPIAdapter:(id<STPBackendAPIAdapter>)apiAdapter;

/**
 *  Initializes a new Payment Context with the provided API adapter and configuration. After this class is initialized, you should also make sure to set its `delegate` and `hostViewController` properties.
 *
 *  @param apiAdapter    The API adapter the payment context will use to fetch and modify its contents. You need to make a class conforming to this protocol that talks to your server. @see STPBackendAPIAdapter.h
 *  @param configuration The configuration for the payment context to use. This lets you set your Stripe publishable API key, required billing address fields, etc. @see STPPaymentConfiguration.h
 *  @param theme         The theme describing the visual appearance of all UI that the payment context automatically creates for you. @see STPTheme.h
 *
 *  @return the newly-instantiated payment context
 */
- (instancetype)initWithAPIAdapter:(id<STPBackendAPIAdapter>)apiAdapter
                     configuration:(STPPaymentConfiguration *)configuration
                             theme:(STPTheme *)theme;

/**
 *  The API adapter the payment context will use to fetch and modify its contents. You need to make a class conforming to this protocol that talks to your server. @see STPBackendAPIAdapter.h
 */
@property(nonatomic, readonly)id<STPBackendAPIAdapter> apiAdapter;

/**
 *  The configuration for the payment context to use internally. @see STPPaymentConfiguration.h
 */
@property(nonatomic, readonly)STPPaymentConfiguration *configuration;

/**
 *  The visual appearance that will be used by any views that the context generates. @see STPTheme.h
 */
@property(nonatomic, readonly)STPTheme *theme;

/**
 *  If you've already collected some information from your user, you can set it here and it'll be automatically filled out when possible/appropriate in any UI that the payment context creates.
 */
@property(nonatomic, strong, nullable)STPUserInformation *prefilledInformation;

/**
 *  The view controller that any additional UI will be presented on. If you have a "checkout view controller" in your app, that should be used as the host view controller.
 */
@property(nonatomic, weak, nullable)UIViewController *hostViewController;

/**
 *  This delegate will be notified when the payment context's contents change. @see STPPaymentContextDelegate
 */
@property(nonatomic, weak, nullable)id<STPPaymentContextDelegate> delegate;

/**
 *  Whether or not the payment context is currently loading information from the network.
 */
@property(nonatomic, readonly)BOOL loading;

/**
 *  The user's currently selected payment method. May be nil.
 */
@property(nonatomic, readonly, nullable)id<STPPaymentMethod> selectedPaymentMethod;
/**
 *  The available payment methods the user can choose between. May be nil.
 */
@property(nonatomic, readonly, nullable)NSArray<id<STPPaymentMethod>> *paymentMethods;

/**
 *  The user's currently selected shipping method. May be nil.
 */
@property(nonatomic, readonly, nullable)PKShippingMethod *selectedShippingMethod;

/**
 *  An array of STPShippingMethod objects that describe the supported shipping methods. May be nil.
 */
@property(nonatomic, readonly, nullable)NSArray<PKShippingMethod *> *shippingMethods;

/**
 *  The user's shipping address. May be nil.
 */
@property(nonatomic, readonly, nullable)STPAddress *shippingAddress;

/**
 *  The amount of money you're requesting from the user, in the smallest currency unit for the selected currency. For example, to indicate $10 USD, use 1000 (i.e. 1000 cents). For more information see https://stripe.com/docs/api#charge_object-amount . This value must be present and greater than zero in order for Apple Pay to be automatically enabled.
 *
 *  @note You should only set either this or `paymentSummaryItems`, not both. The other will be automatically calculated on demand using your `paymentCurrency`. 
 */
@property(nonatomic)NSInteger paymentAmount;

/**
 *  The three-letter currency code for the currency of the payment (i.e. USD, GBP, JPY, etc). Defaults to USD.
 *
 *  @note Changing this property may change the return value of `paymentAmount` or `paymentSummaryItems` (whichever one you didn't directly set yourself).
 */
@property(nonatomic, copy)NSString *paymentCurrency;

/**
 *  If you support Apple Pay, you can optionally set the PKPaymentSummaryItems you want to display here instead of using `paymentAmount`. Note that the grand total (the amount of the last summary item) must be greater than zero.
 *  If not set, a single summary item will be automatically generated using `paymentAmount` and your configuration's `companyName`.
 *  @see PKPaymentRequest for more information
 *
 *  @note You should only set either this or `paymentAmount`, not both. The other will be automatically calculated on demand using your `paymentCurrency.`
 *
 *  @warning `PKPaymentSummaryItem` is only available in iOS8+. If you support iOS 7 you should do a runtime availability check before accessing or setting this property. 
 */
@property(nonatomic, copy)NSArray<PKPaymentSummaryItem *> *paymentSummaryItems NS_AVAILABLE_IOS(8_0);

/**
 *  The presentation style used for all view controllers presented modally by the context.
 *  Since custom transition styles are not supported, you should set this to either
 *  `UIModalPresentationFullScreen`, `UIModalPresentationPageSheet`, or `UIModalPresentationFormSheet`.
 *  The default value is `UIModalPresentationFullScreen`.
 */
@property(nonatomic, assign) UIModalPresentationStyle modalPresentationStyle;

/**
 *  If `paymentContext:didFailToLoadWithError:` is called on your delegate, you
 *  can in turn call this method to try loading again (if that hasn't been called, 
 *  calling this will do nothing). If retrying in turn fails, `paymentContext:didFailToLoadWithError:` 
 *  will be called again (and you can again call this to keep retrying, etc).
 */
- (void)retryLoading;

/**
 *  This creates, configures, and appropriately presents an `STPPaymentMethodsViewController` 
 *  on top of the payment context's `hostViewController`. It'll be dismissed automatically 
 *  when the user is done selecting their payment method.
 *  
 *  @note This method will do nothing if it is called while STPPaymentContext is 
 *        already showing a view controller or in the middle of requesting a payment.
 */
- (void)presentPaymentMethodsViewController;

/**
 *  This creates, configures, and appropriately pushes an `STPPaymentMethodsViewController` 
 *  onto the navigation stack of the context's `hostViewController`. It'll be popped 
 *  automatically when the user is done selecting their payment method.
 *
 *  @note This method will do nothing if it is called while STPPaymentContext is
 *        already showing a view controller or in the middle of requesting a payment.
 */
- (void)pushPaymentMethodsViewController;

/**
 *  This creates, configures, and appropriately presents a view controller for 
 *  collecting shipping address and shipping method on top of the payment context's 
 *  `hostViewController`. It'll be dismissed automatically when the user is done 
 *  entering their shipping info.
 *
 *  @note This method will do nothing if it is called while STPPaymentContext is
 *        already showing a view controller or in the middle of requesting a payment.
 */
- (void)presentShippingViewController;

/**
 *  This creates, configures, and appropriately pushes a view controller for 
 *  collecting shipping address and shipping method onto the navigation stack of 
 *  the context's `hostViewController`. It'll be popped automatically when the 
 *  user is done entering their shipping info.
 *
 *  @note This method will do nothing if it is called while STPPaymentContext is
 *        already showing a view controller, or in the middle of requesting a payment.
 */
- (void)pushShippingViewController;

/**
 *  Requests payment from the user. This may need to present some supplemental UI
 *  to the user, in which case it will be presented on the payment context's 
 *  `hostViewController`. For instance, if they've selected Apple Pay as their 
 *  payment method, calling this method will show the payment sheet. If the user
 *  has a card on file, this will use that without presenting any additional UI.
 *  After this is called, the `paymentContext:didCreatePaymentResult:completion:` 
 *  and `paymentContext:didFinishWithStatus:error:` methods will be called on the
 *  context's `delegate`.
 *
 *  @note This method will do nothing if it is called while STPPaymentContext is
 *        already showing a view controller, or in the middle of requesting a payment.
 */
- (void)requestPayment;


@end

/**
 *  Implement `STPPaymentContextDelegate` to get notified when a payment context changes, finishes, encounters errors, etc. In practice, if your app has a "checkout screen view controller", that is a good candidate to implement this protocol.
 */
NS_EXTENSION_UNAVAILABLE("STPPaymentContext is not available in extensions")
@protocol STPPaymentContextDelegate <NSObject>

/**
 *  Called when the payment context encounters an error when fetching its initial set of data. A few ways to handle this are:
 *  - If you're showing the user a checkout page, dismiss the checkout page when this is called and present the error to the user.
 *  - Present the error to the user using a `UIAlertController` with two buttons: Retry and Cancel. If they cancel, dismiss your UI. If they Retry, call `retryLoading` on the payment context.
 *
 *  To make it harder to get your UI into a bad state, this won't be called until the context's `hostViewController` has finished appearing.
 *
 *  @param paymentContext the payment context that encountered the error
 *  @param error          the error that was encountered
 */
- (void)paymentContext:(STPPaymentContext *)paymentContext didFailToLoadWithError:(NSError *)error;

/**
 *  This is called every time the contents of the payment context change. When this is called, you should update your app's UI to reflect the current state of the payment context. For example, if you have a checkout page with a "selected payment method" row, you should update its payment method with `paymentContext.selectedPaymentMethod.label`. If that checkout page has a "buy" button, you should enable/disable it depending on the result of `[paymentContext isReadyForPayment]`.
 *
 *  @param paymentContext the payment context that changed
 */
- (void)paymentContextDidChange:(STPPaymentContext *)paymentContext;

/**
 *  Inside this method, you should make a call to your backend API to make a charge with that Customer + source, and invoke the `completion` block when that is done.
 *
 *  @note This method is not called for redirect-based sources.
 *
 *  @param paymentContext The context that succeeded
 *  @param paymentResult  Information associated with the payment that you can pass to your server. You should go to your backend API with this payment result and make a charge to complete the payment, passing `paymentResult.source.stripeID` as the `source` parameter to the create charge method and your customer's ID as the `customer` parameter (see stripe.com/docs/api#charge_create for more info). Once that's done call the `completion` block with any error that occurred (or none, if the charge succeeded). @see STPPaymentResult.h
 *  @param completion     Call this block when you're done creating a charge (or subscription, etc) on your backend. If it succeeded, call `completion(nil)`. If it failed with an error, call `completion(error)`.
 */
- (void)paymentContext:(STPPaymentContext *)paymentContext
didCreatePaymentResult:(STPPaymentResult *)paymentResult
            completion:(STPErrorBlock)completion;

/**
 *  This is invoked by an `STPPaymentContext` when it is finished. This will be called after the payment is done and all necessary UI has been dismissed. You should inspect the returned `status` and behave appropriately. For example: if it's `STPPaymentStatusSuccess`, show the user a receipt. If it's `STPPaymentStatusError`, inform the user of the error. If it's `STPPaymentStatusUserCanceled`, do nothing.
 *
 *  @param paymentContext The payment context that finished
 *  @param status         The status of the payment - `STPPaymentStatusSuccess` if it succeeded, `STPPaymentStatusError` if it failed with an error (in which case the `error` parameter will be non-nil), `STPPaymentStatusUserCanceled` if the user canceled the payment.
 *  @param error          An error that occurred, if any.
 */
- (void)paymentContext:(STPPaymentContext *)paymentContext
   didFinishWithStatus:(STPPaymentStatus)status
                 error:(nullable NSError *)error;

@optional
/**
 *  Inside this method, you should verify that you can ship to the given address.
 *  You should call the completion block with the results of your validation
 *  and the available shipping methods for the given address. If you don't implement
 *  this method, the user won't be prompted to select a shipping method and all
 *  addresses will be valid.
 *
 *  @note If a user updates their shipping address within the Apple Pay dialog,
 *  this address will be anonymized. For example, in the US, it will only include the
 *  city, state, and zip code. The payment context will have the user's complete
 *  shipping address by the time `paymentContext:didFinishWithStatus:error` is
 *  called.
 *
 *  @param paymentContext  The context that updated its shipping address
 *  @param address The current shipping address
 *  @param completion      Call this block when you're done validating the shipping address and calculating available shipping methods.
 */
- (void)paymentContext:(STPPaymentContext *)paymentContext
didUpdateShippingAddress:(STPAddress *)address
            completion:(STPShippingMethodsCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
