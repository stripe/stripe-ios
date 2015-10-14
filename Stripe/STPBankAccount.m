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

@end

@implementation STPBankAccount (PrivateMethods)

- (instancetype)initWithAttributeDictionary:(NSDictionary *)attributeDictionary {
    self = [self init];
    if (self) {
        // sanitize NSNull
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        [attributeDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, __unused BOOL *stop) {
            if (obj != [NSNull null]) {
                dictionary[key] = obj;
            }
        }];

        _bankAccountId = dictionary[@"id"];
        _last4 = dictionary[@"last4"];
        _bankName = dictionary[@"bank_name"];
        [self setCountry:dictionary[@"country"]];
        _fingerprint = dictionary[@"fingerprint"];
        [self setCurrency:dictionary[@"currency"]];
        _validated = [dictionary[@"validated"] boolValue];
        _disabled = [dictionary[@"disabled"] boolValue];
    }
    return self;
}

@end
