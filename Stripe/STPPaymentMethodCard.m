//
//  STPPaymentMethodCard.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodCard.h"

#import "NSDictionary+Stripe.h"
#import "STPPaymentMethodCardChecks.h"
#import "STPPaymentMethodThreeDSecureUsage.h"
#import "STPCard.h"

@interface STPPaymentMethodCard ()

@property (nonatomic) STPCardBrand brand;
@property (nonatomic, nullable) STPPaymentMethodCardChecks *checks;
@property (nonatomic, nullable) NSString *country;
@property (nonatomic) NSInteger expMonth;
@property (nonatomic) NSInteger expYear;
@property (nonatomic, nullable) NSString *funding;
@property (nonatomic, nullable) NSString *last4;
@property (nonatomic, nullable) NSString *fingerprint;
@property (nonatomic, nullable) STPPaymentMethodThreeDSecureUsage *threeDSecureUsage;
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;

@end

@implementation STPPaymentMethodCard

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                       
                       [NSString stringWithFormat:@"brand = %@", [STPCard stringFromBrand:self.brand]],
                       [NSString stringWithFormat:@"checks = %@", self.checks],
                       [NSString stringWithFormat:@"country = %@", self.country],
                       [NSString stringWithFormat:@"expMonth = %lu", (unsigned long)self.expMonth],
                       [NSString stringWithFormat:@"expYear = %lu", (unsigned long)self.expYear],
                       [NSString stringWithFormat:@"funding = %@", self.funding],
                       [NSString stringWithFormat:@"last4 = %@", self.last4],
                       [NSString stringWithFormat:@"fingerprint = %@", self.fingerprint],
                       [NSString stringWithFormat:@"threeDSecureUsage = %@", self.threeDSecureUsage],
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
    card.brand = [STPCard brandFromString:[dict stp_stringForKey:@"brand"]];
    card.checks = [STPPaymentMethodCardChecks decodedObjectFromAPIResponse:[dict stp_dictionaryForKey:@"checks"]];
    card.country = [dict stp_stringForKey:@"country"];
    card.expMonth = [dict stp_intForKey:@"exp_month" or:0];
    card.expYear = [dict stp_intForKey:@"exp_year" or:0];
    card.funding = [dict stp_stringForKey:@"funding"];
    card.last4 = [dict stp_stringForKey:@"last4"];
    card.fingerprint = [dict stp_stringForKey:@"fingerprint"];
    card.threeDSecureUsage = [STPPaymentMethodThreeDSecureUsage decodedObjectFromAPIResponse:[dict stp_dictionaryForKey:@"three_d_secure_usage"]];
    return card;
}

@end
