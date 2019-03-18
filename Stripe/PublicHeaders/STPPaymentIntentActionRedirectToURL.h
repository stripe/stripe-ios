//
//  STPPaymentIntentActionRedirectToURL.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/8/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Contains instructions for authenticating a payment by redirecting your customer to another page or application.
 */
@interface STPPaymentIntentActionRedirectToURL : NSObject <STPAPIResponseDecodable>

/**
 You cannot directly instantiate an `STPPaymentIntentActionRedirectToURL`.
 */
- (instancetype)init __attribute__((unavailable("You cannot directly instantiate an STPPaymentIntentActionRedirectToURL.")));

/**
 The URL you must redirect your customer to in order to authenticate the payment.
 */
@property (nonatomic, readonly) NSURL *url;

/**
 The return URL that'll be redirected back to when the user is done
 authenticating.
 */
@property (nonatomic, nullable, readonly) NSURL *returnURL;

@end

NS_ASSUME_NONNULL_END
