//
//  STPPaymentMethodAUBECSDebitParams.h
//  StripeiOS
//
//  Created by Cameron Sabol on 3/3/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPFormEncodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 An object representing parameters used to create an AU BECS Debit Payment Method
 */
@interface STPPaymentMethodAUBECSDebitParams : NSObject <STPFormEncodable>

/**
 The account number to debit.
 */
@property (nonatomic, copy) NSString *accountNumber;

/**
 Six-digit number identifying bank and branch associated with this bank account.
 */
@property (nonatomic, copy) NSString *bsbNumber;

@end

NS_ASSUME_NONNULL_END
