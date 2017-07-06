//
//  STPBankAccountParams.m
//  Stripe
//
//  Created by Jack Flintermann on 10/4/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import "STPBankAccountParams.h"
#import "STPBankAccountParams+Private.h"

#define FAUXPAS_IGNORED_ON_LINE(...)

@interface STPBankAccountParams ()

// See STPBankAccountParams+Private.h

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

#pragma mark - STPBankAccountHolderType

+ (NSDictionary<NSString *, NSNumber *> *)stringToAccountHolderTypeMapping {
    return @{
             @"individual": @(STPBankAccountHolderTypeIndividual),
             @"company": @(STPBankAccountHolderTypeCompany),
             };
}

+ (STPBankAccountHolderType)accountHolderTypeFromString:(NSString *)string {
    NSString *key = [string lowercaseString];
    NSNumber *accountHolderTypeNumber = [self stringToAccountHolderTypeMapping][key];

    if (accountHolderTypeNumber) {
        return (STPBankAccountHolderType)[accountHolderTypeNumber integerValue];
    }

    return STPBankAccountHolderTypeIndividual;
}

+ (NSString *)stringFromAccountHolderType:(STPBankAccountHolderType)accountHolderType {
    return [[[self stringToAccountHolderTypeMapping] allKeysForObject:@(accountHolderType)] firstObject];
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
                       [NSString stringWithFormat:@"accountHolderType = %@", [self.class stringFromAccountHolderType:self.accountHolderType]],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPFormEncodable

+ (NSString *)rootObjectName {
    return @"bank_account";
}

+ (NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(accountNumber)): @"account_number",
             NSStringFromSelector(@selector(routingNumber)): @"routing_number",
             NSStringFromSelector(@selector(country)): @"country",
             NSStringFromSelector(@selector(currency)): @"currency",
             NSStringFromSelector(@selector(accountHolderName)): @"account_holder_name",
             NSStringFromSelector(@selector(accountHolderTypeString)): @"account_holder_type",
             };
}

- (NSString *)accountHolderTypeString { FAUXPAS_IGNORED_ON_LINE(UnusedMethod)
    return [self.class stringFromAccountHolderType:self.accountHolderType];
}

@end
