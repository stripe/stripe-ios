//
//  STPBankAccount.m
//  Stripe
//
//  Created by Charles Scalesse on 10/1/14.
//
//

#import "STPBankAccount.h"
#import "STPBankAccount+Private.h"

#import "NSDictionary+Stripe.h"
#import "STPBankAccountParams+Private.h"

@interface STPBankAccount ()

@property (nonatomic, readwrite) NSString *bankAccountId;
@property (nonatomic, readwrite) NSString *last4;
@property (nonatomic, readwrite) NSString *bankName;
@property (nonatomic, readwrite) NSString *fingerprint;
@property (nonatomic) STPBankAccountStatus status;
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;

// See STPBankAccount+Private.h

@end

@implementation STPBankAccount

@synthesize routingNumber, country, currency, accountHolderName, accountHolderType;

#pragma mark - STPBankAccountStatus

+ (NSDictionary<NSString *, NSNumber *> *)stringToStatusMapping {
    return @{
             @"new": @(STPBankAccountStatusNew),
             @"validated": @(STPBankAccountStatusValidated),
             @"verified": @(STPBankAccountStatusVerified),
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

+ (NSString *)stringFromStatus:(STPBankAccountStatus)status {
    return [[[self stringToStatusMapping] allKeysForObject:@(status)] firstObject];
}

#pragma mark -

- (void)setAccountNumber:(NSString *)accountNumber {
    [super setAccountNumber:accountNumber];
}

- (NSString *)last4 {
    return _last4 ?: [super last4];
}

#pragma mark - Equality

- (BOOL)isEqual:(STPBankAccount *)bankAccount {
    return [self isEqualToBankAccount:bankAccount];
}

- (NSUInteger)hash {
    return [self.bankAccountId hash];
}

- (BOOL)isEqualToBankAccount:(STPBankAccount *)bankAccount {
    if (self == bankAccount) {
        return YES;
    }

    if (!bankAccount || ![bankAccount isKindOfClass:self.class]) {
        return NO;
    }
    
    return [self.bankAccountId isEqualToString:bankAccount.bankAccountId];
}

#pragma mark - Description

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                       // Identifier
                       [NSString stringWithFormat:@"bankAccountId = %@", self.bankAccountId],

                       // Basic account details
                       [NSString stringWithFormat:@"routingNumber = %@", self.routingNumber],
                       [NSString stringWithFormat:@"last4 = %@", self.last4],

                       // Additional account details (alphabetical)
                       [NSString stringWithFormat:@"bankName = %@", self.bankName],
                       [NSString stringWithFormat:@"country = %@", self.country],
                       [NSString stringWithFormat:@"currency = %@", self.currency],
                       [NSString stringWithFormat:@"fingerprint = %@", self.fingerprint],
                       [NSString stringWithFormat:@"status = %@", [self.class stringFromStatus:self.status]],

                       // Owner details
                       [NSString stringWithFormat:@"accountHolderName = %@", (self.accountHolderName) ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"accountHolderType = %@", [self.class stringFromAccountHolderType:self.accountHolderType]],
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

+ (instancetype)decodedObjectFromAPIResponse:(NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNullsValidatingRequiredFields:[self requiredFields]];
    if (!dict) {
        return nil;
    }
    
    STPBankAccount *bankAccount = [self new];

    // Identifier
    bankAccount.bankAccountId = dict[@"id"];

    // Basic account details
    bankAccount.routingNumber = dict[@"routing_number"];
    bankAccount.last4 = dict[@"last4"];

    // Additional account details (alphabetical)
    bankAccount.bankName = dict[@"bank_name"];
    bankAccount.country = dict[@"country"];
    bankAccount.currency = dict[@"currency"];
    bankAccount.fingerprint = dict[@"fingerprint"];
    bankAccount.status = [self statusFromString:dict[@"status"]];

    // Owner details
    bankAccount.accountHolderName = dict[@"account_holder_name"];
    bankAccount.accountHolderType = [self accountHolderTypeFromString:dict[@"account_holder_type"]];

    bankAccount.allResponseFields = dict;

    return bankAccount;
}

@end
