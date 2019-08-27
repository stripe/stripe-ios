//
//  STPPaymentIntentLastPaymentError.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 8/8/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentIntentLastPaymentError.h"

#import "NSDictionary+Stripe.h"
#import "STPPaymentMethod.h"

NSString *const STPPaymentIntentLastPaymentErrorCodeAuthenticationFailure = @"payment_intent_authentication_failure";

@interface STPPaymentIntentLastPaymentError()
@property (nonatomic, copy) NSString *code;
@property (nonatomic, copy) NSString *declineCode;
@property (nonatomic, copy) NSString *docURL;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *param;
@property (nonatomic) STPPaymentMethod *paymentMethod;
@property (nonatomic) STPPaymentIntentLastPaymentErrorType type;
@property (nonatomic, copy, nonnull, readwrite) NSDictionary *allResponseFields;
@end

@implementation STPPaymentIntentLastPaymentError

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                       
                       // PaymentIntentLastError details (alphabetical)
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

+ (STPPaymentIntentLastPaymentErrorType)typeFromString:(NSString *)string {
    NSDictionary<NSString *, NSNumber *> *map = @{
                                                  @"api_connection_error": @(STPPaymentIntentLastPaymentErrorTypeAPIConnection),
                                                  @"api_error": @(STPPaymentIntentLastPaymentErrorTypeAPI),
                                                  @"authentication_error": @(STPPaymentIntentLastPaymentErrorTypeAuthentication),
                                                  @"card_error": @(STPPaymentIntentLastPaymentErrorTypeCard),
                                                  @"idempotency_error": @(STPPaymentIntentLastPaymentErrorTypeIdempotency),
                                                  @"invalid_request_error": @(STPPaymentIntentLastPaymentErrorTypeInvalidRequest),
                                                  @"rate_limit_error": @(STPPaymentIntentLastPaymentErrorTypeRateLimit),
                                                  };
    
    NSString *key = string.lowercaseString;
    NSNumber *statusNumber = map[key] ?: @(STPPaymentIntentLastPaymentErrorTypeUnknown);
    return statusNumber.integerValue;
}

#pragma mark - STPAPIResponseDecodable

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }
    
    STPPaymentIntentLastPaymentError *lastError = [self new];
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
