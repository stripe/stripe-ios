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

NS_ASSUME_NONNULL_BEGIN

@protocol STPPaymentMethod;
@class STPPaymentContext, STPPaymentMethodsViewController;

/**
 *  An STPPaymentMethodsViewControllerDelegate responds when a user selects a payment method from (or cancels) an STPPaymentMethodsViewController. In both of these instances, you should dismiss the view controller (either by popping it off the navigation stack, or dismissing it). If you are popping it off of a UINavigationController stack, be aware that it may have already pushed additional view controllers (such as an STPAddCardViewController) onto the stack, so don't call -popViewControllerAnimated: on your UINavigationController. Instead, call -popToViewController: on your navigation controller, with the view controller that was behind the STPPaymentMethodsViewController as the first argument.
 */
@protocol STPPaymentMethodsViewControllerDelegate <NSObject>

/**
 *  This is called when the user either makes a selection, or adds a new card. Before this is done, the view controller will update the selected payment method on its payment context.
 *
 *  @param paymentMethodsViewController the view controller in question
 *  @param paymentMethod                the selected payment method
 */
- (void)paymentMethodsViewController:(STPPaymentMethodsViewController *)paymentMethodsViewController
              didSelectPaymentMethod:(id<STPPaymentMethod>)paymentMethod;

/**
 *  This is called when the user taps "cancel".
 *
 *  @param paymentMethodsViewController the view controller that has been cancelled
 */
- (void)paymentMethodsViewControllerDidCancel:(STPPaymentMethodsViewController *)paymentMethodsViewController;

@end

/**
 *  This view controller presents a list of payment method options to the user, which they can select between. They can also add and remove credit cards from the list. It must be displayed inside a UINavigationController, so you can either create a UINavigationController with an STPPaymentMethodsViewController as the rootViewController and then present the UINavigationController, or push a new STPPaymentMethodsViewController onto an existing UINavigationController's stack. You can also have STPPaymentContext do this for you automatically, by calling presentPaymentMethodsViewControllerOnViewController: or pushPaymentMethodsViewControllerOntoNavigationController: on it.
 */
@interface STPPaymentMethodsViewController : UIViewController

@property(nonatomic, weak, nullable)id<STPPaymentMethodsViewControllerDelegate>delegate;

/**
 *  Creates a new payment methods view controller.
 *
 *  @param paymentContext A payment context to power the view controller's view. The paymentContext will in turn use its backend API adapter to fetch the information it needs from your application.
 *
 *  @return an initialized view controller.
 */
- (instancetype)initWithPaymentContext:(STPPaymentContext *)paymentContext;

@end

NS_ASSUME_NONNULL_END
