//
//  STPPaymentMethodEPS.h
//  StripeiOS
//
//  Created by Shengwei Wu on 5/14/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
A EPS Payment Method.
@see https://stripe.com/docs/api/payment_methods/object#payment_method_object-eps
*/
@interface STPPaymentMethodEPS : NSObject <STPAPIResponseDecodable>

/**
You cannot directly instantiate an `STPPaymentMethodEPS`.
You should only use one that is part of an existing `STPPaymentMethod` object.
*/
- (instancetype)init NS_UNAVAILABLE;

/**
You cannot directly instantiate an `STPPaymentMethodEPS`.
You should only use one that is part of an existing `STPPaymentMethod` object.
*/
+ (instancetype)new NS_UNAVAILABLE;

@end


NS_ASSUME_NONNULL_END
