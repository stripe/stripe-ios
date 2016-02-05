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
#import "NSDictionary+Stripe.h"

@interface STPCard ()

@property (nonatomic, readwrite) NSString *cardId;
@property (nonatomic, readwrite) NSString *last4;
@property (nonatomic, readwrite) NSString *dynamicLast4;
@property (nonatomic, readwrite) STPCardBrand brand;
@property (nonatomic, readwrite) STPCardFundingType funding;
@property (nonatomic, readwrite) NSString *fingerprint;
@property (nonatomic, readwrite) NSString *country;
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;

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

- (NSString *)last4 {
    return _last4 ?: [super last4];
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

#pragma mark STPAPIResponseDecodable
+ (NSArray *)requiredFields {
    return @[@"id", @"last4", @"brand", @"exp_month", @"exp_year"];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
+ (instancetype)decodedObjectFromAPIResponse:(NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNullsValidatingRequiredFields:[self requiredFields]];
    if (!dict) {
        return nil;
    }
    
    STPCard *card = [self new];
    card.cardId = dict[@"id"];
    card.name = dict[@"name"];
    card.last4 = dict[@"last4"];
    card.dynamicLast4 = dict[@"dynamic_last4"];
    NSString *brand = dict[@"brand"];
    if ([brand isEqualToString:@"Visa"]) {
        card.brand = STPCardBrandVisa;
    } else if ([brand isEqualToString:@"American Express"]) {
        card.brand = STPCardBrandAmex;
    } else if ([brand isEqualToString:@"MasterCard"]) {
        card.brand = STPCardBrandMasterCard;
    } else if ([brand isEqualToString:@"Discover"]) {
        card.brand = STPCardBrandDiscover;
    } else if ([brand isEqualToString:@"JCB"]) {
        card.brand = STPCardBrandJCB;
    } else if ([brand isEqualToString:@"Diners Club"]) {
        card.brand = STPCardBrandDinersClub;
    } else {
        card.brand = STPCardBrandUnknown;
    }
    NSString *funding = dict[@"funding"];
    if ([funding.lowercaseString isEqualToString:@"credit"]) {
        card.funding = STPCardFundingTypeCredit;
    } else if ([funding.lowercaseString isEqualToString:@"debit"]) {
        card.funding = STPCardFundingTypeDebit;
    } else if ([funding.lowercaseString isEqualToString:@"prepaid"]) {
        card.funding = STPCardFundingTypePrepaid;
    } else {
        card.funding = STPCardFundingTypeOther;
    }
    card.fingerprint = dict[@"fingerprint"];
    card.country = dict[@"country"];
    card.currency = dict[@"currency"];
    card.expMonth = [dict[@"exp_month"] intValue];
    card.expYear = [dict[@"exp_year"] intValue];
    card.addressLine1 = dict[@"address_line1"];
    card.addressLine2 = dict[@"address_line2"];
    card.addressCity = dict[@"address_city"];
    card.addressState = dict[@"address_state"];
    card.addressZip = dict[@"address_zip"];
    card.addressCountry = dict[@"address_country"];
    
    card.allResponseFields = dict;
    return card;
}
#pragma clang diagnostic pop

@end
