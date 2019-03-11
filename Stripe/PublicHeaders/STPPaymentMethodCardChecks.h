//
//  STPPaymentMethodCardChecks.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 The result of a check on a Card address or CVC.
 */
typedef NS_ENUM(NSUInteger, STPPaymentMethodCardCheckResult) {
    STPPaymentMethodCardCheckResultPass,
    STPPaymentMethodCardCheckResultFailed,
    STPPaymentMethodCardCheckResultUnavailable,
    STPPaymentMethodCardCheckResultUnchecked,
    STPPaymentMethodCardCheckResultUnknown,
};

/**
 Checks on Card address and CVC.
 
 @see https://stripe.com/docs/api/payment_methods/object#payment_method_object-card-checks
 */
@interface STPPaymentMethodCardChecks : NSObject <STPAPIResponseDecodable>

/**
 You cannot directly instantiate an `STPPaymentMethodCardChecks`.
 */
- (instancetype)init __attribute__((unavailable("You cannot directly instantiate an STPPaymentMethodCardChecks.")));

/**
 If a address line1 was provided, results of the check.
 */
@property (nonatomic, readonly) STPPaymentMethodCardCheckResult addressLine1Check;

/**
 If a address postal code was provided, results of the check.
 */
@property (nonatomic, readonly) STPPaymentMethodCardCheckResult addressPostalCodeCheck;

/**
 If a CVC was provided, results of the check.
 */
@property (nonatomic, readonly) STPPaymentMethodCardCheckResult cvcCheck;

/**
@param string a string representing the check result as returned from
the Stripe API
 
@see https://stripe.com/docs/api/payment_methods/object#payment_method_object-card-checks

@return an enum value mapped to that string. If the string is unrecognized or nil,
returns STPPaymentMethodCardCheckResultUnknown.
*/
+ (STPPaymentMethodCardCheckResult)checkResultFromString:(nullable NSString *)string;


@end

NS_ASSUME_NONNULL_END
