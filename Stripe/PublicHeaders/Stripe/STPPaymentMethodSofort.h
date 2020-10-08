//
//  STPPaymentMethodSofort.h
//  Stripe
//
//  Created by David Estes on 8/7/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
A Sofort Payment Method.

@see https://stripe.com/docs/api/payment_methods/object#payment_method_object-Sofort
*/
@interface STPPaymentMethodSofort : NSObject <STPAPIResponseDecodable>

/**
You cannot directly instantiate an `STPPaymentMethodSofort`.
You should only use one that is part of an existing `STPPaymentMethod` object.
*/
- (instancetype)init NS_UNAVAILABLE;

/**
You cannot directly instantiate an `STPPaymentMethodSofort`.
You should only use one that is part of an existing `STPPaymentMethod` object.
*/
+ (instancetype)new NS_UNAVAILABLE;

/**
 Two-letter ISO code representing the country the bank account is located in.
 */
@property (nonatomic, nullable, readonly) NSString *country;

@end

NS_ASSUME_NONNULL_END
