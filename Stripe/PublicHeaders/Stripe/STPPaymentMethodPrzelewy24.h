//
//  STPPaymentMethodPrzelewy24.h
//  StripeiOS
//
//  Created by Vineet Shah on 4/23/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
A Przelewy24 Payment Method.

@see https://stripe.com/docs/payments/p24
*/
@interface STPPaymentMethodPrzelewy24 : NSObject <STPAPIResponseDecodable>

/**
You cannot directly instantiate an `STPPaymentMethodPrzelewy24`.
You should only use one that is part of an existing `STPPaymentMethod` object.
*/
- (instancetype)init NS_UNAVAILABLE;

/**
You cannot directly instantiate an `STPPaymentMethodPrzelewy24`.
You should only use one that is part of an existing `STPPaymentMethod` object.
*/
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
