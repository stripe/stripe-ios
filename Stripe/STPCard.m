//
//  STPCard.m
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/2/12.
//
//

#import "STPCard.h"
#import "STPCard+Private.h"

#import "NSDictionary+Stripe.h"
#import "STPImageLibrary+Private.h"
#import "STPImageLibrary.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPCard ()

@property (nonatomic, copy) NSString *stripeID;

@property (nonatomic, copy, nullable, readwrite) NSString *name;
@property (nonatomic, copy, readwrite) NSString *last4;
@property (nonatomic, copy, nullable, readwrite) NSString *dynamicLast4;
@property (nonatomic, assign, readwrite) STPCardBrand brand;
@property (nonatomic, assign, readwrite) STPCardFundingType funding;
@property (nonatomic, copy, nullable, readwrite) NSString *country;
@property (nonatomic, copy, nullable, readwrite) NSString *currency;
@property (nonatomic, assign, readwrite) NSUInteger expMonth;
@property (nonatomic, assign, readwrite) NSUInteger expYear;
@property (nonatomic, strong, readwrite) STPAddress *address;
@property (nonatomic, copy, nullable, readwrite) NSDictionary<NSString *, NSString *> *metadata;
@property (nonatomic, copy, readwrite) NSDictionary *allResponseFields;

// See STPCard+Private.h

@end

@implementation STPCard

#pragma mark - STPCardBrand

+ (STPCardBrand)brandFromString:(NSString *)string {
    // Documentation: https://stripe.com/docs/api#card_object-brand
    NSString *brand = [string lowercaseString];
    if ([brand isEqualToString:@"visa"]) {
        return STPCardBrandVisa;
    } else if ([brand isEqualToString:@"american express"] || [brand isEqualToString:@"american_express"]) {
        return STPCardBrandAmex;
    } else if ([brand isEqualToString:@"mastercard"]) {
        return STPCardBrandMasterCard;
    } else if ([brand isEqualToString:@"discover"]) {
        return STPCardBrandDiscover;
    } else if ([brand isEqualToString:@"jcb"]) {
        return STPCardBrandJCB;
    } else if ([brand isEqualToString:@"diners club"] || [brand isEqualToString:@"diners_club"]) {
        return STPCardBrandDinersClub;
    } else if ([brand isEqualToString:@"unionpay"]) {
        return STPCardBrandUnionPay;
    } else {
        return STPCardBrandUnknown;
    }
}

+ (NSString *)stringFromBrand:(STPCardBrand)brand {
    return STPStringFromCardBrand(brand);
}

#pragma mark - STPCardFundingType

+ (NSDictionary <NSString *, NSNumber *> *)stringToFundingMapping {
    return @{
             @"credit": @(STPCardFundingTypeCredit),
             @"debit": @(STPCardFundingTypeDebit),
             @"prepaid": @(STPCardFundingTypePrepaid),
             };
}

+ (STPCardFundingType)fundingFromString:(NSString *)string {
    NSString *key = [string lowercaseString];
    NSNumber *fundingNumber = [self stringToFundingMapping][key];

    if (fundingNumber != nil) {
        return (STPCardFundingType)[fundingNumber integerValue];
    }

    return STPCardFundingTypeOther;
}

+ (nullable NSString *)stringFromFunding:(STPCardFundingType)funding {
    return [[[self stringToFundingMapping] allKeysForObject:@(funding)] firstObject];
}

#pragma mark -

- (BOOL)isApplePayCard {
    return [self.allResponseFields[@"tokenization_method"] isEqualToString:@"apple_pay"];
}

#pragma mark - Equality

- (BOOL)isEqual:(nullable id)other {
    return [self isEqualToCard:other];
}

- (NSUInteger)hash {
    return [self.stripeID hash];
}

- (BOOL)isEqualToCard:(nullable STPCard *)other {
    if (self == other) {
        return YES;
    }

    if (!other || ![other isKindOfClass:self.class]) {
        return NO;
    }
    
    return [self.stripeID isEqualToString:other.stripeID];
}

