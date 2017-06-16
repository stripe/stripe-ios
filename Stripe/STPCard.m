//
//  STPCard.m
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/2/12.
//
//

#import "STPCard.h"

#import "NSDictionary+Stripe.h"
#import "STPImageLibrary+Private.h"
#import "STPImageLibrary.h"

@interface STPCard ()

@property (nonatomic, readwrite) NSString *cardId;
@property (nonatomic, readwrite) NSString *last4;
@property (nonatomic, readwrite) NSString *dynamicLast4;
@property (nonatomic, readwrite) STPCardBrand brand;
@property (nonatomic, readwrite) STPCardFundingType funding;
@property (nonatomic, readwrite) NSString *country;
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;

@end

@implementation STPCard

@dynamic number, cvc, expMonth, expYear, currency, name, address, addressLine1, addressLine2, addressCity, addressState, addressZip, addressCountry;

- (instancetype)initWithID:(NSString *)stripeID
                     brand:(STPCardBrand)brand
                     last4:(NSString *)last4
                  expMonth:(NSUInteger)expMonth
                   expYear:(NSUInteger)expYear
                   funding:(STPCardFundingType)funding {
    self = [super init];
    if (self) {
        _cardId = stripeID;
        _brand = brand;
        _last4 = last4;
        self.expMonth = expMonth;
        self.expYear = expYear;
        _funding = funding;
    }
    return self;
}

+ (STPCardBrand)brandFromString:(NSString *)string {
    NSString *brand = [string lowercaseString];
    if ([brand isEqualToString:@"visa"]) {
        return STPCardBrandVisa;
    } else if ([brand isEqualToString:@"american express"]) {
        return STPCardBrandAmex;
    } else if ([brand isEqualToString:@"mastercard"]) {
        return STPCardBrandMasterCard;
    } else if ([brand isEqualToString:@"discover"]) {
        return STPCardBrandDiscover;
    } else if ([brand isEqualToString:@"jcb"]) {
        return STPCardBrandJCB;
    } else if ([brand isEqualToString:@"diners club"]) {
        return STPCardBrandDinersClub;
    } else {
        return STPCardBrandUnknown;
    }
}

+ (NSString *)stringFromBrand:(STPCardBrand)brand {
    switch (brand) {
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
        case STPCardBrandUnknown:
            return @"Unknown";
    }
}

+ (STPCardFundingType)fundingFromString:(NSString *)string {
    NSString *funding = [string lowercaseString];
    if ([funding isEqualToString:@"credit"]) {
        return STPCardFundingTypeCredit;
    } else if ([funding isEqualToString:@"debit"]) {
        return STPCardFundingTypeDebit;
    } else if ([funding isEqualToString:@"prepaid"]) {
        return STPCardFundingTypePrepaid;
    } else {
        return STPCardFundingTypeOther;
    }
}

+ (NSString *)displayStringFromFunding:(STPCardFundingType)funding {
    switch (funding) {
        case STPCardFundingTypeCredit:
            return @"Credit";
        case STPCardFundingTypeDebit:
            return @"Debit";
        case STPCardFundingTypePrepaid:
            return @"Prepaid";
        case STPCardFundingTypeOther:
            return @"Other";
    }
}

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

- (BOOL)isApplePayCard {
    return [self.allResponseFields[@"tokenization_method"] isEqualToString:@"apple_pay"];
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

- (NSString *)description {
    NSArray *descriptionComponents = @[
                                       // NSObject
                                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                                       // Card ID
                                       [NSString stringWithFormat:@"cardId = %@", self.cardId],

                                       // Basic card details
                                       [NSString stringWithFormat:@"brand = %@", [STPCard stringFromBrand:self.brand]],
                                       [NSString stringWithFormat:@"last4 = %@", self.last4],
                                       [NSString stringWithFormat:@"expMonth = %lu", (unsigned long)self.expMonth],
                                       [NSString stringWithFormat:@"expYear = %lu", (unsigned long)self.expYear],
                                       [NSString stringWithFormat:@"funding = %@", [STPCard displayStringFromFunding:self.funding]],

                                       // Additional card details
                                       [NSString stringWithFormat:@"country = %@", self.country],
                                       [NSString stringWithFormat:@"currency = %@", self.currency],
                                       [NSString stringWithFormat:@"dynamicLast4 = %@", self.dynamicLast4],
                                       [NSString stringWithFormat:@"isApplePayCard = %@", (self.isApplePayCard) ? @"YES" : @"NO"],

                                       // Cardholder details
                                       [NSString stringWithFormat:@"name = %@", (self.name.length > 0) ? @"<redacted>" : nil],
                                       [NSString stringWithFormat:@"address = %@", (self.address) ? @"<redacted>" : nil],
                                       ];
    return [NSString stringWithFormat:@"<%@>", [descriptionComponents componentsJoinedByString:@"; "]];
}

- (STPAddress *)address {
    if (self.name || self.addressLine1 || self.addressLine2 || self.addressZip || self.addressCity || self.addressState || self.addressCountry) {
        STPAddress *address = [STPAddress new];
        address.name = self.name;
        address.line1 = self.addressLine1;
        address.line2 = self.addressLine2;
        address.postalCode = self.addressZip;
        address.city = self.addressCity;
        address.state = self.addressState;
        address.country = self.addressCountry;
        return address;
    }
    return nil;
}

#pragma mark STPAPIResponseDecodable
+ (NSArray *)requiredFields {
    return @[@"id", @"last4", @"brand", @"exp_month", @"exp_year"];
}

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
    NSString *brand = [dict[@"brand"] lowercaseString];
    card.brand = [self.class brandFromString:brand];
    NSString *funding = dict[@"funding"];
    card.funding = [self.class fundingFromString:funding];
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

#pragma mark - STPSource

- (NSString *)stripeID {
    return self.cardId;
}

- (NSString *)label {
    NSString *brand = [self.class stringFromBrand:self.brand];
    return [NSString stringWithFormat:@"%@ %@", brand, self.last4];
}

- (UIImage *)image {
    return [STPImageLibrary brandImageForCardBrand:self.brand];
}

- (UIImage *)templateImage {
    return [STPImageLibrary templatedBrandImageForCardBrand:self.brand];
}

@end
