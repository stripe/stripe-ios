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
 Checks on Card address and CVC.
 
 @see https://site-admin.stripe.com/docs/api/payment_methods/object#payment_method_object-card-checks
 */
@interface STPPaymentMethodCardChecks : NSObject <STPAPIResponseDecodable>

/**
 You cannot directly instantiate an `STPPaymentMethodCardChecks`.
 */
- (instancetype)init __attribute__((unavailable("You cannot directly instantiate an STPPaymentMethodCardChecks.")));

/**
 If a address line1 was provided, results of the check, one of ‘pass’, ‘failed’, ‘unavailable’ or ‘unchecked’.
 */
@property (nonatomic, nullable, readonly) NSString *addressLine1Check;

/**
 If a address postal code was provided, results of the check, one of ‘pass’, ‘failed’, ‘unavailable’ or ‘unchecked’.
 */
@property (nonatomic, nullable, readonly) NSString *addressPostalCodeCheck;

/**
 If a CVC was provided, results of the check, one of ‘pass’, ‘failed’, ‘unavailable’ or ‘unchecked’.
 */
@property (nonatomic, nullable, readonly) NSString *cvcCheck;

@end

NS_ASSUME_NONNULL_END
