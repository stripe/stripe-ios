//
//  STPPostalCodeValidator.h
//  Stripe
//
//  Created by Ben Guo on 4/14/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STPPostalCodeValidator : NSObject

+ (BOOL)stringIsValidPostalCode:(nullable NSString *)string;

@end
