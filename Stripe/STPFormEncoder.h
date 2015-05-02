//
//  STPFormEncoder.h
//  Stripe
//
//  Created by Jack Flintermann on 1/8/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPNullabilityMacros.h"

@class STPBankAccount, STPCard;

@interface STPFormEncoder : NSObject

+ (stp_nonnull NSData *)formEncodedDataForBankAccount:(stp_nonnull STPBankAccount *)bankAccount;

+ (stp_nonnull NSData *)formEncodedDataForCard:(stp_nonnull STPCard *)card;

+ (stp_nonnull NSString *)stringByURLEncoding:(stp_nonnull NSString *)string;

+ (stp_nonnull NSString *)stringByReplacingSnakeCaseWithCamelCase:(stp_nonnull NSString *)input;

@end
