//
//  STPToken.m
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/5/12.
//
//

#import "STPToken.h"

#import "NSDictionary+Stripe.h"
#import "STPBankAccount.h"
#import "STPCard.h"

@interface STPToken()
@property (nonatomic, nonnull) NSString *tokenId;
@property (nonatomic) BOOL livemode;
@property (nonatomic) STPTokenType type;
@property (nonatomic, nullable) STPCard *card;
@property (nonatomic, nullable) STPBankAccount *bankAccount;
@property (nonatomic, nullable) NSDate *created;
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;
@end

@implementation STPToken

#pragma mark - Description

- (NSString *)description {
    return self.tokenId ?: @"Unknown token";
}

- (NSString *)debugDescription {
    NSString *token = self.tokenId ?: @"Unknown token";
    NSString *livemode = self.livemode ? @"live mode" : @"test mode";
    return [NSString stringWithFormat:@"%@ (%@)", token, livemode];
}

#pragma mark - Equality

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

    return self.livemode == object.livemode &&
    self.type == object.type &&
    [self.tokenId isEqualToString:object.tokenId] &&
    [self.created isEqualToDate:object.created] &&
    [self.card isEqual:object.card] &&
    [self.created isEqualToDate:object.created];
}

#pragma mark - STPSourceProtocol

- (NSString *)stripeID {
    return self.tokenId;
}

#pragma mark - STPAPIResponseDecodable

+ (instancetype)decodedObjectFromAPIResponse:(NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }

    // required fields
    NSString *stripeId = [dict stp_stringForKey:@"id"];
    NSDate *created = [dict stp_dateForKey:@"created"];
    NSString *rawType = [dict stp_stringForKey:@"type"];
    if (!stripeId || !created || !dict[@"livemode"] || ![[self class] _isValidRawTokenType:rawType]) {
        return nil;
    }
    
    STPToken *token = [self new];
    token.tokenId = stripeId;
    token.livemode = [dict stp_boolForKey:@"livemode" or:YES];
    token.created = created;
    token.type = [[self class] _tokenTypeForString:rawType];
    
    NSDictionary *rawCard = [dict stp_dictionaryForKey:@"card"];
    token.card = [STPCard decodedObjectFromAPIResponse:rawCard];

    NSDictionary *rawBankAccount = [dict stp_dictionaryForKey:@"bank_account"];
    token.bankAccount = [STPBankAccount decodedObjectFromAPIResponse:rawBankAccount];

    token.allResponseFields = dict;
    return token;
}

#pragma mark - STPTokenType

+ (BOOL)_isValidRawTokenType:(NSString *)rawType {
    if ([rawType isEqualToString:@"account"] ||
        [rawType isEqualToString:@"bank_account"] ||
        [rawType isEqualToString:@"card"] ||
        [rawType isEqualToString:@"pii"] ||
        [rawType isEqualToString:@"cvc_update"]
        ) {
        return YES;
    }
    return NO;
}

+ (STPTokenType)_tokenTypeForString:(NSString *)rawType {
    if ([rawType isEqualToString:@"account"]) {
        return STPTokenTypeAccount;
    } else if ([rawType isEqualToString:@"bank_account"]) {
        return STPTokenTypeBankAccount;
    } else if ([rawType isEqualToString:@"card"]) {
        return STPTokenTypeCard;
    } else if ([rawType isEqualToString:@"pii"]) {
        return STPTokenTypePII;
    } else if ([rawType isEqualToString:@"cvc_update"]) {
        return STPTokenTypeCVCUpdate;
    }

    // default return STPTokenTypeAccount (this matches other default enum behavior)
    return STPTokenTypeAccount;
}

@end
