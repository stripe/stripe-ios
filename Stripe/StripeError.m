//
//  StripeError.m
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/4/12.
//
//

#import "StripeError.h"

#import "NSDictionary+Stripe.h"
#import "NSError+Stripe.h"
#import "STPFormEncoder.h"

NSString *const StripeDomain = @"com.stripe.lib";
NSString *const STPCardErrorCodeKey = @"com.stripe.lib:CardErrorCodeKey";
NSString *const STPErrorMessageKey = @"com.stripe.lib:ErrorMessageKey";
NSString *const STPErrorParameterKey = @"com.stripe.lib:ErrorParameterKey";
NSString *const STPStripeErrorCodeKey = @"com.stripe.lib:StripeErrorCodeKey";
NSString *const STPStripeErrorTypeKey = @"com.stripe.lib:StripeErrorTypeKey";
NSString *const STPInvalidNumber = @"com.stripe.lib:InvalidNumber";
NSString *const STPInvalidExpMonth = @"com.stripe.lib:InvalidExpiryMonth";
NSString *const STPInvalidExpYear = @"com.stripe.lib:InvalidExpiryYear";
NSString *const STPInvalidCVC = @"com.stripe.lib:InvalidCVC";
NSString *const STPIncorrectNumber = @"com.stripe.lib:IncorrectNumber";
NSString *const STPExpiredCard = @"com.stripe.lib:ExpiredCard";
NSString *const STPCardDeclined = @"com.stripe.lib:CardDeclined";
NSString *const STPProcessingError = @"com.stripe.lib:ProcessingError";
NSString *const STPIncorrectCVC = @"com.stripe.lib:IncorrectCVC";

@implementation NSError (Stripe)

+ (NSError *)stp_errorFromStripeResponse:(NSDictionary *)jsonDictionary {
    NSDictionary *errorDictionary = [jsonDictionary stp_dictionaryForKey:@"error"];
    if (!errorDictionary) {
        return nil;
    }
    NSString *errorType = [errorDictionary stp_stringForKey:@"type"];
    NSString *errorParam = [errorDictionary stp_stringForKey:@"param"];
    NSString *stripeErrorMessage = [errorDictionary stp_stringForKey:@"message"];
    NSString *stripeErrorCode = [errorDictionary stp_stringForKey:@"code"];
    NSInteger code = 0;

    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[STPStripeErrorCodeKey] = stripeErrorCode;
    userInfo[STPStripeErrorTypeKey] = errorType;
    if (errorParam) {
        userInfo[STPErrorParameterKey] = [STPFormEncoder stringByReplacingSnakeCaseWithCamelCase:errorParam];
    }
    if (stripeErrorMessage) {
        userInfo[NSLocalizedDescriptionKey] = stripeErrorMessage;
        userInfo[STPErrorMessageKey] = stripeErrorMessage;
    } else {
        userInfo[NSLocalizedDescriptionKey] = [self stp_unexpectedErrorMessage];
        userInfo[STPErrorMessageKey] = @"Could not interpret the error response that was returned from Stripe.";
    }
    if ([errorType isEqualToString:@"api_error"]) {
        code = STPAPIError;
        userInfo[NSLocalizedDescriptionKey] = [self stp_unexpectedErrorMessage];
    } else {
        if ([errorType isEqualToString:@"invalid_request_error"]) {
            code = STPInvalidRequestError;
        } else if ([errorType isEqualToString:@"card_error"]) {
            code = STPCardError;
        } else {
            code = STPAPIError;
        }
        NSDictionary *codeMap = @{
                                  @"incorrect_number": @{@"code": STPIncorrectNumber, @"message": [self stp_cardErrorInvalidNumberUserMessage]},
                                  @"invalid_number": @{@"code": STPInvalidNumber, @"message": [self stp_cardErrorInvalidNumberUserMessage]},
                                  @"invalid_expiry_month": @{@"code": STPInvalidExpMonth, @"message": [self stp_cardErrorInvalidExpMonthUserMessage]},
                                  @"invalid_expiry_year": @{@"code": STPInvalidExpYear, @"message": [self stp_cardErrorInvalidExpYearUserMessage]},
                                  @"invalid_cvc": @{@"code": STPInvalidCVC, @"message": [self stp_cardInvalidCVCUserMessage]},
                                  @"expired_card": @{@"code": STPExpiredCard, @"message": [self stp_cardErrorExpiredCardUserMessage]},
                                  @"incorrect_cvc": @{@"code": STPIncorrectCVC, @"message": [self stp_cardInvalidCVCUserMessage]},
                                  @"card_declined": @{@"code": STPCardDeclined, @"message": [self stp_cardErrorDeclinedUserMessage]},
                                  @"processing_error": @{@"code": STPProcessingError, @"message": [self stp_cardErrorProcessingErrorUserMessage]},
                                  };
        NSDictionary *codeMapEntry = codeMap[stripeErrorCode];
        NSDictionary *cardErrorCode = codeMapEntry[@"code"];
        NSString *localizedMessage = codeMapEntry[@"message"];
        if (cardErrorCode) {
            userInfo[STPCardErrorCodeKey] = cardErrorCode;
        }
        if (localizedMessage) {
            userInfo[NSLocalizedDescriptionKey] = codeMapEntry[@"message"];
        }
    }

    return [[self alloc] initWithDomain:StripeDomain code:code userInfo:userInfo];
}

@end

void linkNSErrorCategory(void) {}
