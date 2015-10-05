//
//  STPCard.m
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/2/12.
//
//

#import "STPCard.h"
#import "StripeError.h"
#import "STPCardValidator.h"

@interface STPCard ()

@property (nonatomic, readwrite) NSString *cardId;
@property (nonatomic, readwrite) NSString *last4;
@property (nonatomic, readwrite) NSString *dynamicLast4;
@property (nonatomic, readwrite) STPCardBrand brand;
@property (nonatomic, readwrite) STPCardFundingType funding;
@property (nonatomic, readwrite) NSString *fingerprint;
@property (nonatomic, readwrite) NSString *country;

@end

@implementation STPCard

@dynamic number, cvc, expMonth, expYear, currency, name, addressLine1, addressLine2, addressCity, addressState, addressZip, addressCountry;

- (instancetype)init {
    self = [super init];
    if (self) {
        _brand = STPCardBrandUnknown;
        _funding = STPCardFundingTypeOther;
    }

    return self;
}

- (NSString *)type {
    switch (self.brand) {
    case STPCardBrandAmex:
        return @"American Express";
    case STPCardBrandDinersClub:
        return @"Diners Club";
    case STPCardBrandDiscover:
        return @"Discover";
    case STPCardBrandJCB:
        return @"JCB";
    case STPCardBrandMasterCard:
        return @"MasterCard";
    case STPCardBrandVisa:
        return @"Visa";
    default:
        return @"Unknown";
    }
}

- (BOOL)isEqual:(id)other {
    return [self isEqualToCard:other];
}

- (NSUInteger)hash {
    return [self.cardId hash];
}

- (BOOL)isEqualToCard:(STPCard *)other {
    if (self == other) {
        return YES;
    }

    if (!other || ![other isKindOfClass:self.class]) {
        return NO;
    }
    
    return [self.cardId isEqualToString:other.cardId];
}

@end


@implementation STPCard(PrivateMethods)

- (instancetype)initWithAttributeDictionary:(NSDictionary *)attributeDictionary {
    self = [self init];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    [attributeDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, __unused BOOL *stop) {
        if (obj != [NSNull null]) {
            dict[key] = obj;
        }
    }];
    
    if (self) {
        _cardId = dict[@"id"];
        [super setName:dict[@"name"]];
        _last4 = dict[@"last4"];
        _dynamicLast4 = dict[@"dynamic_last4"];
        NSString *brand = dict[@"brand"] ?: dict[@"type"];
        if ([brand isEqualToString:@"Visa"]) {
            _brand = STPCardBrandVisa;
        } else if ([brand isEqualToString:@"American Express"]) {
            _brand = STPCardBrandAmex;
        } else if ([brand isEqualToString:@"MasterCard"]) {
            _brand = STPCardBrandMasterCard;
        } else if ([brand isEqualToString:@"Discover"]) {
            _brand = STPCardBrandDiscover;
        } else if ([brand isEqualToString:@"JCB"]) {
            _brand = STPCardBrandJCB;
        } else if ([brand isEqualToString:@"Diners Club"]) {
            _brand = STPCardBrandDinersClub;
        } else {
            _brand = STPCardBrandUnknown;
        }
        NSString *funding = dict[@"funding"];
        if ([funding.lowercaseString isEqualToString:@"credit"]) {
            _funding = STPCardFundingTypeCredit;
        } else if ([funding.lowercaseString isEqualToString:@"debit"]) {
            _funding = STPCardFundingTypeDebit;
        } else if ([funding.lowercaseString isEqualToString:@"prepaid"]) {
            _funding = STPCardFundingTypePrepaid;
        } else {
            _funding = STPCardFundingTypeOther;
        }
        _fingerprint = dict[@"fingerprint"];
        _country = dict[@"country"];
        self.currency = dict[@"currency"];
        // Support both camelCase and snake_case keys
        [super setExpMonth:[(dict[@"exp_month"] ?: dict[@"expMonth"])intValue]];
        [super setExpYear:[(dict[@"exp_year"] ?: dict[@"expYear"])intValue]];
        [super setAddressLine1:dict[@"address_line1"] ?: dict[@"addressLine1"]];
        [super setAddressLine2:dict[@"address_line2"] ?: dict[@"addressLine2"]];
        [super setAddressCity:dict[@"address_city"] ?: dict[@"addressCity"]];
        [super setAddressState:dict[@"address_state"] ?: dict[@"addressState"]];
        [super setAddressZip:dict[@"address_zip"] ?: dict[@"addressZip"]];
        [super setAddressCountry:dict[@"address_country"] ?: dict[@"addressCountry"]];
    }
    
    return self;
}

@end


