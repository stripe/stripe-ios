//
//  STPSourceListViewController.h
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STPPaymentMethod.h"
#import "STPTheme.h"
#import "STPBackendAPIAdapter.h"
#import "STPPaymentConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@protocol STPPaymentMethod;
@class STPPaymentContext, STPPaymentMethodsViewController;

/**
 *  An STPPaymentMethodsViewControllerDelegate responds when a user selects a payment method from (or cancels) an STPPaymentMethodsViewController. In both of these instances, you should dismiss the view controller (either by popping it off the navigation stack, or dismissing it). If you are popping it off of a UINavigationController stack, be aware that it may have already pushed additional view controllers (such as an STPAddCardViewController) onto the stack, so don't call -popViewControllerAnimated: on your UINavigationController. Instead, call -popToViewController: on your navigation controller, with the view controller that was behind the STPPaymentMethodsViewController as the first argument.
 */
@protocol STPPaymentMethodsViewControllerDelegate <NSObject>

/**
 *  This is called when the user either makes a selection, or adds a new card. This will be triggered after the view controller loads with the user's current selection (if they have one) and then subsequently when they change their choice. You should use this callback to update any necessary UI in your app that displays the user's currently selected payment method. You should *not* dismiss the view controller at this point, instead do this in paymentMethodsViewControllerDidFinish:. STPPaymentMethodsViewController will also call the necessary methods on your API adapter, so you don't need to call them directly during this method.
 *
 *  @param paymentMethodsViewController the view controller in question
 *  @param paymentMethod                the selected payment method
 */
- (void)paymentMethodsViewController:(STPPaymentMethodsViewController *)paymentMethodsViewController
              didSelectPaymentMethod:(id<STPPaymentMethod>)paymentMethod;


/**
 *  This is called when the view controller encounters an error fetching the user's payment methods from its API adapter. You should dismiss the view controller when this is called.
 *
 *  @param paymentMethodsViewController the view controller in question
 *  @param paymentMethod                the selected payment method
 */
- (void)paymentMethodsViewController:(STPPaymentMethodsViewController *)paymentMethodsViewController
              didFailToLoadWithError:(NSError *)error;

/**
 *  This is called when the user taps "cancel". It's also called after the user directly selects or adds a payment method, so it will often be called immediately after calling paymentMethodsViewController:didSelectPaymentMethod:. You should dismiss the view controller when this is called.
 *
 *  @param paymentMethodsViewController the view controller that has finished
 */
- (void)paymentMethodsViewControllerDidFinish:(STPPaymentMethodsViewController *)paymentMethodsViewController;

@end

/**
 *  This view controller presents a list of payment method options to the user, which they can select between. They can also add and remove credit cards from the list. It must be displayed inside a UINavigationController, so you can either create a UINavigationController with an STPPaymentMethodsViewController as the rootViewController and then present the UINavigationController, or push a new STPPaymentMethodsViewController onto an existing UINavigationController's stack. You can also have STPPaymentContext do this for you automatically, by calling presentPaymentMethodsViewControllerOnViewController: or pushPaymentMethodsViewControllerOntoNavigationController: on it.
 */
@interface STPPaymentMethodsViewController : UIViewController

@property(nonatomic, weak, readonly)id<STPPaymentMethodsViewControllerDelegate>delegate;

/**
 *  Creates a new payment methods view controller.
 *
 *  @param paymentContext A payment context to power the view controller's view. The paymentContext will in turn use its backend API adapter to fetch the information it needs from your application.
 *
 *  @return an initialized view controller.
 */
- (instancetype)initWithPaymentContext:(STPPaymentContext *)paymentContext;

/**
 *  Initializes a new payment methods view controller without using a payment context.
 *
 *  @param configuration The configuration to use to determine what types of payment method to offer your user. @see STPPaymentConfiguration.h
 *  @param apiAdapter    The API adapter to use to retrieve a customer's stored payment methods and save new ones. @see STPBackendAPIAdapter.h
 *  @param delegate      A delegate that will be notified when the payment methods view controller's selection changes.
 *
 */
- (instancetype)initWithConfiguration:(STPPaymentConfiguration *)configuration
                           apiAdapter:(id<STPBackendAPIAdapter>)apiAdapter
                             delegate:(id<STPPaymentMethodsViewControllerDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
