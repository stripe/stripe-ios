//
//  STPPostalCodeValidator.h
//  Stripe
//
//  Created by Ben Guo on 4/14/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPCardValidationState.h"

typedef NS_ENUM(NSUInteger, STPPostalCodeIntendedUsage) {
    STPPostalCodeIntendedUsageBillingAddress,
    STPPostalCodeIntendedUsageShippingAddress,
    STPPostalCodeIntendedUsageCardField,
};

@interface STPPostalCodeValidator : NSObject
+ (BOOL)postalCodeIsRequiredForCountryCode:(nullable NSString *)countryCode;
+ (STPCardValidationState)validationStateForPostalCode:(nullable NSString *)postalCode
                                           countryCode:(nullable NSString *)countryCode;

+ (nullable NSString *)formattedSanitizedPostalCodeFromString:(nullable NSString *)postalCode
                                                  countryCode:(nullable NSString *)countryCode
                                                        usage:(STPPostalCodeIntendedUsage)usage;
@end
