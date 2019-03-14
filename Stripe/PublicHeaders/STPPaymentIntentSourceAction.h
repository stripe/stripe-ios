//
//  STPPaymentIntentSourceAction.h
//  Stripe
//
//  Created by Daniel Jackson on 11/7/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPPaymentIntentAction.h"

/**
 Source Action details for an STPPaymentIntent. This is a container for
 the various types that are available. Check the `type` to see which one
 it is, and then use the related property for the details necessary to handle
 it.
 
 @deprecated Use `STPPaymentIntentAction` instead.
 */
__attribute__((deprecated("Use STPPaymentIntentAction instead", "STPPaymentIntentAction")))
typedef STPPaymentIntentAction STPPaymentIntentSourceAction;
