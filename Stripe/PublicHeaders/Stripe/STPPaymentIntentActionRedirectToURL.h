//
//  STPPaymentIntentActionRedirectToURL.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/8/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPIntentActionRedirectToURL.h"

/**
 Contains instructions for authenticating a payment by redirecting your customer to another page or application.
 
 @deprecated Use `STPIntentActionRedirectToURL` instead.
 */
__attribute__((deprecated("Use STPIntentActionRedirectToURL instead", "STPIntentActionRedirectToURL")))
typedef STPIntentActionRedirectToURL STPPaymentIntentActionRedirectToURL;
