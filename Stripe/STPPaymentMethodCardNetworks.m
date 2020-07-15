//
//  STPPaymentMethodCardNetworks.m
//  Stripe
//
//  Created by Cameron Sabol on 7/15/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodCardNetworks.h"

#import "NSDictionary+Stripe.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPPaymentMethodCardNetworks

@synthesize allResponseFields = _allResponseFields;

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                       // Properties
                       [NSString stringWithFormat:@"available: %@", self.available],
                       [NSString stringWithFormat:@"preferred: %@", self.preferred],
                       ];
    
    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPAPIResponseDecodable

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }
    NSArray<NSString *> *available = [dict stp_arrayForKey:@"available" withObjectType:[NSString class]];
    if (available == nil) {
        return nil;
    }
    
    STPPaymentMethodCardNetworks *networks = [self new];
    networks->_allResponseFields = [dict copy];
    networks->_available = available;
    networks->_preferred = [[dict stp_stringForKey:@"preferred"] copy];
    return networks;
}
                       
@end

NS_ASSUME_NONNULL_END
