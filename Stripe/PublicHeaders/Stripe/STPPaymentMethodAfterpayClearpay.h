//
//  STPPaymentMethodAfterpayClearpay.h
//  StripeiOS
//
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 An Afterpay Clearpay Payment Method.

 @see https://stripe.com/docs/api/payment_methods/object#payment_method_object-afterpay_clearpay
 */
@interface STPPaymentMethodAfterpayClearpay : NSObject <STPAPIResponseDecodable>

/**
You cannot directly instantiate an `STPPaymentMethodAfterpayClearpay`.
You should only use one that is part of an existing `STPPaymentMethod` object.
*/
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
