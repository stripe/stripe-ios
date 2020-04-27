//
//  STPPaymentIntentShippingDetailsParams.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 4/27/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPPaymentIntentShippingDetailsParams.h"

#import "STPPaymentIntentShippingDetailsAddressParams.h"

@implementation STPPaymentIntentShippingDetailsParams

- (instancetype)initWithAddress:(STPPaymentIntentShippingDetailsAddressParams *)address name:(NSString *)name {
    self = [super init];
    if (self) {
        _address = address;
        _name = [name copy];
    }
    return self;
}

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                       
                       // Properties
                       [NSString stringWithFormat:@"address = %@", self.address],
                       [NSString stringWithFormat:@"name = %@", self.name],
                       [NSString stringWithFormat:@"carrier = %@", self.carrier],
                       [NSString stringWithFormat:@"phone = %@", self.phone],
                       [NSString stringWithFormat:@"trackingNumber = %@", self.trackingNumber],
                       ];
    
    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    __typeof(self) copy = [[[self class] allocWithZone:zone] init];

    copy.address = [self.address copy];
    copy.name = self.name;
    copy.carrier = self.carrier;
    copy.phone = self.phone;
    copy.trackingNumber = self.trackingNumber;

    return copy;
}

#pragma mark - STPFormEncodable

@synthesize additionalAPIParameters;

+ (nonnull NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(address)): @"address",
             NSStringFromSelector(@selector(name)): @"name",
             NSStringFromSelector(@selector(carrier)): @"carrier",
             NSStringFromSelector(@selector(phone)): @"phone",
             NSStringFromSelector(@selector(trackingNumber)): @"tracking_number",
             };
}

+ (nullable NSString *)rootObjectName {
    return nil;
}

@end
