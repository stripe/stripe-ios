//
//  STPPaymentMethodAUBECSDebit.h
//  StripeiOS
//
//  Created by Cameron Sabol on 3/3/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
An AU BECS Debit Payment Method.

@see https://stripe.com/docs/api/payment_methods/object#payment_method_object-au_becs_debit
*/
@interface STPPaymentMethodAUBECSDebit : NSObject <STPAPIResponseDecodable>

/**
You cannot directly instantiate an `STPPaymentMethodAUBECSDebit`.
You should only use one that is part of an existing `STPPaymentMethod` object.
*/
- (instancetype)init NS_UNAVAILABLE;

/**
 Six-digit number identifying bank and branch associated with this bank account.
 */
@property (nonatomic, readonly, copy) NSString *bsbNumber;

/**
 Uniquely identifies this particular bank account. You can use this attribute to check whether two bank accounts are the same.
 */
@property (nonatomic, readonly, copy) NSString *fingerprint;

/**
 Last four digits of the bank account number.
 */
@property (nonatomic, readonly, copy) NSString *last4;

@end

NS_ASSUME_NONNULL_END
