//
//  STPPaymentMethodPayPalParams.m
//  StripeiOS
//
//  Created by Cameron Sabol on 10/5/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodPayPalParams.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPPaymentMethodPayPalParams

@synthesize additionalAPIParameters = _additionalAPIParameters;

+ (nullable NSString *)rootObjectName {
    return @"paypal";
}

+ (NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             };
}

@end

NS_ASSUME_NONNULL_END
