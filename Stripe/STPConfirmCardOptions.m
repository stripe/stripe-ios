//
//  STPConfirmCardOptions.m
//  Stripe
//
//  Created by Cameron Sabol on 1/10/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPConfirmCardOptions.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPConfirmCardOptions

@synthesize additionalAPIParameters;

- (NSString *)description {
    NSMutableArray *props = [@[
                               // Object
                               [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                               [NSString stringWithFormat:@"cvc = %@", self.cvc],
                               [NSString stringWithFormat:@"network = %@", self.network],
                               ] mutableCopy];


    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPFormEncodable

+ (nonnull NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
        NSStringFromSelector(@selector(cvc)): @"cvc",
        NSStringFromSelector(@selector(network)): @"network",
    };
}

+ (nullable NSString *)rootObjectName {
    return @"card";
}

@end

NS_ASSUME_NONNULL_END
