//
//  STPBankAccount.m
//  Stripe
//
//  Created by Charles Scalesse on 10/1/14.
//
//

#import "STPBankAccount.h"
#import "NSDictionary+Stripe.h"

@interface STPBankAccount ()

@property (nonatomic, readwrite) NSString *bankAccountId;
@property (nonatomic, readwrite) NSString *last4;
@property (nonatomic, readwrite) NSString *bankName;
@property (nonatomic, readwrite) NSString *fingerprint;
@property (nonatomic) STPBankAccountStatus status;
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;

@end

@implementation STPBankAccount

@synthesize routingNumber, country, currency, accountHolderName, accountHolderType;

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
    NSString *statusDescription;

    switch (self.status) {
        case STPBankAccountStatusNew:
            statusDescription = @"new";
        case STPBankAccountStatusValidated:
            statusDescription = @"validated";
        case STPBankAccountStatusVerified:
            statusDescription = @"verified";
        case STPBankAccountStatusErrored:
            statusDescription = @"errored";
    }

    NSString *accountHolderTypeDescription;

    switch (self.accountHolderType) {
        case STPBankAccountHolderTypeIndividual:
            accountHolderTypeDescription = @"individual";
        case STPBankAccountHolderTypeCompany:
            accountHolderTypeDescription = @"company";
    }

    NSArray *descriptionComponents = @[
                                       // Object
                                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                                       // Identifier
                                       [NSString stringWithFormat:@"bankAccountId = %@", self.bankAccountId],

                                       // Basic account details
                                       [NSString stringWithFormat:@"routingNumber = %@", self.routingNumber],
                                       [NSString stringWithFormat:@"last4 = %@", self.last4],

                                       // Additional account details
                                       [NSString stringWithFormat:@"bankName = %@", self.bankName],
                                       [NSString stringWithFormat:@"country = %@", self.country],
                                       [NSString stringWithFormat:@"currency = %@", self.currency],
                                       [NSString stringWithFormat:@"fingerprint = %@", self.fingerprint],
                                       [NSString stringWithFormat:@"status = %@", statusDescription],

                                       // Owner details
                                       [NSString stringWithFormat:@"accountHolderName = %@", (self.accountHolderName) ? @"<redacted>" : nil],
                                       [NSString stringWithFormat:@"accountHolderType = %@", accountHolderTypeDescription],
                                       ];

    return [NSString stringWithFormat:@"<%@>", [descriptionComponents componentsJoinedByString:@"; "]];
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
    bankAccount.bankAccountId = dict[@"id"];
    bankAccount.last4 = dict[@"last4"];
    bankAccount.bankName = dict[@"bank_name"];
    bankAccount.country = dict[@"country"];
    bankAccount.fingerprint = dict[@"fingerprint"];
    bankAccount.currency = dict[@"currency"];
    bankAccount.accountHolderName = dict[@"account_holder_name"];
    NSString *accountHolderType = dict[@"account_holder_type"];
    if ([accountHolderType isEqualToString:@"individual"]) {
        bankAccount.accountHolderType = STPBankAccountHolderTypeIndividual;
    } else if ([accountHolderType isEqualToString:@"company"]) {
        bankAccount.accountHolderType = STPBankAccountHolderTypeCompany;
    }
    NSString *status = dict[@"status"];
    if ([status isEqual: @"new"]) {
        bankAccount.status = STPBankAccountStatusNew;
    } else if ([status isEqual: @"validated"]) {
        bankAccount.status = STPBankAccountStatusValidated;
    } else if ([status isEqual: @"verified"]) {
        bankAccount.status = STPBankAccountStatusVerified;
    } else if ([status isEqual: @"errored"]) {
        bankAccount.status = STPBankAccountStatusErrored;
    }
    
    bankAccount.allResponseFields = dict;
    return bankAccount;
}

@end
