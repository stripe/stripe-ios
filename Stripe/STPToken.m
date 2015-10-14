//
//  STPToken.m
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/5/12.
//
//

#import "STPToken.h"
#import "STPCard.h"
#import "STPBankAccount.h"

@interface STPToken()
@property (nonatomic, nonnull) NSString *tokenId;
@property (nonatomic) BOOL livemode;
@property (nonatomic, nullable) STPCard *card;
@property (nonatomic, nullable) STPBankAccount *bankAccount;
@property (nonatomic, nullable) NSDate *created;
@end

@implementation STPToken

- (NSString *)description {
    NSString *token = self.tokenId ?: @"Unknown token";
    NSString *livemode = self.livemode ? @"live mode" : @"test mode";

    return [NSString stringWithFormat:@"%@ (%@)", token, livemode];
}

- (BOOL)isEqual:(id)object {
    return [self isEqualToToken:object];
}

- (NSUInteger)hash {
    return [self.tokenId hash];
}

- (BOOL)isEqualToToken:(STPToken *)object {
    if (self == object) {
        return YES;
    }

    if (!object || ![object isKindOfClass:self.class]) {
        return NO;
    }

    if ((self.card || object.card) && (![self.card isEqual:object.card])) {
        return NO;
    }

    if ((self.bankAccount || object.bankAccount) && (![self.bankAccount isEqual:object.bankAccount])) {
        return NO;
    }

    return self.livemode == object.livemode && [self.tokenId isEqualToString:object.tokenId] && [self.created isEqualToDate:object.created] &&
           [self.card isEqual:object.card] && [self.tokenId isEqualToString:object.tokenId] && [self.created isEqualToDate:object.created];
}

#pragma mark STPAPIResponseDecodable

+ (instancetype)decodedObjectFromAPIResponse:(NSDictionary *)response {
    STPToken *token = [self new];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [response enumerateKeysAndObjectsUsingBlock:^(id key, id obj, __unused BOOL *stop) {
        if (obj != [NSNull null]) {
            dict[key] = obj;
        }
    }];
    
    token.tokenId = dict[@"id"] ?: @"";
    token.livemode = [dict[@"livemode"] boolValue];
    token.created = [NSDate dateWithTimeIntervalSince1970:[dict[@"created"] doubleValue]];
    
    NSDictionary *cardDictionary = dict[@"card"];
    if (cardDictionary) {
        token.card = [STPCard decodedObjectFromAPIResponse:cardDictionary];
    }
    
    NSDictionary *bankAccountDictionary = dict[@"bank_account"];
    if (bankAccountDictionary) {
        token.bankAccount = [STPBankAccount decodedObjectFromAPIResponse:bankAccountDictionary];
    }
    return token;
}

@end
