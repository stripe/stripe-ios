//
//  STPPaymentMethodPayPal.h
//  StripeiOS
//
//  Created by Cameron Sabol on 10/5/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
A PayPal Payment Method. :nodoc:
@see https://stripe.com/docs/payments/paypal
*/
@interface STPPaymentMethodPayPal : NSObject <STPAPIResponseDecodable>

/**
You cannot directly instantiate an `STPPaymentMethodPayPal`.
You should only use one that is part of an existing `STPPaymentMethod` object.
*/
- (instancetype)init NS_UNAVAILABLE;

/**
You cannot directly instantiate an `STPPaymentMethodPayPal`.
You should only use one that is part of an existing `STPPaymentMethod` object.
*/
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
