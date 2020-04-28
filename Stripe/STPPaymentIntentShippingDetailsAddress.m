//
//  STPPaymentIntentShippingDetailsAddress.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 4/27/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPPaymentIntentShippingDetailsAddress.h"

#import "NSDictionary+Stripe.h"

@interface STPPaymentIntentShippingDetailsAddress ()
@property (nonatomic, copy, nonnull, readwrite) NSDictionary *allResponseFields;

@property (nonatomic, copy, nullable) NSString *city;
@property (nonatomic, copy, nullable) NSString *country;
@property (nonatomic, copy, nullable) NSString *line1;
@property (nonatomic, copy, nullable) NSString *line2;
@property (nonatomic, copy, nullable) NSString *postalCode;
@property (nonatomic, copy, nullable) NSString *state;
@end

@implementation STPPaymentIntentShippingDetailsAddress

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

#pragma mark - STPAPIResponseDecodable

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }
    STPPaymentIntentShippingDetailsAddress *address = [self new];
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
