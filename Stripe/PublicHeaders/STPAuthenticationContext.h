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

 Implement this method if your customer is using Apple Pay.  For security, it's impossible to present UIViewControllers above the Apple Pay sheet.
 This method should dismiss the PKPaymentAuthorizationViewController and call `completion` in the dismissal's completion block.
 
 @note `STPPaymentHandler` will not proceed until `completion` is called.
 @note `paymentAuthorizationViewControllerDidFinish` is not called after `PKPaymentAuthorizationViewController` is dismissed.
 */
- (void)prepareAuthenticationContextForPresentation:(STPVoidBlock)completion;

/**
 This method is called before presenting an SFSafariViewController for web-based authentication.
 
 Implement this method to configure the `SFSafariViewController` instance, e.g. `viewController.preferredBarTintColor = MyBarTintColor`
 
 @note Setting the `delegate` property has no effect.
 */
- (void)configureSafariViewController:(SFSafariViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
