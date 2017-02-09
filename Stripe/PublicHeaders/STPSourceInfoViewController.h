//
//  STPSourceInfoViewController.h
//  Stripe
//
//  Created by Ben Guo on 2/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Stripe/Stripe.h>
#import "STPCoreTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@protocol STPSourceInfoViewControllerDelegate;
@class STPSourceParams;

/** You can use this view controller to collect information for payment sources that require additional information upon creation (e.g. iDEAL, which requires your customer's name and bank.) Note that this view controller renders a right bar button item that submits the form, so it must be shown inside a `UINavigationController`.
 */
@interface STPSourceInfoViewController : STPCoreTableViewController

/**
 *  Initializes a new `STPSourceInfoViewController` with the provided parameters. When the user submits the form, the view controller will return a copy of the provided `STPSourceParams` object to its delegate, updated with the information entered by the user.
 *
 *  @param sourceParams     The source parameters to collect additional info for. @see STPSourceParams
  *  @param theme           The theme to use to inform the view controller's visual appearance. @see STPTheme
 */
- (nullable instancetype)initWithSourceParams:(STPSourceParams *)sourceParams
                                        theme:(STPTheme *)theme;

/**
 *  The view controller's delegate. This must be set before showing the view controller in order for it to work properly. @see STPSourceInfoViewControllerDelegate
 */
@property(nonatomic, weak) id<STPSourceInfoViewControllerDelegate> delegate;

@end

/**
 *  An `STPSourceInfoViewControllerDelegate` is notified when a user submits information or cancels in an `STPSourceInfoViewController`.
 */
@protocol STPSourceInfoViewControllerDelegate <NSObject>

/**
 *  This is called when the user cancels entering source information. You should dismiss (or pop) the view controller at this point.
 *
 *  @param sourceInfoViewController the view controller that has been cancelled
 */
- (void)sourceInfoViewControllerDidCancel:(STPSourceInfoViewController *)sourceInfoViewController;

/**
 *  This is called when the user finishes entering source information and submits the form. You should use the `STPSourceParams` object returned by this callback to create a source, and dismiss (or pop) the view controller.
 *
 *  @param sourceInfoViewController the view controller that has been cancelled
 */
- (void)sourceInfoViewController:(STPSourceInfoViewController *)sourceInfoViewController
       didFinishWithSourceParams:(STPSourceParams *)sourceParams;

@end

NS_ASSUME_NONNULL_END
