//
//  STPAPIClient+BankAccounts.h
//  Stripe
//
//  Created by Jack Flintermann on 12/19/14.
//  Copyright (c) 2014 Stripe, Inc. All rights reserved.
//

#import "STPAPIClient.h"
@class STPBankAccount;

@interface STPAPIClient (BankAccounts)

- (void)createTokenWithBankAccount:(STPBankAccount *)bankAccount completion:(STPCompletionBlock)completion;

+ (NSData *)formEncodedDataForBankAccount:(STPBankAccount *)bankAccount;

@end
