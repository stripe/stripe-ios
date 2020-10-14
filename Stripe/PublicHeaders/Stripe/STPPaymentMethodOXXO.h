//
//  STPPaymentMethodOXXO.h
//  Stripe
//
//  Created by Polo Li on 6/15/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
A OXXO Payment Method.
@see https://stripe.com/docs/payments/oxxo
*/
@interface STPPaymentMethodOXXO : NSObject<STPAPIResponseDecodable>

/**
You cannot directly instantiate an `STPPaymentMethodOXXO.
You should only use one that is part of an existing `STPPaymentMethod` object.
*/
- (instancetype)init NS_UNAVAILABLE;

/**
You cannot directly instantiate an `STPPaymentMethodOXXO`.
You should only use one that is part of an existing `STPPaymentMethod` object.
*/
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
