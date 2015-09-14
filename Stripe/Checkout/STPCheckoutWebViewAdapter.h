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

static NSString * __nonnull const checkoutOptionsGlobal = @"StripeCheckoutOptions";
static NSString * __nonnull const checkoutRedirectPrefix = @"/-/";
static NSString * __nonnull const checkoutUserAgent = @"Stripe";
static NSString * __nonnull const checkoutRPCScheme = @"stripecheckout";

static NSString * __nonnull const checkoutHost = @"checkout.stripe.com";
static NSString * __nonnull const checkoutURLString = @"https://checkout.stripe.com/v3/ios/index.html";

static NSString * __nonnull const STPCheckoutEventOpen = @"CheckoutDidOpen";
static NSString * __nonnull const STPCheckoutEventTokenize = @"CheckoutDidTokenize";
static NSString * __nonnull const STPCheckoutEventCancel = @"CheckoutDidCancel";
static NSString * __nonnull const STPCheckoutEventFinish = @"CheckoutDidFinish";
static NSString * __nonnull const STPCheckoutEventError = @"CheckoutDidError";

@protocol STPCheckoutDelegate;
@protocol STPCheckoutWebViewAdapter<NSObject>

@property (nonatomic, weak, nullable) id<STPCheckoutDelegate> delegate;
@property (nonatomic, readonly, nullable) STP_VIEW_CLASS *webView;
- (void)loadRequest:(nonnull NSURLRequest *)request;
- (nullable NSString *)evaluateJavaScript:(nonnull NSString *)js;
- (void)cleanup;

@end
