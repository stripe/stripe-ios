//
//  STPPaymentMethodSEPADebitParams.h
//  StripeiOS
//
//  Created by Cameron Sabol on 10/7/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPFormEncodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
An object representing parameters used to create a SEPA Debit Payment Method
*/
@interface STPPaymentMethodSEPADebitParams : NSObject <STPFormEncodable>

/**
 The IBAN number for the bank account you wish to debit. Required.
 */
@property (nonatomic, nullable, copy) NSString *iban;

@end

NS_ASSUME_NONNULL_END
