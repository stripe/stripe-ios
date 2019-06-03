//
//  STPPaymentMethodCard.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodCard.h"

#import "NSDictionary+Stripe.h"
#import "STPPaymentMethodCardWallet.h"
#import "STPPaymentMethodCardChecks.h"
#import "STPPaymentMethodThreeDSecureUsage.h"

@interface STPPaymentMethodCard ()

@property (nonatomic, readwrite) STPCardBrand brand;
@property (nonatomic, strong, nullable, readwrite) STPPaymentMethodCardChecks *checks;
@property (nonatomic, copy, nullable, readwrite) NSString *country;
@property (nonatomic, readwrite) NSInteger expMonth;
@property (nonatomic, readwrite) NSInteger expYear;
@property (nonatomic, copy, nullable, readwrite) NSString *funding;
@property (nonatomic, copy, nullable, readwrite) NSString *last4;
@property (nonatomic, copy, nullable, readwrite) NSString *fingerprint;
@property (nonatomic, strong, nullable, readwrite) STPPaymentMethodThreeDSecureUsage *threeDSecureUsage;
@property (nonatomic, strong, nullable, readwrite) STPPaymentMethodCardWallet *wallet;
@property (nonatomic, copy, nonnull, readwrite) NSDictionary *allResponseFields;

@end

@implementation STPPaymentMethodCard

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                       
                       [NSString stringWithFormat:@"brand = %@", STPStringFromCardBrand(self.brand)],
                       [NSString stringWithFormat:@"checks = %@", self.checks],
                       [NSString stringWithFormat:@"country = %@", self.country],
                       [NSString stringWithFormat:@"expMonth = %lu", (unsigned long)self.expMonth],
                       [NSString stringWithFormat:@"expYear = %lu", (unsigned long)self.expYear],
                       [NSString stringWithFormat:@"funding = %@", self.funding],
                       [NSString stringWithFormat:@"last4 = %@", self.last4],
                       [NSString stringWithFormat:@"fingerprint = %@", self.fingerprint],
                       [NSString stringWithFormat:@"threeDSecureUsage = %@", self.threeDSecureUsage],
                       [NSString stringWithFormat:@"wallet = %@", self.wallet],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPAPIResponseDecodable

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }
    STPPaymentMethodCard *card = [self new];
    card.allResponseFields = dict;
    card.brand = [self brandFromString:[dict stp_stringForKey:@"brand"]];
    card.checks = [STPPaymentMethodCardChecks decodedObjectFromAPIResponse:[dict stp_dictionaryForKey:@"checks"]];
    card.country = [dict stp_stringForKey:@"country"];
    card.expMonth = [dict stp_intForKey:@"exp_month" or:0];
    card.expYear = [dict stp_intForKey:@"exp_year" or:0];
    card.funding = [dict stp_stringForKey:@"funding"];
    card.last4 = [dict stp_stringForKey:@"last4"];
    card.fingerprint = [dict stp_stringForKey:@"fingerprint"];
    card.threeDSecureUsage = [STPPaymentMethodThreeDSecureUsage decodedObjectFromAPIResponse:[dict stp_dictionaryForKey:@"three_d_secure_usage"]];
    card.wallet = [STPPaymentMethodCardWallet decodedObjectFromAPIResponse:[dict stp_dictionaryForKey:@"wallet"]];
    return card;
}

#pragma mark - STPCardBrand

+ (NSString *)stringFromBrand:(STPCardBrand)brand {
    return STPStringFromCardBrand(brand);
}

+ (STPCardBrand)brandFromString:(NSString *)string {
    // Documentation: https://stripe.com/docs/api/payment_methods/object#payment_method_object-card-brand
    NSString *brand = [string lowercaseString];
    if ([brand isEqualToString:@"visa"]) {
        return STPCardBrandVisa;
    } else if ([brand isEqualToString:@"amex"]) {
        return STPCardBrandAmex;
    } else if ([brand isEqualToString:@"mastercard"]) {
        return STPCardBrandMasterCard;
    } else if ([brand isEqualToString:@"discover"]) {
        return STPCardBrandDiscover;
    } else if ([brand isEqualToString:@"jcb"]) {
        return STPCardBrandJCB;
    } else if ([brand isEqualToString:@"diners"]) {
        return STPCardBrandDinersClub;
    } else if ([brand isEqualToString:@"unionpay"]) {
        return STPCardBrandUnionPay;
    } else {
        return STPCardBrandUnknown;
    }
}

@end
