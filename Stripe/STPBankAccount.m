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

    if (statusNumber != nil) {
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

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }
    
    // required fields
    NSString *stripeId = [dict stp_stringForKey:@"id"];
    NSString *last4 = [dict stp_stringForKey:@"last4"];
    NSString *bankName = [dict stp_stringForKey:@"bank_name"];
    NSString *country = [dict stp_stringForKey:@"country"];
    NSString *currency = [dict stp_stringForKey:@"currency"];
    NSString *rawStatus = [dict stp_stringForKey:@"status"];
    if (!stripeId || !last4 || !bankName || !country || !currency || !rawStatus) {
        return nil;
    }

    STPBankAccount *bankAccount = [self new];

    // Identifier
    bankAccount.stripeID = stripeId;

    // Basic account details
    bankAccount.routingNumber = [dict stp_stringForKey:@"routing_number"];
    bankAccount.last4 = last4;

    // Additional account details (alphabetical)
    bankAccount.bankName = bankName;
    bankAccount.country = country;
    bankAccount.currency = currency;
    bankAccount.fingerprint = [dict stp_stringForKey:@"fingerprint"];
    bankAccount.metadata = [[dict stp_dictionaryForKey:@"metadata"] stp_dictionaryByRemovingNonStrings];
    bankAccount.status = [self statusFromString:rawStatus];

    // Owner details
    bankAccount.accountHolderName = [dict stp_stringForKey:@"account_holder_name"];
    NSString *rawAccountHolderType = [dict stp_stringForKey:@"account_holder_type"];
    bankAccount.accountHolderType = [STPBankAccountParams accountHolderTypeFromString:rawAccountHolderType];

    bankAccount.allResponseFields = dict;

    return bankAccount;
}

#pragma mark - Deprecated methods

- (NSString *)bankAccountId {
    return self.stripeID;
}

@end

NS_ASSUME_NONNULL_END
