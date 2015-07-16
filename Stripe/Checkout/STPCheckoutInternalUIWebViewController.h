//
//  STPCheckoutInternalUIWebViewController.h
//  Stripe
//
//  Created by Jack Flintermann on 1/7/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#if TARGET_OS_IPHONE

@import Foundation;
@import UIKit;

#import "STPCheckoutDelegate.h"
#import "STPCheckoutViewController.h"
#import "STPNullabilityMacros.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
@interface STPCheckoutInternalUIWebViewController : UIViewController<STPCheckoutDelegate, UIScrollViewDelegate>
- (stp_nonnull instancetype)initWithCheckoutViewController:(stp_nonnull STPCheckoutViewController *)checkoutViewController;
@property (weak, nonatomic, readonly, stp_nullable) STPCheckoutViewController *checkoutController;
@property (weak, nonatomic, readonly, stp_nullable) UIView *webView;
@property (nonatomic, stp_nonnull) STPCheckoutOptions *options;
@property (nonatomic, weak, stp_nullable) id<STPCheckoutViewControllerDelegate> delegate;

@end
#pragma clang diagnostic pop

#endif
