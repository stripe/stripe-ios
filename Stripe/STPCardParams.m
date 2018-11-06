//
//  STPCardParams.m
//  Stripe
//
//  Created by Jack Flintermann on 10/4/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import "STPCardParams.h"
#import "STPCard+Private.h"

#import "STPCardValidator.h"
#import "StripeError.h"

@implementation STPCardParams

@synthesize additionalAPIParameters = _additionalAPIParameters;

- (instancetype)init {
    self = [super init];
    if (self) {
        _additionalAPIParameters = @{};
        _address = [STPAddress new];
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

- (void)setName:(NSString *)name {
    _name = [name copy];
    self.address.name = self.name;
}

- (void)setAddress:(STPAddress *)address {
    _address = address;
    _name = [address.name copy];
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

#pragma mark - Deprecated methods

- (void)setAddressLine1:(NSString *)addressLine1 {
    self.address.line1 = addressLine1;
}

- (NSString *)addressLine1 {
    return self.address.line1;
}

- (void)setAddressLine2:(NSString *)addressLine2 {
    self.address.line2 = addressLine2;
}

- (NSString *)addressLine2 {
    return self.address.line2;
}

- (void)setAddressZip:(NSString *)addressZip {
    self.address.postalCode = addressZip;
}

- (NSString *)addressZip {
    return self.address.postalCode;
}

- (void)setAddressCity:(NSString *)addressCity {
    self.address.city = addressCity;
}

- (NSString *)addressCity {
    return self.address.city;
}

- (void)setAddressState:(NSString *)addressState {
    self.address.state = addressState;
}

- (NSString *)addressState {
    return self.address.state;
}

- (void)setAddressCountry:(NSString *)addressCountry {
    self.address.country = addressCountry;
}

- (NSString *)addressCountry {
    return self.address.country;
}

#pragma mark - NSCopying

- (id)copyWithZone:(__unused NSZone *)zone {
    STPCardParams *copyCardParams = [self.class new];

    copyCardParams.number = self.number;
    copyCardParams.expMonth = self.expMonth;
    copyCardParams.expYear = self.expYear;
    copyCardParams.cvc = self.cvc;

    // Use ivar to avoid setName:/setAddress: behavior that'd possibly overwrite name/address.name
    copyCardParams->_name = self.name;
    copyCardParams->_address = [self.address copy];

    copyCardParams.currency = self.currency;
    copyCardParams.additionalAPIParameters = self.additionalAPIParameters;

    return copyCardParams;
}

@end
