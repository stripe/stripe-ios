//
//  STPBankAccount.m
//  Stripe
//
//  Created by Charles Scalesse on 10/1/14.
//
//

#import "STPBankAccount.h"

@interface STPBankAccount ()

@property (nonatomic, readwrite) NSString *object;
@property (nonatomic, readwrite) NSString *last4;
@property (nonatomic, readwrite) NSString *bankName;
@property (nonatomic, readwrite) BOOL validated;

@end

@implementation STPBankAccount

#pragma mark - Constructors

- (id)init {
    self = [super init];
    if (self) {
        self.object = @"bank_account";
    }
    return self;
}

- (id)initWithAttributeDictionary:(NSDictionary *)attributeDictionary {
    self = [self init];
    if (self) {
        self.last4 = attributeDictionary[@"last4"];
        self.bankName = attributeDictionary[@"bank_name"];
        self.country = attributeDictionary[@"country"];
        self.validated = [attributeDictionary[@"validated"] boolValue];
    }
    return self;
}

#pragma mark - Equality

- (BOOL)isEqual:(STPBankAccount *)bankAccount {
    return [self isEqualToBankAccount:bankAccount];
}

- (BOOL)isEqualToBankAccount:(STPBankAccount *)bankAccount {
    if (self == bankAccount) {
        return YES;
    }
    
    if (!bankAccount || ![bankAccount isKindOfClass:self.class]) {
        return NO;
    }
    
    return [self.accountNumber ?: @"" isEqualToString:bankAccount.accountNumber ?: @""]
        && [self.routingNumber ?: @"" isEqualToString:bankAccount.routingNumber ?: @""]
        && [self.country ?: @"" isEqualToString:bankAccount.country ?: @""]
        && [self.last4 ?: @"" isEqualToString:bankAccount.last4 ?: @""]
        && [self.bankName ?: @"" isEqualToString:bankAccount.bankName ?: @""];
}

@end
