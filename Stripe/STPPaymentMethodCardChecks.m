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

@property (nonatomic, readwrite) STPPaymentMethodCardCheckResult addressLine1Check;
@property (nonatomic, readwrite) STPPaymentMethodCardCheckResult addressPostalCodeCheck;
@property (nonatomic, readwrite) STPPaymentMethodCardCheckResult cvcCheck;
@property (nonatomic, copy, nonnull, readwrite) NSDictionary *allResponseFields;

@end

@implementation STPPaymentMethodCardChecks

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                       // Properties
                       [NSString stringWithFormat:@"addressLine1Check: %@", [self.allResponseFields stp_stringForKey:@"address_line1_check"]],
                       [NSString stringWithFormat:@"addressPostalCodeCheck: %@", [self.allResponseFields stp_stringForKey:@"address_postal_code_check"]],
                       [NSString stringWithFormat:@"cvcCheck: %@", [self.allResponseFields stp_stringForKey:@"cvc_check"]],
                       ];
    
    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

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