#pragma mark - Description

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                       // Identifier
                       [NSString stringWithFormat:@"stripeID = %@", self.stripeID],

                       // Basic card details
                       [NSString stringWithFormat:@"brand = %@", [self.class stringFromBrand:self.brand]],
                       [NSString stringWithFormat:@"last4 = %@", self.last4],
                       [NSString stringWithFormat:@"expMonth = %lu", (unsigned long)self.expMonth],
                       [NSString stringWithFormat:@"expYear = %lu", (unsigned long)self.expYear],
                       [NSString stringWithFormat:@"funding = %@", ([self.class stringFromFunding:self.funding]) ?: @"unknown"],

                       // Additional card details (alphabetical)
                       [NSString stringWithFormat:@"country = %@", self.country],
                       [NSString stringWithFormat:@"currency = %@", self.currency],
                       [NSString stringWithFormat:@"dynamicLast4 = %@", self.dynamicLast4],
                       [NSString stringWithFormat:@"isApplePayCard = %@", (self.isApplePayCard) ? @"YES" : @"NO"],
                       [NSString stringWithFormat:@"metadata = %@", (self.metadata) ? @"<redacted>" : nil],

                       // Cardholder details
                       [NSString stringWithFormat:@"name = %@", (self.name) ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"address = %@", (self.address) ? @"<redacted>" : nil],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPAPIResponseDecodable

- (NSString *)stripeObject {
    return @"card";
}

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }

    // required fields
    NSString *stripeId = [dict stp_stringForKey:@"id"];
    NSString *last4 = [dict stp_stringForKey:@"last4"];
    NSString *rawBrand = [dict stp_stringForKey:@"brand"];
    NSNumber *rawExpMonth = [dict stp_numberForKey:@"exp_month"];
    NSNumber *rawExpYear = [dict stp_numberForKey:@"exp_year"];
    if (stripeId == nil || last4 == nil || rawBrand == nil || rawExpMonth == nil || rawExpYear == nil) {
        return nil;
    }

    STPCard *card = [self new];
    card.address = [STPAddress new];

    card.stripeID = stripeId;
    card.name = [dict stp_stringForKey:@"name"];
    card.last4 = last4;
    card.dynamicLast4 = [dict stp_stringForKey:@"dynamic_last4"];
    card.brand = [self.class brandFromString:rawBrand];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    // This is only intended to be deprecated publicly.
    // When removed from public header, can remove these pragmas
    NSString *rawFunding = [dict stp_stringForKey:@"funding"];
    card.funding = [self.class fundingFromString:rawFunding];
#pragma clang diagnostic pop

    card.country = [dict stp_stringForKey:@"country"];
    card.currency = [dict stp_stringForKey:@"currency"];
    card.expMonth = [dict stp_intForKey:@"exp_month" or:0];
    card.expYear = [dict stp_intForKey:@"exp_year" or:0];
    card.metadata = [[dict stp_dictionaryForKey:@"metadata"] stp_dictionaryByRemovingNonStrings];

    card.address.name = card.name;
    card.address.line1 = [dict stp_stringForKey:@"address_line1"];
    card.address.line2 = [dict stp_stringForKey:@"address_line2"];
    card.address.city = [dict stp_stringForKey:@"address_city"];
    card.address.state = [dict stp_stringForKey:@"address_state"];
    card.address.postalCode = [dict stp_stringForKey:@"address_zip"];
    card.address.country = [dict stp_stringForKey:@"address_country"];
    
    card.allResponseFields = dict;
    return card;
}

#pragma mark - STPPaymentOption

- (UIImage *)image {
    return [STPImageLibrary brandImageForCardBrand:self.brand];
}

- (UIImage *)templateImage {
    return [STPImageLibrary templatedBrandImageForCardBrand:self.brand];
}

- (NSString *)label {
    NSString *brand = [self.class stringFromBrand:self.brand];
    return [NSString stringWithFormat:@"%@ %@", brand, self.last4];
}

#pragma mark - Deprecated methods

- (instancetype)initWithID:(NSString *)stripeID
                     brand:(STPCardBrand)brand
                     last4:(NSString *)last4
                  expMonth:(NSUInteger)expMonth
                   expYear:(NSUInteger)expYear
                   funding:(STPCardFundingType)funding {
    self = [super init];
    if (self) {
        _stripeID = stripeID.copy;
        _brand = brand;
        _last4 = last4.copy;
        _expMonth = expMonth;
        _expYear = expYear;
        _funding = funding;
        _address = [STPAddress new];
    }
    return self;
}

- (NSString *)cardId {
    return self.stripeID;
}

- (nullable NSString *)addressLine1 {
    return self.address.line1;
}

- (nullable NSString *)addressLine2 {
    return self.address.line2;
}

- (nullable NSString *)addressZip {
    return self.address.postalCode;
}

- (nullable NSString *)addressCity {
    return self.address.city;
}

- (nullable NSString *)addressState {
    return self.address.state;
}

- (nullable NSString *)addressCountry {
    return self.address.country;
}

- (BOOL)isReusable {
    return YES;
}

@end

NS_ASSUME_NONNULL_END
