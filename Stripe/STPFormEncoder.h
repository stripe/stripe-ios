//
//  STPFormEncoder.h
//  Stripe
//
//  Created by Jack Flintermann on 1/8/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STPBankAccount, STPCard;

@interface STPFormEncoder : NSObject

+ (NSData *)formEncodedDataForBankAccount:(STPBankAccount *)bankAccount;

+ (NSData *)formEncodedDataForCard:(STPCard *)card;

+ (NSString *)stringByURLEncoding:(NSString *)string;

+ (NSString *)stringByReplacingSnakeCaseWithCamelCase:(NSString *)input;

@end
