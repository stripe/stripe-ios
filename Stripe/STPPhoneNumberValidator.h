//
//  STPPhoneNumberValidator.h
//  Stripe
//
//  Created by Jack Flintermann on 10/16/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface STPPhoneNumberValidator : NSObject

+ (BOOL)isUSLocale;
+ (BOOL)stringIsValidPartialPhoneNumber:(NSString *)string;
+ (BOOL)stringIsValidPhoneNumber:(NSString *)string;

+ (NSString *)formattedPhoneNumberForString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
