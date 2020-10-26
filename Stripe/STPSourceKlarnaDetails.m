//
//  STPSourceKlarnaDetails.m
//  Stripe
//
//  Created by David Estes on 11/19/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPSourceKlarnaDetails.h"

#import "NSDictionary+Stripe.h"

@interface STPSourceKlarnaDetails()
@property (nonatomic, copy, readwrite) NSString *clientToken;
@property (nonatomic, copy, readwrite) NSString *purchaseCountry;
@property (nonatomic, copy, readwrite) NSDictionary *allResponseFields;
@end

@implementation STPSourceKlarnaDetails


#pragma mark - Description

- (NSString *)description {
    NSArray *props = @[
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                       [NSString stringWithFormat:@"clientToken = %@", self.clientToken],
                       [NSString stringWithFormat:@"purchaseCountry = %@", self.purchaseCountry],
                       ];
    
    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPAPIResponseDecodable

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }
    STPSourceKlarnaDetails *details = [[self class] new];
    details.clientToken = [dict stp_stringForKey:@"client_token"];
    details.purchaseCountry = [dict stp_stringForKey:@"purchase_country"];
    details.allResponseFields = dict;
    return details;
}

@end
