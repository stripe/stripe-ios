//
//  STPPaymentMethodGiropayParams.m
//  Stripe
//
//  Created by Cameron Sabol on 4/21/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodGiropayParams.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPPaymentMethodGiropayParams

@synthesize additionalAPIParameters = _additionalAPIParameters;

+ (nullable NSString *)rootObjectName {
    return @"giropay";
}

+ (NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             };
}

@end

NS_ASSUME_NONNULL_END
