//
//  STPPaymentMethodFPX.m
//  Stripe
//
//  Created by David Estes on 7/30/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodFPX.h"

#import "NSDictionary+Stripe.h"

@interface STPPaymentMethodFPX ()

@property (nonatomic, nullable, copy, readwrite) NSString *bankIdentifierCode;
@property (nonatomic, copy, nonnull, readwrite) NSDictionary *allResponseFields;

@end

@implementation STPPaymentMethodFPX

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                       // Properties
                       [NSString stringWithFormat:@"bank: %@", self.bankIdentifierCode],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPAPIResponseDecodable

+ (instancetype)decodedObjectFromAPIResponse:(NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }
    STPPaymentMethodFPX *fpx = [self new];
    fpx.allResponseFields = dict;
    fpx.bankIdentifierCode = [dict stp_stringForKey:@"bank"];
    return fpx;
}

@end

