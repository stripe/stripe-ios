//
//  STPFakeAddPaymentPassViewController.h
//  Stripe
//
//  Created by Jack Flintermann on 9/28/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PassKit/PassKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
This class is a piece of fake UI that is intended to mimic `PKAddPaymentPassViewController`. That class is restricted to apps with a special entitlement from Apple, and as such can be difficult to build and test against. This class implements the same public API as `PKAddPaymentPassViewController`, and can be used to develop against the Stripe API in *testmode only*. (Obviously it will not actually place cards into the user's Apple Pay wallet either.) When it's time to go to production, you may simply replace all references to `STPFakeAddPaymentPassViewController` in your app with `PKAddPaymentPassViewController` and it will continue to function. For more information on developing against this API, please see https://stripe.com/docs/issuing/cards/digital-wallets .
 */
@interface STPFakeAddPaymentPassViewController : UIViewController

/// @see PKAddPaymentPassViewController
+ (BOOL)canAddPaymentPass;

/// @see PKAddPaymentPassViewController
- (nullable instancetype)initWithRequestConfiguration:(PKAddPaymentPassRequestConfiguration *)configuration
                                             delegate:(nullable id<PKAddPaymentPassViewControllerDelegate>)delegate NS_DESIGNATED_INITIALIZER;
/// @see PKAddPaymentPassViewController
@property (nonatomic, weak, nullable) id<PKAddPaymentPassViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
