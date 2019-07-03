//
//  STPPaymentIntentSourceActionAuthorizeWithURL.h
//  Stripe
//
//  Created by Daniel Jackson on 11/7/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPIntentActionRedirectToURL.h"

/**
 The `STPPaymentIntentSourceAction` details when type is `STPPaymentIntentSourceActionTypeAuthorizeWithURL`.
 
 These are created & owned by the containing `STPPaymentIntent`.
 
 @deprecated Use `STPIntentActionRedirectToURL` instead.
 */
__attribute__((deprecated("Use STPIntentActionRedirectToURL instead", "STPIntentActionRedirectToURL")))
typedef STPIntentActionRedirectToURL STPPaymentIntentSourceActionAuthorizeWithURL;
