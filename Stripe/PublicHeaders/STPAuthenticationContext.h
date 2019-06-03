//
//  STPAuthenticationContext.h
//  Stripe
//
//  Created by Cameron Sabol on 5/10/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

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

@end

NS_ASSUME_NONNULL_END
