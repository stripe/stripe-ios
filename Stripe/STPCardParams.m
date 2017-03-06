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

#pragma mark - STPFormEncodable

+ (NSString *)rootObjectName {
    return @"card";
}

+ (NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             @"number": @"number",
             @"cvc": @"cvc",
             @"name": @"name",
             @"addressLine1": @"address_line1",
             @"addressLine2": @"address_line2",
             @"addressCity": @"address_city",
             @"addressState": @"address_state",
             @"addressZip": @"address_zip",
             @"addressCountry": @"address_country",
             @"expMonth": @"exp_month",
             @"expYear": @"exp_year",
             @"currency": @"currency",
             };
}

@end
