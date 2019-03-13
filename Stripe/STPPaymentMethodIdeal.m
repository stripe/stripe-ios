//
//  STPPaymentMethodiDEAL.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodiDEAL.h"

#import "NSDictionary+Stripe.h"

@interface STPPaymentMethodiDEAL ()

@property (nonatomic, nullable, copy, readwrite) NSString *bankName;
@property (nonatomic, nullable, copy, readwrite) NSString *bankIdentifierCode;
@property (nonatomic, copy, nonnull, readwrite) NSDictionary *allResponseFields;

@end

@implementation STPPaymentMethodiDEAL

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                       // Properties
                       [NSString stringWithFormat:@"bank: %@", self.bankName],
                       [NSString stringWithFormat:@"bic: %@", self.bankIdentifierCode],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPAPIResponseDecodable

+ (instancetype)decodedObjectFromAPIResponse:(NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }
    STPPaymentMethodiDEAL *ideal = [self new];
    ideal.allResponseFields = dict;
    ideal.bankName = [dict stp_stringForKey:@"bank"];
    ideal.bankIdentifierCode = [dict stp_stringForKey:@"bic"];
    return ideal;
}

@end

