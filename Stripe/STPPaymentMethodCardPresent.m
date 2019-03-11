//
//  STPPaymentMethodCardPresent.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/11/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodCardPresent.h"

#import "NSDictionary+Stripe.h"

@interface STPPaymentMethodCardPresent()
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;
@end

@implementation STPPaymentMethodCardPresent

#pragma mark - STPAPIResponseDecodable

+ (instancetype)decodedObjectFromAPIResponse:(NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }
    STPPaymentMethodCardPresent *cardPresent = [self new];
    cardPresent.allResponseFields = dict;
    return cardPresent;
}

@end
