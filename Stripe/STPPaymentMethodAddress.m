//
//  STPPaymentMethodAddress.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodAddress.h"

#import "NSDictionary+Stripe.h"
#import "STPAddress.h"

@interface STPPaymentMethodAddress ()

@property (nonatomic, copy, nonnull, readwrite) NSDictionary *allResponseFields;

@end

@implementation STPPaymentMethodAddress

- (instancetype)initWithAddress:(STPAddress *)address {
    self = [super init];
    if (self) {
        _city = [address.city copy];
        _country = [address.country copy];
        _line1 = [address.line1 copy];
        _line2 = [address.line2 copy];
        _postalCode = [address.postalCode copy];
        _state = [address.state copy];
    }
    return self;
}

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                       
                       // Properties
                       [NSString stringWithFormat:@"line1 = %@", self.line1],
                       [NSString stringWithFormat:@"line2 = %@", self.line2],
                       [NSString stringWithFormat:@"city = %@", self.city],
                       [NSString stringWithFormat:@"state = %@", self.state],
                       [NSString stringWithFormat:@"postalCode = %@", self.postalCode],
                       [NSString stringWithFormat:@"country = %@", self.country],
                       ];
    
    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPFormEncodable

@synthesize additionalAPIParameters;

+ (nonnull NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(line1)): @"line1",
             NSStringFromSelector(@selector(line2)): @"line2",
             NSStringFromSelector(@selector(city)): @"city",
             NSStringFromSelector(@selector(country)): @"country",
             NSStringFromSelector(@selector(state)): @"state",
             NSStringFromSelector(@selector(postalCode)): @"postal_code",
             };
}

+ (nullable NSString *)rootObjectName {
    return nil;
}

#pragma mark - STPAPIResponseDecodable

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }
    STPPaymentMethodAddress *address = [self new];
    address.allResponseFields = dict;
    address.city = [dict stp_stringForKey:@"city"];
    address.country = [dict stp_stringForKey:@"country"];
    address.line1 = [dict stp_stringForKey:@"line1"];
    address.line2 = [dict stp_stringForKey:@"line2"];
    address.postalCode = [dict stp_stringForKey:@"postal_code"];
    address.state = [dict stp_stringForKey:@"state"];
    return address;
}

@end
