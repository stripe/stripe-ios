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

@property (nonatomic, nullable, copy) NSString *email;
@property (nonatomic, nullable, copy) NSString *name;
@property (nonatomic, nullable) STPPaymentMethodAddress *billingAddress;
@property (nonatomic, nullable) STPPaymentMethodAddress *shippingAddress;
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;

@end

@implementation STPPaymentMethodCardWalletMasterpass

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
