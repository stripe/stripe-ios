//
//  STPPaymentMethodGrabPay.h
//  StripeiOS
//
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 A GrabPay PaymentMethod

 @see https://stripe.com/docs/api/payment_methods/object#payment_method_object-grabpay
 */
@interface STPPaymentMethodGrabPay : NSObject <STPAPIResponseDecodable>

/**
You cannot directly instantiate an `STPPaymentMethodGrabPay`.
You should only use one that is part of an existing `STPPaymentMethod` object.
*/
- (instancetype)init NS_UNAVAILABLE;

/**
You cannot directly instantiate an `STPPaymentMethodGrabPay`.
You should only use one that is part of an existing `STPPaymentMethod` object.
*/
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
