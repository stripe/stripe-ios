//
//  STPCheckoutInternalUIWebViewController.h
//  Stripe
//
//  Created by Jack Flintermann on 1/7/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>
#import "STPCheckoutDelegate.h"
#import "STPCheckoutViewController.h"

@interface STPCheckoutInternalUIWebViewController : UIViewController<STPCheckoutDelegate>

- (instancetype)initWithCheckoutViewController:(STPCheckoutViewController *)checkoutViewController;

@property (weak, nonatomic, readonly) STPCheckoutViewController *checkoutController;
@property (weak, nonatomic) UIView *webView;
@property (nonatomic) id<STPCheckoutWebViewAdapter> adapter;
@property (weak, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) UIView *headerBackground;
@property (nonatomic) STPCheckoutOptions *options;
@property (nonatomic) NSURL *logoURL;
@property (nonatomic) NSURL *url;
@property (nonatomic, weak) id<STPCheckoutViewControllerDelegate> delegate;
@property (nonatomic) BOOL backendChargeSuccessful;
@property (nonatomic) NSError *backendChargeError;

@end

#endif
