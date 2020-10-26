//
//  STPAuthenticationContext.h
//  Stripe
//
//  Created by Cameron Sabol on 5/10/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "STPBlocks.h"

@class SFSafariViewController;

NS_ASSUME_NONNULL_BEGIN

/**
 `STPAuthenticationContext` provides information required to present authentication challenges
 to a user.
 */
@protocol STPAuthenticationContext <NSObject>

/**
 The Stripe SDK will modally present additional view controllers on top
 of the `authenticationPresentingViewController` when required for user
 authentication, like in the Challenge Flow for 3DS2 transactions.
 */
- (UIViewController *)authenticationPresentingViewController;

@optional

/**
 This method is called before presenting a UIViewController for authentication.

 @note `STPPaymentHandler` will not proceed until `completion` is called.
 */
- (void)prepareAuthenticationContextForPresentation:(STPVoidBlock)completion;

/**
 This method is called before presenting an SFSafariViewController for web-based authentication.
 
 Implement this method to configure the `SFSafariViewController` instance, e.g. `viewController.preferredBarTintColor = MyBarTintColor`
 
 @note Setting the `delegate` property has no effect.
 */
- (void)configureSafariViewController:(SFSafariViewController *)viewController;

/**
 This method is called when an authentication UIViewController is about to be dismissed.
 
 Implement this method to prepare your UI for the authentication view controller to be dismissed. For example,
 if you requested authentication while displaying an STPBankSelectionViewController, you may want to hide
 it to return the user to your desired view controller.
 */
- (void)authenticationContextWillDismissViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
