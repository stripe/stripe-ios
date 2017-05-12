//
//  STPSourcePrecheckParams.h
//  Stripe
//
//  Created by Brian Dorfman on 5/8/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPFormEncodable.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPSourcePrecheckParams : NSObject <STPFormEncodable>

@property (nonatomic, copy) NSString *sourceID;

/**
 *  A positive integer in the smallest currency unit representing the
 *  amount to charge the customer (e.g., @1099 for a €10.99 payment).
 *  Should be a wrapped NSUInteger
 */
@property (nonatomic, copy, nullable) NSNumber *paymentAmount;

/**
 *  The three-letter currency code for the currency of the payment (i.e. USD, GBP, JPY, etc).
 */
@property (nonatomic, copy, nullable) NSString *paymentCurrency;

@property (nonatomic, copy, nullable) NSDictionary *metadata;

@property (nonatomic, copy) NSDictionary *additionalParameters;

@end

NS_ASSUME_NONNULL_END
