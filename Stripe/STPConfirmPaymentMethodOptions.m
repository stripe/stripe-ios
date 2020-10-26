//
//  STPConfirmPaymentMethodOptions.m
//  Stripe
//
//  Created by Cameron Sabol on 1/10/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPConfirmPaymentMethodOptions.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPConfirmPaymentMethodOptions

@synthesize additionalAPIParameters;

- (NSString *)description {
    NSMutableArray *props = [@[
                               // Object
                               [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                               [NSString stringWithFormat:@"alipay = %@", self.alipayOptions],
                               [NSString stringWithFormat:@"card = %@", self.cardOptions],
                               ] mutableCopy];


    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPFormEncodable

+ (nonnull NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
        NSStringFromSelector(@selector(alipayOptions)): @"alipay",
        NSStringFromSelector(@selector(cardOptions)): @"card",
    };
}

+ (nullable NSString *)rootObjectName {
    return @"payment_method_options";
}

@end

NS_ASSUME_NONNULL_END
