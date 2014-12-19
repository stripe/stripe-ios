//
//  STPAPIClient+BankAccounts.m
//  Stripe
//
//  Created by Jack Flintermann on 12/19/14.
//  Copyright (c) 2014 Stripe, Inc. All rights reserved.
//

#import "STPAPIClient+BankAccounts.h"
#import "STPBankAccount.h"

@implementation STPAPIClient (BankAccounts)

- (void)createTokenWithBankAccount:(STPBankAccount *)bankAccount completion:(STPCompletionBlock)completion {
    [self createTokenWithData:[self.class formEncodedDataForBankAccount:bankAccount] completion:completion];
}

+ (NSData *)formEncodedDataForBankAccount:(STPBankAccount *)bankAccount {
    NSCAssert(bankAccount != nil, @"Cannot create a token with a nil bank account.");
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSMutableArray *parts = [NSMutableArray array];
    
    if (bankAccount.accountNumber) {
        params[@"account_number"] = bankAccount.accountNumber;
    }
    if (bankAccount.routingNumber) {
        params[@"routing_number"] = bankAccount.routingNumber;
    }
    if (bankAccount.country) {
        params[@"country"] = bankAccount.country;
    }
    
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id val, __unused BOOL *stop) {
        [parts addObject:[NSString stringWithFormat:@"bank_account[%@]=%@", key, [self.class stringByURLEncoding:val]]];
    }];
    
    return [[parts componentsJoinedByString:@"&"] dataUsingEncoding:NSUTF8StringEncoding];
}

@end
