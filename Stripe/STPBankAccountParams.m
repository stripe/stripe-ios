//
//  STPBankAccountParams.m
//  Stripe
//
//  Created by Jack Flintermann on 10/4/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import "STPBankAccountParams.h"

@implementation STPBankAccountParams

@synthesize additionalAPIParameters = _additionalAPIParameters;

- (instancetype)init {
    self = [super init];
    if (self) {
        _additionalAPIParameters = @{};
    }
    return self;
}

- (NSString *)last4 {
    if (self.accountNumber && self.accountNumber.length >= 4) {
        return [self.accountNumber substringFromIndex:(self.accountNumber.length - 4)];
    } else {
        return nil;
    }
}

+ (NSString *)rootObjectName {
    return @"bank_account";
}

+ (NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
        @"accountNumber": @"account_number",
        @"routingNumber": @"routing_number",
        @"country": @"country",
        @"currency": @"currency",
    };
}

@end
