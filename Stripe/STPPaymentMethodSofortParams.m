//
//  STPPaymentMethodSofortParams.m
//  Stripe
//
//  Created by David Estes on 8/7/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodSofortParams.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPPaymentMethodSofortParams

@synthesize additionalAPIParameters = _additionalAPIParameters;

+ (nullable NSString *)rootObjectName {
    return @"sofort";
}

+ (NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
                NSStringFromSelector(@selector(country)): @"country",
             };
}

@end

NS_ASSUME_NONNULL_END
