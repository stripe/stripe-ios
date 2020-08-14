//
//  STPIntentActionAlipayHandleRedirect.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 8/3/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Contains instructions for authenticating a payment by redirecting your customer to Alipay App or website.
 */
@interface STPIntentActionAlipayHandleRedirect : NSObject <STPAPIResponseDecodable>

/**
 The native URL you must redirect your customer to in order to authenticate the payment.
 */
@property (nonatomic, nullable, readonly) NSURL *nativeURL;

/**
 If the customer does not exit their browser while authenticating, they will be redirected to this specified URL after completion.
 */
@property (nonatomic, readonly) NSURL *returnURL;

/**
 The URL you must redirect your customer to in order to authenticate the payment.
 */
@property (nonatomic, readonly) NSURL *url;

/**
 You cannot directly instantiate an `STPPaymentIntentActionAlipayHandleRedirect`.
 */
- (instancetype)init __attribute__((unavailable("You cannot directly instantiate an STPPaymentIntentActionAlipayHandleRedirect.")));

/**
 You cannot directly instantiate an `STPPaymentIntentActionAlipayHandleRedirect`.
 */
+ (instancetype)new __attribute__((unavailable("You cannot directly instantiate an STPPaymentIntentActionAlipayHandleRedirect.")));

@end

NS_ASSUME_NONNULL_END
