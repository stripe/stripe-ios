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

@interface STPPaymentMethodCard ()

@property (nonatomic, nullable) NSString *brand;
@property (nonatomic, nullable) STPPaymentMethodCardChecks *checks;
@property (nonatomic, nullable) NSString *country;
@property (nonatomic, nullable) NSString *expMonth;
@property (nonatomic, nullable) NSString *expYear;
@property (nonatomic, nullable) NSString *funding;
@property (nonatomic, nullable) NSString *last4;
@property (nonatomic, nullable) STPPaymentMethodThreeDSecureUsage *threeDSecureUsage;
@property (nonatomic, nullable) STPPaymentMethodCardWallet *wallet;
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;

@end

@implementation STPPaymentMethodCard

#pragma mark - STPAPIResponseDecodable

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }
    STPPaymentMethodCard *card = [STPPaymentMethodCard new];
    card.allResponseFields = dict;
    card.brand = [dict stp_stringForKey:@"brand"];
    card.checks = [STPPaymentMethodCardChecks decodedObjectFromAPIResponse:[dict stp_dictionaryForKey:@"checks"]];
    card.country = [dict stp_stringForKey:@"country"];
    card.expMonth = [dict stp_stringForKey:@"exp_month"];
    card.expYear = [dict stp_stringForKey:@"exp_year"];
    card.funding = [dict stp_stringForKey:@"funding"];
    card.last4 = [dict stp_stringForKey:@"last4"];
    card.threeDSecureUsage = [STPPaymentMethodThreeDSecureUsage decodedObjectFromAPIResponse:[dict stp_dictionaryForKey:@"three_d_secure_usage"]];
    // Ignoring wallet...
    return card;
}

@end
