//
//  STPIBANValidator.h
//  Stripe
//
//  Created by Ben Guo on 2/15/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface STPIBANValidator : NSObject

+ (NSString *)sanitizedIBANForString:(NSString *)string;
+ (BOOL)stringIsValidPartialIBAN:(NSString *)string;
+ (BOOL)stringIsValidIBAN:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
