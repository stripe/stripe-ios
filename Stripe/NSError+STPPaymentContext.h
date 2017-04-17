//
//  NSError+STPPaymentContext.h
//  Stripe
//
//  Created by Brian Dorfman on 4/13/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "StripeError.h"
#import "STPSource.h"

@interface NSError (STPPaymentContext)
+ (nonnull NSError *)stp_paymentContextUnknownError;
+ (nonnull NSError *)stp_paymentContextUnsupportedPaymentMethodError;
+ (nonnull NSError *)stp_paymentContextInvalidSourceStatusErrorWithStatus:(STPSourceStatus)status;
@end
