//
//  STPPaymentMethodCardWalletMasterpass.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodCardWalletMasterpass.h"

#import "STPPaymentMethodAddress.h"

#import "NSDictionary+Stripe.h"

@interface STPPaymentMethodCardWalletMasterpass()

@property (nonatomic, copy, nullable, readwrite) NSString *email;
@property (nonatomic, copy, nullable, readwrite) NSString *name;
@property (nonatomic, strong, nullable, readwrite) STPPaymentMethodAddress *billingAddress;
@property (nonatomic, strong, nullable, readwrite) STPPaymentMethodAddress *shippingAddress;
@property (nonatomic, copy, nonnull, readwrite) NSDictionary *allResponseFields;

@end

@implementation STPPaymentMethodCardWalletMasterpass

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                       
                       // Properties
                       [NSString stringWithFormat:@"email: %@", self.email],
                       [NSString stringWithFormat:@"name: %@", self.name],
                       [NSString stringWithFormat:@"billingAddress: %@", self.billingAddress],
                       [NSString stringWithFormat:@"shippingAddress: %@", self.shippingAddress],
                       ];
    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPAPIResponseDecodable

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }
    STPPaymentMethodCardWalletMasterpass *masterpass = [self new];
    masterpass.allResponseFields = dict;
    masterpass.billingAddress = [STPPaymentMethodAddress decodedObjectFromAPIResponse:[response stp_dictionaryForKey:@"billing_address"]];
    masterpass.shippingAddress = [STPPaymentMethodAddress decodedObjectFromAPIResponse:[response stp_dictionaryForKey:@"shipping_address"]];
    masterpass.email = [dict stp_stringForKey:@"email"];
    masterpass.name = [dict stp_stringForKey:@"name"];
    return masterpass;
}

@end
