//
//  STPCheckoutInternalUIWebViewController.h
//  Stripe
//
//  Created by Jack Flintermann on 1/7/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#if TARGET_OS_IPHONE

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "STPCheckoutDelegate.h"
#import "STPCheckoutViewController.h"
#import "STPNullabilityMacros.h"

@interface STPCheckoutInternalUIWebViewController : UIViewController<STPCheckoutDelegate, UIScrollViewDelegate>

- (stp_nonnull instancetype)initWithCheckoutViewController:(stp_nonnull STPCheckoutViewController *)checkoutViewController;

@property (weak, nonatomic, readonly, stp_nonnull) STPCheckoutViewController *checkoutController;
@property (weak, nonatomic, readonly, stp_nullable) UIView *webView;
@property (nonatomic, stp_nonnull) STPCheckoutOptions *options;
@property (nonatomic, weak, stp_nullable) id<STPCheckoutViewControllerDelegate> delegate;

@end

#endif
