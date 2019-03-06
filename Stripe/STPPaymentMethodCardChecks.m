//
//  STPPaymentMethodCardChecks.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodCardChecks.h"

#import "NSDictionary+Stripe.h"

@interface STPPaymentMethodCardChecks ()

@property (nonatomic, nullable) NSString *addressLine1Check;
@property (nonatomic, nullable) NSString *addressPostalCodeCheck;
@property (nonatomic, nullable) NSString *cvcCheck;
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;

@end

@implementation STPPaymentMethodCardChecks

#pragma mark - STPAPIResponseDecodable

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }
    STPPaymentMethodCardChecks *cardChecks = [self new];
    cardChecks.allResponseFields = dict;
    cardChecks.addressLine1Check = [dict stp_stringForKey:@"address_line1_check"];
    cardChecks.addressPostalCodeCheck = [dict stp_stringForKey:@"address_postal_code_check"];
    cardChecks.cvcCheck = [dict stp_stringForKey:@"cvc_check"];
    return cardChecks;
}

@end
