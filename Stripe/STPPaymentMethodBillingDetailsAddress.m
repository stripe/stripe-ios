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

@property (nonatomic, nullable) NSString *city;
@property (nonatomic, nullable) NSString *country;
@property (nonatomic, nullable) NSString *line1;
@property (nonatomic, nullable) NSString *line2;
@property (nonatomic, nullable) NSString *postalCode;
@property (nonatomic, nullable) NSString *state;
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;

@end


@implementation STPPaymentMethodBillingDetailsAddress

#pragma mark - STPAPIResponseDecodable

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }
    STPPaymentMethodBillingDetailsAddress *address = [STPPaymentMethodBillingDetailsAddress new];
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
