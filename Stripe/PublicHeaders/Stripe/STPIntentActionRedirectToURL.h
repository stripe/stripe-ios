//
//  STPIntentActionRedirectToURL.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 6/27/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Contains instructions for authenticating a payment by redirecting your customer to another page or application.
 
 @see https://stripe.com/docs/api/payment_intents/object#payment_intent_object-next_action
 */
@interface STPIntentActionRedirectToURL : NSObject <STPAPIResponseDecodable>

/**
 You cannot directly instantiate an `STPIntentActionRedirectToURL`.
 */
- (instancetype)init __attribute__((unavailable("You cannot directly instantiate an STPIntentActionRedirectToURL.")));

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
