//
//  STPPaymentMethodBacsDebitParams.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 1/29/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPFormEncodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 The user's bank account details.
 
 @see https://stripe.com/docs/api/payment_methods/create#create_payment_method-bacs_debit
 */
@interface STPPaymentMethodBacsDebitParams : NSObject <STPFormEncodable>

/**
 The bank account number (eg 00012345)
 */
@property (nonatomic, copy) NSString *accountNumber;

/**
 The sort code of the bank account (eg 10-88-00)
*/
@property (nonatomic, copy) NSString *sortCode;

@end

NS_ASSUME_NONNULL_END
