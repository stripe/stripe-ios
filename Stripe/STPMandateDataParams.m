//
//  STPMandateDataParams.m
//  Stripe
//
//  Created by Cameron Sabol on 10/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPMandateDataParams.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPMandateDataParams

@synthesize additionalAPIParameters;

#pragma mark - STPFormEncodable

+ (nonnull NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
        NSStringFromSelector(@selector(customerAcceptance)): @"customer_acceptance",
    };
}

+ (nullable NSString *)rootObjectName {
    return @"mandate_data";
}

@end

NS_ASSUME_NONNULL_END
