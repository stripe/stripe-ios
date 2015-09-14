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


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
@interface STPCheckoutInternalUIWebViewController : UIViewController<STPCheckoutDelegate, UIScrollViewDelegate>
- (nonnull instancetype)initWithCheckoutViewController:(nonnull STPCheckoutViewController *)checkoutViewController;
@property (weak, nonatomic, readonly, nullable) STPCheckoutViewController *checkoutController;
@property (weak, nonatomic, readonly, nullable) UIView *webView;
@property (nonatomic, nonnull) STPCheckoutOptions *options;
@property (nonatomic, weak, nullable) id<STPCheckoutViewControllerDelegate> delegate;

@end
#pragma clang diagnostic pop

#endif
