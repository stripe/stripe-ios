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
@property (nonatomic, copy, nonnull, readwrite) NSDictionary *allResponseFields;
@end

@implementation STPPaymentMethodCardPresent

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                       ];
    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

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
