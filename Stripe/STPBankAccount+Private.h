//
//  STPBankAccount+Private.h
//  Stripe
//
//  Created by Joey Dong on 6/20/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPBankAccount.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPBankAccount ()

+ (STPBankAccountStatus)statusFromString:(NSString *)string;
+ (NSString *)stringFromStatus:(STPBankAccountStatus)status;

@end

NS_ASSUME_NONNULL_END
