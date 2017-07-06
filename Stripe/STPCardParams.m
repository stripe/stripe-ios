//
//  STPCardParams.m
//  Stripe
//
//  Created by Jack Flintermann on 10/4/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import "STPCardParams.h"

#import "STPCardValidator.h"
#import "StripeError.h"

@implementation STPCardParams

@synthesize additionalAPIParameters = _additionalAPIParameters;

- (instancetype)init {
    self = [super init];
    if (self) {
        _additionalAPIParameters = @{};
    }
    return self;
}

- (NSString *)last4 {
    if (self.number && self.number.length >= 4) {
        return [self.number substringFromIndex:(self.number.length - 4)];
    } else {
        return nil;
    }
}

- (STPAddress *)address {
    STPAddress *address = [STPAddress new];
    address.name = self.name;
    address.line1 = self.addressLine1;
    address.line2 = self.addressLine2;
    address.city = self.addressCity;
    address.state = self.addressState;
    address.postalCode = self.addressZip;
    address.country = self.addressCountry;
    return address;
}

- (void)setAddress:(STPAddress *)address {
    self.name = address.name;
    self.addressLine1 = address.line1;
    self.addressLine2 = address.line2;
    self.addressCity = address.city;
    self.addressState = address.state;
    self.addressZip = address.postalCode;
    self.addressCountry = address.country;
}

#pragma mark - Description

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                       // Basic card details
                       [NSString stringWithFormat:@"last4 = %@", self.last4],
                       [NSString stringWithFormat:@"expMonth = %lu", (unsigned long)self.expMonth],
                       [NSString stringWithFormat:@"expYear = %lu", (unsigned long)self.expYear],
                       [NSString stringWithFormat:@"cvc = %@", (self.cvc) ? @"<redacted>" : nil],

                       // Additional card details (alphabetical)
                       [NSString stringWithFormat:@"currency = %@", self.currency],

                       // Cardholder details
                       [NSString stringWithFormat:@"name = %@", (self.name) ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"address = %@", (self.address) ? @"<redacted>" : nil],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPFormEncodable

+ (NSString *)rootObjectName {
    return @"card";
}

+ (NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(number)): @"number",
             NSStringFromSelector(@selector(cvc)): @"cvc",
             NSStringFromSelector(@selector(name)): @"name",
             NSStringFromSelector(@selector(addressLine1)): @"address_line1",
             NSStringFromSelector(@selector(addressLine2)): @"address_line2",
             NSStringFromSelector(@selector(addressCity)): @"address_city",
             NSStringFromSelector(@selector(addressState)): @"address_state",
             NSStringFromSelector(@selector(addressZip)): @"address_zip",
             NSStringFromSelector(@selector(addressCountry)): @"address_country",
             NSStringFromSelector(@selector(expMonth)): @"exp_month",
             NSStringFromSelector(@selector(expYear)): @"exp_year",
             NSStringFromSelector(@selector(currency)): @"currency",
             };
}

@end
