//
//  STPAddCardViewController.h
//  Stripe
//
//  Created by Jack Flintermann on 3/23/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "STPAPIClient.h"
#import "STPAddress.h"
#import "STPBlocks.h"
#import "STPCoreTableViewController.h"
#import "STPPaymentConfiguration.h"
#import "STPTheme.h"
#import "STPUserInformation.h"

NS_ASSUME_NONNULL_BEGIN

@class STPAddCardViewController;
@protocol STPAddCardViewControllerDelegate;

/** This view controller contains a credit card entry form that the user can fill out. On submission, it will use the Stripe API to convert the user's card details to a Stripe token. It renders a right bar button item that submits the form, so it must be shown inside a `UINavigationController`.
 */
@interface STPAddCardViewController : STPCoreTableViewController

/**
 A convenience initializer; equivalent to calling `initWithConfiguration:[STPPaymentConfiguration sharedConfiguration] theme:[STPTheme defaultTheme]`.
 */
- (instancetype)init;

/**
 Initializes a new `STPAddCardViewController` with the provided configuration and theme. Don't forget to set the `delegate` property after initialization.

 @param configuration The configuration to use (this determines the Stripe publishable key to use, the required billing address fields, whether or not to use SMS autofill, etc). @see STPPaymentConfiguration
 @param theme         The theme to use to inform the view controller's visual appearance. @see STPTheme
 */
- (instancetype)initWithConfiguration:(STPPaymentConfiguration *)configuration
                                theme:(STPTheme *)theme;

/**
 The view controller's delegate. This must be set before showing the view controller in order for it to work properly. @see STPAddCardViewControllerDelegate
 */
@property (nonatomic, weak, nullable) id<STPAddCardViewControllerDelegate>delegate;

/**
 You can set this property to pre-fill any information you've already collected from your user. @see STPUserInformation.h
 */
@property (nonatomic, strong, nullable) STPUserInformation *prefilledInformation;

/**
 Provide this view controller with a footer view.

 When the footer view needs to be resized, it will be sent a
 `sizeThatFits:` call. The view should respond correctly to this method in order
 to be sized and positioned properly.
 */
@property (nonatomic, strong, nullable) UIView *customFooterView;

/**
 Use init: or initWithConfiguration:theme:
 */
- (instancetype)initWithTheme:(STPTheme *)theme NS_UNAVAILABLE;

/**
 Use init: or initWithConfiguration:theme:
 */
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

/**
 Use init: or initWithConfiguration:theme:
 */
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

@end

/**
 An `STPAddCardViewControllerDelegate` is notified when an `STPAddCardViewController`
 successfully creates a card token or is cancelled. It has internal error-handling
 logic, so there's no error case to deal with.
 */
@protocol STPAddCardViewControllerDelegate <NSObject>

/**
 Called when the user cancels adding a card. You should dismiss (or pop) the
 view controller at this point.

 @param addCardViewController the view controller that has been cancelled
 */
- (void)addCardViewControllerDidCancel:(STPAddCardViewController *)addCardViewController;

@optional

/**
 This is called when the user successfully adds a card and Stripe returns a
 Payment Method.
 
 You should send the PaymentMethod to your backend to store it on a customer, and then
 call the provided `completion` block when that call is finished. If an error
 occurs while talking to your backend, call `completion(error)`, otherwise,
 dismiss (or pop) the view controller.
 
 @param addCardViewController the view controller that successfully created a token
 @param paymentMethod         the Payment Method that was created. @see STPPaymentMethod
 @param completion            call this callback when you're done sending the token to your backend
 */
- (void)addCardViewController:(STPAddCardViewController *)addCardViewController
       didCreatePaymentMethod:(STPPaymentMethod *)paymentMethod
                   completion:(STPErrorBlock)completion;

# pragma mark - Deprecated

/**
  This method is deprecated as of v16.0.0 (https://github.com/stripe/stripe-ios/blob/master/MIGRATING.md#migrating-from-versions--1600).
  To use this class, migrate your integration from Charges to PaymentIntents. See https://stripe.com/docs/payments/payment-intents/migration/charges#read
 */
- (void)addCardViewController:(STPAddCardViewController *)addCardViewController
               didCreateToken:(STPToken *)token
                   completion:(STPErrorBlock)completion __attribute__((deprecated("Use addCardViewController:didCreatePaymentMethod:completion: instead and migrate your integration to PaymentIntents. See https://stripe.com/docs/payments/payment-intents/migration/charges#read", "addCardViewController:didCreatePaymentMethod:completion:")));

/**
 This method is deprecated as of v16.0.0 (https://github.com/stripe/stripe-ios/blob/master/MIGRATING.md#migrating-from-versions--1600).
 To use this class, migrate your integration from Charges to PaymentIntents. See https://stripe.com/docs/payments/payment-intents/migration/charges#read
*/
- (void)addCardViewController:(STPAddCardViewController *)addCardViewController
              didCreateSource:(STPSource *)source
                   completion:(STPErrorBlock)completion __attribute__((deprecated("Use addCardViewController:didCreatePaymentMethod:completion: instead and migrate your integration to PaymentIntents. See https://stripe.com/docs/payments/payment-intents/migration/charges#read", "addCardViewController:didCreatePaymentMethod:completion:")));

@end

NS_ASSUME_NONNULL_END
