//
//  STPPaymentMethodCardWalletVisaCheckout.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodCardWalletVisaCheckout.h"

#import "STPPaymentMethodAddress.h"

#import "NSDictionary+Stripe.h"

@interface STPPaymentMethodCardWalletVisaCheckout()

@property (nonatomic, copy, nullable, readwrite) NSString *email;
@property (nonatomic, copy, nullable, readwrite) NSString *name;
@property (nonatomic, strong, nullable, readwrite) STPPaymentMethodAddress *billingAddress;
@property (nonatomic, strong, nullable) STPPaymentMethodAddress *shippingAddress;
@property (nonatomic, copy, nonnull, readwrite) NSDictionary *allResponseFields;

@end

@implementation STPPaymentMethodCardWalletVisaCheckout

#pragma mark - STPAPIResponseDecodable

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }
    STPPaymentMethodCardWalletVisaCheckout *visaCheckout = [self new];
    visaCheckout.allResponseFields = dict;
    visaCheckout.billingAddress = [STPPaymentMethodAddress decodedObjectFromAPIResponse:[response stp_dictionaryForKey:@"billing_address"]];
    visaCheckout.shippingAddress = [STPPaymentMethodAddress decodedObjectFromAPIResponse:[response stp_dictionaryForKey:@"shipping_address"]];
    visaCheckout.email = [dict stp_stringForKey:@"email"];
    visaCheckout.name = [dict stp_stringForKey:@"name"];
    return visaCheckout;
}

@end
