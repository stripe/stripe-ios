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

- (nullable instancetype)_initWithDictionary:(nullable NSDictionary *)dict {
    dict = [dict stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }
    NSArray<NSString *> *available = [dict stp_arrayForKey:@"available" withObjectType:[NSString class]];
    if (available == nil) {
        return nil;
    }
        
    self = [super init];
    if (self) {
        self->_allResponseFields = [dict copy];
        self->_available = available;
        self->_preferred = [[dict stp_stringForKey:@"preferred"] copy];
    }
    
    return self;
}

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    return [[self alloc] _initWithDictionary:response];
}
                       
@end

NS_ASSUME_NONNULL_END
