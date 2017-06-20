//
//  STPBankAccountParams.m
//  Stripe
//
//  Created by Jack Flintermann on 10/4/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import "STPBankAccountParams.h"
#define FAUXPAS_IGNORED_ON_LINE(...)

@interface STPBankAccountParams()
@property(nonatomic, readonly)NSString *accountHolderTypeString;
@end

@implementation STPBankAccountParams

@synthesize additionalAPIParameters = _additionalAPIParameters;

- (instancetype)init {
    self = [super init];
    if (self) {
        _additionalAPIParameters = @{};
        _accountHolderType = STPBankAccountHolderTypeIndividual;
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

- (NSString *)accountHolderTypeString { FAUXPAS_IGNORED_ON_LINE(UnusedMethod)
    switch (self.accountHolderType) {
        case STPBankAccountHolderTypeCompany:
            return @"company";
        case STPBankAccountHolderTypeIndividual:
            return @"individual";
    }
}

#pragma mark - Description

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                       // Basic account details
                       [NSString stringWithFormat:@"routingNumber = %@", self.routingNumber],
                       [NSString stringWithFormat:@"last4 = %@", self.last4],

                       // Additional account details (alphabetical)
                       [NSString stringWithFormat:@"country = %@", self.country],
                       [NSString stringWithFormat:@"currency = %@", self.currency],

                       // Owner details
                       [NSString stringWithFormat:@"accountHolderName = %@", (self.accountHolderName) ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"accountHolderType = %@", [self accountHolderTypeString]],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPFormEncodable

+ (NSString *)rootObjectName {
    return @"bank_account";
}

+ (NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             @"accountNumber": @"account_number",
             @"routingNumber": @"routing_number",
             @"country": @"country",
             @"currency": @"currency",
             @"accountHolderName": @"account_holder_name",
             @"accountHolderTypeString": @"account_holder_type",
             };
}

@end
