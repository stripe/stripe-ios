//
//  STPCheckoutWebViewAdapter.h
//  Stripe
//
//  Created by Jack Flintermann on 1/7/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#define STP_VIEW_CLASS UIView
#import <UIKit/UIKit.h>
#else
#define STP_VIEW_CLASS NSView
#import <AppKit/AppKit.h>
#endif

static NSString *const checkoutOptionsGlobal = @"StripeCheckoutOptions";
static NSString *const checkoutRedirectPrefix = @"/-/";
static NSString *const checkoutUserAgent = @"Stripe";
static NSString *const checkoutRPCScheme = @"stripecheckout";

static NSString *const checkoutHost = @"checkout.stripe.com";
static NSString *const checkoutURLString = @"https://checkout.stripe.com/v3/ios/index.html";

static NSString *const STPCheckoutEventOpen = @"CheckoutDidOpen";
static NSString *const STPCheckoutEventTokenize = @"CheckoutDidTokenize";
static NSString *const STPCheckoutEventCancel = @"CheckoutDidCancel";
static NSString *const STPCheckoutEventFinish = @"CheckoutDidFinish";
static NSString *const STPCheckoutEventError = @"CheckoutDidError";

@protocol STPCheckoutDelegate;
@protocol STPCheckoutWebViewAdapter<NSObject>
@property (nonatomic, weak) id<STPCheckoutDelegate> delegate;
@property (nonatomic, readonly) STP_VIEW_CLASS *webView;
- (void)loadRequest:(NSURLRequest *)request;
- (void)evaluateJavaScript:(NSString *)js;
- (void)cleanup;
@end
