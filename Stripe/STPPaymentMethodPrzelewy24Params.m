//
//  STPPaymentMethodPrzelewy24Params.m
//  StripeiOS
//
//  Created by Vineet Shah on 4/23/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodPrzelewy24Params.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPPaymentMethodPrzelewy24Params

@synthesize additionalAPIParameters = _additionalAPIParameters;

+ (nullable NSString *)rootObjectName {
    return @"p24";
}

+ (NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             };
}

@end

NS_ASSUME_NONNULL_END
