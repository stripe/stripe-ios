//
//  STPBankAccount.m
//  Stripe
//
//  Created by Charles Scalesse on 10/1/14.
//
//

#import "STPBankAccount.h"

@interface STPBankAccount ()

@property (nonatomic, readwrite) NSString *bankAccountId;
@property (nonatomic, readwrite) NSString *last4;
@property (nonatomic, readwrite) NSString *bankName;
@property (nonatomic, readwrite) NSString *fingerprint;
@property (nonatomic, readwrite) BOOL validated;
@property (nonatomic, readwrite) BOOL disabled;

@end

@implementation STPBankAccount

@synthesize routingNumber, country, currency;

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

#pragma mark STPAPIResponseDecodable

+ (instancetype)decodedObjectFromAPIResponse:(NSDictionary *)response {
    STPBankAccount *bankAccount = [self new];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [response enumerateKeysAndObjectsUsingBlock:^(id key, id obj, __unused BOOL *stop) {
        if (obj != [NSNull null]) {
            dict[key] = obj;
        }
    }];
    
    bankAccount.bankAccountId = dict[@"id"];
    bankAccount.last4 = dict[@"last4"];
    bankAccount.bankName = dict[@"bank_name"];
    bankAccount.country = dict[@"country"];
    bankAccount.fingerprint = dict[@"fingerprint"];
    bankAccount.currency = dict[@"currency"];
    bankAccount.validated = [dict[@"validated"] boolValue];
    bankAccount.disabled = [dict[@"disabled"] boolValue];
    return bankAccount;
}

@end
