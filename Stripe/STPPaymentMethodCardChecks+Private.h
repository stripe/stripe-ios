//
//  STPPaymentMethodCardChecks+Private.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/11/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodCardChecks.h"

@interface STPPaymentMethodCardChecks()

/**
 @param string a string representing the check result as returned from
 the Stripe API
 
 @see https://stripe.com/docs/api/payment_methods/object#payment_method_object-card-checks
 
 @return an enum value mapped to that string. If the string is unrecognized or nil,
 returns STPPaymentMethodCardCheckResultUnknown.
 */
+ (STPPaymentMethodCardCheckResult)checkResultFromString:(nullable NSString *)string;

@end
