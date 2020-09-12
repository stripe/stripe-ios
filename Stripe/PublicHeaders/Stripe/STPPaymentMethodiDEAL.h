//
//  STPPaymentMethodiDEAL.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 An iDEAL Payment Method.
 
 @see https://stripe.com/docs/api/payment_methods/object#payment_method_object-ideal
 */
@interface STPPaymentMethodiDEAL : NSObject <STPAPIResponseDecodable>

/**
 The customer’s bank.
 */
@property (nonatomic, nullable, readonly) NSString *bankName;

/**
 The Bank Identifier Code of the customer’s bank.
 */
@property (nonatomic, nullable, readonly) NSString *bankIdentifierCode;

@end

NS_ASSUME_NONNULL_END

