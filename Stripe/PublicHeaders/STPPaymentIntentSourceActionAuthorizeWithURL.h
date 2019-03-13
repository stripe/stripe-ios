//
//  STPPaymentIntentSourceActionAuthorizeWithURL.h
//  Stripe
//
//  Created by Daniel Jackson on 11/7/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPPaymentIntentActionRedirectToURL.h"

/**
 The `STPPaymentIntentSourceAction` details when type is `STPPaymentIntentSourceActionTypeAuthorizeWithURL`.
 
 These are created & owned by the containing `STPPaymentIntent`.
 
 @deprecated Use `STPPaymentIntentActionRedirectToURL` instead.
 */
__attribute__((deprecated("Use STPPaymentIntentActionRedirectToURL instead", "STPPaymentIntentActionRedirectToURL")))
typedef STPPaymentIntentActionRedirectToURL STPPaymentIntentSourceActionAuthorizeWithURL;
