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

@property (nonatomic) STPPaymentMethodCardCheckResult addressLine1Check;
@property (nonatomic) STPPaymentMethodCardCheckResult addressPostalCodeCheck;
@property (nonatomic) STPPaymentMethodCardCheckResult cvcCheck;
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;

@end

@implementation STPPaymentMethodCardChecks

+ (STPPaymentMethodCardCheckResult)checkResultFromString:(nullable NSString *)string {
    NSString *check = [string lowercaseString];
    if ([check isEqualToString:@"pass"]) {
        return STPPaymentMethodCardCheckResultPass;
    } else if ([check isEqualToString:@"failed"]) {
        return STPPaymentMethodCardCheckResultFailed;
    } else if ([check isEqualToString:@"unavailable"]) {
        return STPPaymentMethodCardCheckResultUnavailable;
    } else if ([check isEqualToString:@"unchecked"]) {
        return STPPaymentMethodCardCheckResultUnchecked;
    } else {
        return STPPaymentMethodCardCheckResultUnknown;
    }
}

#pragma mark - STPAPIResponseDecodable

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }
    NSString *addressLine1CheckRawString = [dict stp_stringForKey:@"address_line1_check"];
    NSString *addressPostalCodeCheckRawString = [dict stp_stringForKey:@"address_postal_code_check"];
    NSString *cvcCheckRawString = [dict stp_stringForKey:@"cvc_check"];
    STPPaymentMethodCardChecks *cardChecks = [self new];
    cardChecks.allResponseFields = dict;
    cardChecks.addressLine1Check = [[self class] checkResultFromString:addressLine1CheckRawString];
    cardChecks.addressPostalCodeCheck = [[self class] checkResultFromString:addressPostalCodeCheckRawString];
    cardChecks.cvcCheck = [[self class] checkResultFromString:cvcCheckRawString];
    return cardChecks;
}

@end
