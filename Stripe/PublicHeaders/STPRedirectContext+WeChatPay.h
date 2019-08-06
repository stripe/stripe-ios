//
//  STPRedirectContext+WeChatPay.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 8/22/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPRedirectContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPRedirectContext (WeChatPay)

/**
 Initializer for context from a WeChat Pay `STPSource`.
 
 Call `startWeChatPayAppRedirectFlow` after this to redirect the user to
 their WeChat app to complete the payment.
 
 @param source The WeChat Pay source.
 @param completion A block to fire when the action is believed to have
 been completed.
 
 @return nil if the specified source is not a WeChat Pay source. Otherwise
 a new context object.
 
 @note This feature is in private beta. For participating users, see
 https://stripe.com/docs/sources/wechat-pay/ios
 @note Execution of the completion block does not necessarily mean the user
 successfully performed the redirect action. You should listen for source status
 change webhooks on your backend to determine the result of a redirect.
 */
- (nullable instancetype)initWithWeChatPaySource:(STPSource *)source
completion:(STPRedirectContextSourceCompletionBlock)completion;

/**
 Redirects the user to their WeChat app to complete the in-app payment flow.

 The context will listen for both received URLs and app open notifications
 and fire its completion block when either the URL is received, or the next
 time the app is foregrounded.
 
 @note This method does nothing if the context is not in the
 `STPRedirectContextStateNotStarted` state.
 */
- (void)startWeChatPayAppRedirectFlow;

@end

NS_ASSUME_NONNULL_END
