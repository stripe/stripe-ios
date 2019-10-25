//
//  STPMandateCustomerAcceptanceParams.m
//  Stripe
//
//  Created by Cameron Sabol on 10/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPMandateCustomerAcceptanceParams.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPMandateCustomerAcceptanceParams

@synthesize additionalAPIParameters;

+ (NSString *)_stringForType:(STPMandateCustomerAcceptanceType)type {
    switch (type) {
        case STPMandateCustomerAcceptanceTypeOnline:
            return @"online";

        case STPMandateCustomerAcceptanceTypeOffline:
            return @"offline";
    }
}

- (NSString *)_typeString {
    return [[self class] _stringForType:self.type];
}

#pragma mark - STPFormEncodable

+ (nonnull NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
        NSStringFromSelector(@selector(_typeString)): @"type",
        NSStringFromSelector(@selector(onlineParams)): @"online",
    };
}

+ (nullable NSString *)rootObjectName {
    return @"customer_acceptance";
}

@end

NS_ASSUME_NONNULL_END
