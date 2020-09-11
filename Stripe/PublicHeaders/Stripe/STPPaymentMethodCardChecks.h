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
    /**
     The check passed.
     */
    STPPaymentMethodCardCheckResultPass,
    
    /**
     The check failed.
     */
    STPPaymentMethodCardCheckResultFailed,
    
    /**
     The check is unavailable.
     */
    STPPaymentMethodCardCheckResultUnavailable,
    
    /**
     The value was not checked.
     */
    STPPaymentMethodCardCheckResultUnchecked,
    
    /**
     Represents an unknown or null value.
     */
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

#pragma mark - Deprecated
/**
 If a address line1 was provided, results of the check.

 @deprecated Card check values are no longer returned to clients using publishable keys. Retrieve them on your server using yoursecret key instead.
 */
@property (nonatomic, readonly) STPPaymentMethodCardCheckResult addressLine1Check DEPRECATED_MSG_ATTRIBUTE("Card check values are no longer returned to clients using publishable keys. Retrieve them on your server using yoursecret key instead.");

/**
 If a address postal code was provided, results of the check.


 @deprecated Card check values are no longer returned to clients using publishable keys. Retrieve them on your server using yoursecret key instead.
 */
@property (nonatomic, readonly) STPPaymentMethodCardCheckResult addressPostalCodeCheck DEPRECATED_MSG_ATTRIBUTE("Card check values are no longer returned to clients using publishable keys. Retrieve them on your server using yoursecret key instead.");

/**
 If a CVC was provided, results of the check.


 @deprecated Card check values are no longer returned to clients using publishable keys. Retrieve them on your server using yoursecret key instead.
 */
@property (nonatomic, readonly) STPPaymentMethodCardCheckResult cvcCheck DEPRECATED_MSG_ATTRIBUTE("Card check values are no longer returned to clients using publishable keys. Retrieve them on your server using yoursecret key instead.");

@end

NS_ASSUME_NONNULL_END
