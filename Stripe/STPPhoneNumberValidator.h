//
//  STPPhoneNumberValidator.h
//  Stripe
//
//  Created by Jack Flintermann on 10/16/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STPPhoneNumberValidator : NSObject

+ (BOOL)stringIsValidPhoneNumber:(nonnull NSString *)string;

+ (nonnull NSString *)formattedPhoneNumberForString:(nonnull NSString *)string;

@end
