//
//  STPPaymentMethodOXXOParams.m
//  StripeiOS
//
//  Created by Polo Li on 6/16/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodOXXOParams.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPPaymentMethodOXXOParams

@synthesize additionalAPIParameters = _additionalAPIParameters;

+ (nullable NSString *)rootObjectName {
    return @"oxxo";
}

+ (NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             };
}

@end

NS_ASSUME_NONNULL_END
