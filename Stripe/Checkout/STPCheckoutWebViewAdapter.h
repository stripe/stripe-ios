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

#import "STPNullabilityMacros.h"

static NSString * __stp_nonnull const checkoutOptionsGlobal = @"StripeCheckoutOptions";
static NSString * __stp_nonnull const checkoutRedirectPrefix = @"/-/";
static NSString * __stp_nonnull const checkoutUserAgent = @"Stripe";
static NSString * __stp_nonnull const checkoutRPCScheme = @"stripecheckout";

static NSString * __stp_nonnull const checkoutHost = @"checkout.stripe.com";
static NSString * __stp_nonnull const checkoutURLString = @"https://checkout.stripe.com/v3/ios/index.html";

static NSString * __stp_nonnull const STPCheckoutEventOpen = @"CheckoutDidOpen";
static NSString * __stp_nonnull const STPCheckoutEventTokenize = @"CheckoutDidTokenize";
static NSString * __stp_nonnull const STPCheckoutEventCancel = @"CheckoutDidCancel";
static NSString * __stp_nonnull const STPCheckoutEventFinish = @"CheckoutDidFinish";
static NSString * __stp_nonnull const STPCheckoutEventError = @"CheckoutDidError";

@protocol STPCheckoutDelegate;
@protocol STPCheckoutWebViewAdapter<NSObject>

@property (nonatomic, weak, stp_nullable) id<STPCheckoutDelegate> delegate;
@property (nonatomic, readonly, stp_nullable) STP_VIEW_CLASS *webView;
- (void)loadRequest:(stp_nonnull NSURLRequest *)request;
- (stp_nullable NSString *)evaluateJavaScript:(stp_nonnull NSString *)js;
- (void)cleanup;

@end
