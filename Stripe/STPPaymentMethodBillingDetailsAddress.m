//
//  STPPaymentMethodBillingDetailsAddress.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodBillingDetailsAddress.h"

#import "NSDictionary+Stripe.h"

@interface STPPaymentMethodBillingDetailsAddress ()

@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;

@end

@implementation STPPaymentMethodBillingDetailsAddress

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
    STPPaymentMethodBillingDetailsAddress *address = [self new];
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
