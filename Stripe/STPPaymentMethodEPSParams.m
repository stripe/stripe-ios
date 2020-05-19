//
//  STPPaymentMethodEPSParams.m
//  StripeiOS
//
//  Created by Shengwei Wu on 5/14/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodEPSParams.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPPaymentMethodEPSParams

@synthesize additionalAPIParameters = _additionalAPIParameters;

+ (nullable NSString *)rootObjectName {
    return @"eps";
}

+ (NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             };
}

@end

NS_ASSUME_NONNULL_END
