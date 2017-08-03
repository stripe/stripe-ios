//
//  STPBankAccountParams+Private.h
//  Stripe
//
//  Created by Joey Dong on 6/20/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPBankAccountParams.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPBankAccountParams ()

+ (STPBankAccountHolderType)accountHolderTypeFromString:(NSString *)string;
+ (NSString *)stringFromAccountHolderType:(STPBankAccountHolderType)accountHolderType;

@end

NS_ASSUME_NONNULL_END
