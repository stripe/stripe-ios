//
//  STPRedirectContext+Private.h
//  Stripe
//
//  Created by Daniel Jackson on 7/12/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import "STPRedirectContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPRedirectContext()

/// Optional URL for a native app. This is passed directly to `UIApplication openURL:`, and if it fails this class falls back to `redirectUrl`
@property (nonatomic, nullable, copy) NSURL *nativeRedirectUrl;
/// The URL to redirect to, assuming `nativeRedirectUrl` is nil or fails to open. Cannot be nil if `nativeRedirectUrl` is.
@property (nonatomic, nullable, copy) NSURL *redirectUrl;
/// The expected `returnUrl`, passed to STPURLCallbackHandler
@property (nonatomic, copy) NSURL *returnUrl;
/// Completion block to execute when finished redirecting, with optional error parameter.
@property (nonatomic, copy) STPErrorBlock completion;

@end

NS_ASSUME_NONNULL_END
