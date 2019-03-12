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

@property (nonatomic, nullable, copy, readwrite) NSString *bank;
@property (nonatomic, nullable, copy, readwrite) NSString *bic;
@property (nonatomic, copy, nonnull, readwrite) NSDictionary *allResponseFields;

@end

@implementation STPPaymentMethodIdeal

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                       
                       // Properties
                       [NSString stringWithFormat:@"bank: %@", self.bank],
                       [NSString stringWithFormat:@"bic: %@", self.bic],
                       ];
    
    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

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
