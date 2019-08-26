//
//  STPSetupIntentLastSetupError.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 8/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPSetupIntentLastSetupError.h"

#import "NSDictionary+Stripe.h"
#import "STPPaymentMethod.h"

NSString *const STPSetupIntentLastSetupErrorCodeAuthenticationFailure = @"setup_intent_authentication_failure";

@interface STPSetupIntentLastSetupError()
@property (nonatomic, copy) NSString *code;
@property (nonatomic, copy) NSString *declineCode;
@property (nonatomic, copy) NSString *docURL;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *param;
@property (nonatomic) STPPaymentMethod *paymentMethod;
@property (nonatomic) STPSetupIntentLastSetupErrorType type;
@property (nonatomic, copy, nonnull, readwrite) NSDictionary *allResponseFields;
@end

@implementation STPSetupIntentLastSetupError
- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                       
                       // SetupIntentLastError details (alphabetical)
                       [NSString stringWithFormat:@"code = %@", self.code],
                       [NSString stringWithFormat:@"declineCode = %@", self.declineCode],
                       [NSString stringWithFormat:@"docURL = %@", self.docURL],
                       [NSString stringWithFormat:@"message = %@", self.message],
                       [NSString stringWithFormat:@"param = %@", self.param],
                       [NSString stringWithFormat:@"paymentMethod = %@", self.paymentMethod],
                       [NSString stringWithFormat:@"type = %@", self.allResponseFields[@"type"]],
                       ];
    
    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

+ (STPSetupIntentLastSetupErrorType)typeFromString:(NSString *)string {
    NSDictionary<NSString *, NSNumber *> *map = @{
                                                  @"api_connection_error": @(STPSetupIntentLastSetupErrorTypeAPIConnection),
                                                  @"api_error": @(STPSetupIntentLastSetupErrorTypeAPI),
                                                  @"authentication_error": @(STPSetupIntentLastSetupErrorTypeAuthentication),
                                                  @"card_error": @(STPSetupIntentLastSetupErrorTypeCard),
                                                  @"idempotency_error": @(STPSetupIntentLastSetupErrorTypeIdempotency),
                                                  @"invalid_request_error": @(STPSetupIntentLastSetupErrorTypeInvalidRequest),
                                                  @"rate_limit_error": @(STPSetupIntentLastSetupErrorTypeRateLimit),
                                                  };
    
    NSString *key = string.lowercaseString;
    NSNumber *statusNumber = map[key] ?: @(STPSetupIntentLastSetupErrorTypeUnknown);
    return statusNumber.integerValue;
}

#pragma mark - STPAPIResponseDecodable

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }
    
    STPSetupIntentLastSetupError *lastError = [self new];
    lastError.code = [dict stp_stringForKey:@"code"];
    lastError.declineCode = [dict stp_stringForKey:@"decline_code"];
    lastError.docURL = [dict stp_stringForKey:@"doc_url"];
    lastError.message = [dict stp_stringForKey:@"message"];
    lastError.param = [dict stp_stringForKey:@"param"];
    lastError.paymentMethod = [STPPaymentMethod decodedObjectFromAPIResponse:[dict stp_dictionaryForKey:@"payment_method"]];
    lastError.type = [self typeFromString:[dict stp_stringForKey:@"type"]];
    lastError.allResponseFields = dict;
    
    return lastError;
}

@end
