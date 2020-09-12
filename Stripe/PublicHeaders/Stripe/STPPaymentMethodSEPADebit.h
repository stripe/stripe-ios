//
//  STPPaymentMethodSEPADebit.h
//  StripeiOS
//
//  Created by Cameron Sabol on 10/7/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
A SEPA Debit Payment Method.

@see https://stripe.com/docs/api/payment_methods/object#payment_method_object-sepa_debit
*/
@interface STPPaymentMethodSEPADebit : NSObject <STPAPIResponseDecodable>

/**
You cannot directly instantiate an `STPPaymentMethodSEPADebit`.
You should only use one that is part of an existing `STPPaymentMethod` object.
*/
- (instancetype)init NS_UNAVAILABLE;

/**
 The last 4 digits of the account number.
 */
@property (nonatomic, nullable, readonly) NSString *last4;

/**
 The account's bank code.
 */
@property (nonatomic, nullable, readonly) NSString *bankCode;

/**
 The account's branch code
 */
@property (nonatomic, nullable, readonly) NSString *branchCode;

/**
 Two-letter ISO code representing the country of the bank account.
 */
@property (nonatomic, nullable, readonly) NSString *country;

/**
 The account's fingerprint.
 */
@property (nonatomic, nullable, readonly) NSString *fingerprint;

/**
 The reference of the mandate accepted by your customer. @see https://stripe.com/docs/api/sources/create#create_source-mandate
 */
@property (nonatomic, nullable, readonly) NSString *mandate;

@end

NS_ASSUME_NONNULL_END
