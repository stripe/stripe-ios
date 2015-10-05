//
//  STPFormEncoder.h
//  Stripe
//
//  Created by Jack Flintermann on 1/8/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STPCardParams, STPBankAccountParams;

@interface STPFormEncoder : NSObject

+ (nonnull NSData *)formEncodedDataForBankAccountParams:(nonnull STPBankAccountParams *)bankAccount;

+ (nonnull NSData *)formEncodedDataForCardParams:(nonnull STPCardParams *)card;

+ (nonnull NSString *)stringByURLEncoding:(nonnull NSString *)string;

+ (nonnull NSString *)stringByReplacingSnakeCaseWithCamelCase:(nonnull NSString *)input;

@end
