//
//  STPPaymentMethodIdeal.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodIdeal.h"

#import "NSDictionary+Stripe.h"

@interface STPPaymentMethodIdeal ()

@property (nonatomic, nullable, copy) NSString *bank;
@property (nonatomic, nullable, copy) NSString *bic;
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;

@end

@implementation STPPaymentMethodIdeal

#pragma mark - STPAPIResponseDecodable

+ (instancetype)decodedObjectFromAPIResponse:(NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }
    STPPaymentMethodIdeal *ideal = [self new];
    ideal.allResponseFields = dict;
    ideal.bank = [dict stp_stringForKey:@"bank"];
    ideal.bic = [dict stp_stringForKey:@"bic"];
    return ideal;
}

@end
