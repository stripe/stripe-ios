//
//  STPBankAccount.m
//  Stripe
//
//  Created by Charles Scalesse on 10/1/14.
//
//

#import "STPBankAccount.h"

#import "NSDictionary+Stripe.h"
#import "STPBankAccountParams+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPBankAccount ()

@property (nonatomic, copy, readwrite) NSString *stripeID;
@property (nonatomic, copy, nullable, readwrite) NSString *routingNumber;
@property (nonatomic, copy, readwrite) NSString *country;
@property (nonatomic, copy, readwrite) NSString *currency;
@property (nonatomic, copy, readwrite) NSString *last4;
@property (nonatomic, copy, readwrite) NSString *bankName;
@property (nonatomic, copy, nullable, readwrite) NSString *accountHolderName;
@property (nonatomic, assign, readwrite) STPBankAccountHolderType accountHolderType;
@property (nonatomic, copy, nullable, readwrite) NSDictionary<NSString *, NSString *> *metadata;
@property (nonatomic, copy, nullable, readwrite) NSString *fingerprint;
@property (nonatomic, assign, readwrite) STPBankAccountStatus status;
@property (nonatomic, copy, readwrite) NSDictionary *allResponseFields;

@end

@implementation STPBankAccount

@synthesize routingNumber, country, currency, accountHolderName, accountHolderType;

#pragma mark - STPBankAccountStatus

+ (NSDictionary<NSString *, NSNumber *> *)stringToStatusMapping {
    return @{
             @"new": @(STPBankAccountStatusNew),
             @"validated": @(STPBankAccountStatusValidated),
             @"verified": @(STPBankAccountStatusVerified),
             @"verification_failed": @(STPBankAccountStatusVerificationFailed),
             @"errored": @(STPBankAccountStatusErrored),
             };
}

+ (STPBankAccountStatus)statusFromString:(NSString *)string {
    NSString *key = [string lowercaseString];
    NSNumber *statusNumber = [self stringToStatusMapping][key];

    if (statusNumber) {
        return (STPBankAccountStatus)[statusNumber integerValue];
    }

    return STPBankAccountStatusNew;
}

+ (nullable NSString *)stringFromStatus:(STPBankAccountStatus)status {
    return [[[self stringToStatusMapping] allKeysForObject:@(status)] firstObject];
}

#pragma mark - Equality

- (BOOL)isEqual:(nullable id)bankAccount {
    return [self isEqualToBankAccount:bankAccount];
}

- (NSUInteger)hash {
    return [self.stripeID hash];
}

- (BOOL)isEqualToBankAccount:(nullable STPBankAccount *)bankAccount {
    if (self == bankAccount) {
        return YES;
    }

    if (!bankAccount || ![bankAccount isKindOfClass:self.class]) {
        return NO;
    }
    
    return [self.stripeID isEqualToString:bankAccount.stripeID];
}

#pragma mark - Description

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                       // Identifier
                       [NSString stringWithFormat:@"stripeID = %@", self.stripeID],

                       // Basic account details
                       [NSString stringWithFormat:@"routingNumber = %@", self.routingNumber],
                       [NSString stringWithFormat:@"last4 = %@", self.last4],

                       // Additional account details (alphabetical)
                       [NSString stringWithFormat:@"bankName = %@", self.bankName],
                       [NSString stringWithFormat:@"country = %@", self.country],
                       [NSString stringWithFormat:@"currency = %@", self.currency],
                       [NSString stringWithFormat:@"fingerprint = %@", self.fingerprint],
                       [NSString stringWithFormat:@"metadata = %@", (self.metadata) ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"status = %@", [self.class stringFromStatus:self.status]],

                       // Owner details
                       [NSString stringWithFormat:@"accountHolderName = %@", (self.accountHolderName) ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"accountHolderType = %@", [STPBankAccountParams stringFromAccountHolderType:self.accountHolderType]],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPAPIResponseDecodable

+ (NSArray *)requiredFields {
    return @[
             @"id",
             @"last4",
             @"bank_name",
             @"country",
             @"currency",
             @"status",
             ];
}

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNullsValidatingRequiredFields:[self requiredFields]];
    if (!dict) {
        return nil;
    }
    
    STPBankAccount *bankAccount = [self new];

    // Identifier
    bankAccount.stripeID = dict[@"id"];

    // Basic account details
    bankAccount.routingNumber = dict[@"routing_number"];
    bankAccount.last4 = dict[@"last4"];

    // Additional account details (alphabetical)
    bankAccount.bankName = dict[@"bank_name"];
    bankAccount.country = dict[@"country"];
    bankAccount.currency = dict[@"currency"];
    bankAccount.fingerprint = dict[@"fingerprint"];
    bankAccount.metadata = [dict[@"metadata"] stp_dictionaryByRemovingNonStrings];
    bankAccount.status = [self statusFromString:dict[@"status"]];

    // Owner details
    bankAccount.accountHolderName = dict[@"account_holder_name"];
    bankAccount.accountHolderType = [STPBankAccountParams accountHolderTypeFromString:dict[@"account_holder_type"]];

    bankAccount.allResponseFields = dict;

    return bankAccount;
}

#pragma mark - Deprecated methods

- (NSString *)bankAccountId {
    return self.stripeID;
}

@end

NS_ASSUME_NONNULL_END
