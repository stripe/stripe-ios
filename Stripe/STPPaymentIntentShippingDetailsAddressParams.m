//
//  STPPaymentIntentShippingDetailsAddressParams.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 4/27/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPPaymentIntentShippingDetailsAddressParams.h"

@implementation STPPaymentIntentShippingDetailsAddressParams

- (instancetype)initWithLine1:(NSString *)line1 {
    self = [super init];
    if (self) {
        _line1 = [line1 copy];
    }
    return self;
}

- (nonnull NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                       
                       // Properties
                       [NSString stringWithFormat:@"line1 = %@", self.line1],
                       [NSString stringWithFormat:@"line2 = %@", self.line2],
                       [NSString stringWithFormat:@"city = %@", self.city],
                       [NSString stringWithFormat:@"state = %@", self.state],
                       [NSString stringWithFormat:@"postalCode = %@", self.postalCode],
                       [NSString stringWithFormat:@"country = %@", self.country],
                       ];
    
    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - NSCopying

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    __typeof(self) copy = [[[self class] allocWithZone:zone] init];

    copy.line1 = self.line1;
    copy.line2 = self.line2;
    copy.city = self.city;
    copy.country = self.country;
    copy.state = self.state;
    copy.postalCode = self.postalCode;

    return copy;
}

#pragma mark - STPFormEncodable

@synthesize additionalAPIParameters;

+ (nonnull NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(line1)): @"line1",
             NSStringFromSelector(@selector(line2)): @"line2",
             NSStringFromSelector(@selector(city)): @"city",
             NSStringFromSelector(@selector(country)): @"country",
             NSStringFromSelector(@selector(state)): @"state",
             NSStringFromSelector(@selector(postalCode)): @"postal_code",
             };
}

+ (nullable NSString *)rootObjectName {
    return nil;
}

@end
