//
//  STPPaymentIntentSourceActionAuthorizeWithURL.h
//  Stripe
//
//  Created by Daniel Jackson on 11/7/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 The `STPPaymentIntentSourceAction` details when type is `STPPaymentIntentSourceActionTypeAuthorizeWithURL`.

 These are created & owned by the containing `STPPaymentIntent`.
 */
@interface STPPaymentIntentSourceActionAuthorizeWithURL: NSObject<STPAPIResponseDecodable>

/**
 You cannot directly instantiate an `STPPaymentIntentSourceActionAuthorizeWithURL`.
 */
- (instancetype)init __attribute__((unavailable("You cannot directly instantiate an STPPaymentIntentSourceActionAuthorizeWithURL.")));

/**
 The URL where the user will authorize this charge.
 */
@property (nonatomic, readonly) NSURL *url;

/**
 The return URL that'll be redirected back to when the user is done
 authorizing the charge.
 */
@property (nonatomic, nullable, readonly) NSURL *returnURL;

@end

NS_ASSUME_NONNULL_END
