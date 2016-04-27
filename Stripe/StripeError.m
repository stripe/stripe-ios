//
//  StripeError.m
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/4/12.
//
//

#import "StripeError.h"
#import "STPFormEncoder.h"

NSString *const StripeDomain = @"com.stripe.lib";
NSString *const STPCardErrorCodeKey = @"com.stripe.lib:CardErrorCodeKey";
NSString *const STPErrorMessageKey = @"com.stripe.lib:ErrorMessageKey";
NSString *const STPErrorParameterKey = @"com.stripe.lib:ErrorParameterKey";
NSString *const STPInvalidNumber = @"com.stripe.lib:InvalidNumber";
NSString *const STPInvalidExpMonth = @"com.stripe.lib:InvalidExpiryMonth";
NSString *const STPInvalidExpYear = @"com.stripe.lib:InvalidExpiryYear";
NSString *const STPInvalidCVC = @"com.stripe.lib:InvalidCVC";
NSString *const STPIncorrectNumber = @"com.stripe.lib:IncorrectNumber";
NSString *const STPExpiredCard = @"com.stripe.lib:ExpiredCard";
NSString *const STPCardDeclined = @"com.stripe.lib:CardDeclined";
NSString *const STPProcessingError = @"com.stripe.lib:ProcessingError";
NSString *const STPIncorrectCVC = @"com.stripe.lib:IncorrectCVC";

@implementation NSError(Stripe)

+ (NSError *)stp_errorFromStripeResponse:(NSDictionary *)jsonDictionary {
    NSDictionary *errorDictionary = jsonDictionary[@"error"];
    if (!errorDictionary) {
        return nil;
    }
    NSString *type = errorDictionary[@"type"];
    NSString *devMessage = errorDictionary[@"message"];
    NSString *parameter = errorDictionary[@"param"];
    NSInteger code = 0;
    
    // There should always be a message and type for the error
    if (devMessage == nil || type == nil) {
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey: STPUnexpectedError,
                                   STPErrorMessageKey: @"Could not interpret the error response that was returned from Stripe."
                                   };
        return [[NSError alloc] initWithDomain:StripeDomain code:STPAPIError userInfo:userInfo];
    }
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[STPErrorMessageKey] = devMessage;
    
    if (parameter) {
        userInfo[STPErrorParameterKey] = [STPFormEncoder stringByReplacingSnakeCaseWithCamelCase:parameter];
    }
    
    if ([type isEqualToString:@"api_error"]) {
        code = STPAPIError;
        userInfo[NSLocalizedDescriptionKey] = STPUnexpectedError;
    } else if ([type isEqualToString:@"invalid_request_error"]) {
        code = STPInvalidRequestError;
        userInfo[NSLocalizedDescriptionKey] = devMessage;
    } else if ([type isEqualToString:@"card_error"]) {
        code = STPCardError;
        NSDictionary *errorCodes = @{
                                     @"incorrect_number": @{@"code": STPIncorrectNumber, @"message": STPCardErrorInvalidNumberUserMessage},
                                     @"invalid_number": @{@"code": STPInvalidNumber, @"message": STPCardErrorInvalidNumberUserMessage},
                                     @"invalid_expiry_month": @{@"code": STPInvalidExpMonth, @"message": STPCardErrorInvalidExpMonthUserMessage},
                                     @"invalid_expiry_year": @{@"code": STPInvalidExpYear, @"message": STPCardErrorInvalidExpYearUserMessage},
                                     @"invalid_cvc": @{@"code": STPInvalidCVC, @"message": STPCardErrorInvalidCVCUserMessage},
                                     @"expired_card": @{@"code": STPExpiredCard, @"message": STPCardErrorExpiredCardUserMessage},
                                     @"incorrect_cvc": @{@"code": STPIncorrectCVC, @"message": STPCardErrorInvalidCVCUserMessage},
                                     @"card_declined": @{@"code": STPCardDeclined, @"message": STPCardErrorDeclinedUserMessage},
                                     @"processing_error": @{@"code": STPProcessingError, @"message": STPCardErrorProcessingErrorUserMessage},
                                     };
        NSDictionary *codeMapEntry = errorCodes[errorDictionary[@"code"]];
        
        if (codeMapEntry) {
            userInfo[STPCardErrorCodeKey] = codeMapEntry[@"code"];
            userInfo[NSLocalizedDescriptionKey] = codeMapEntry[@"message"];
        } else {
            userInfo[STPCardErrorCodeKey] = errorDictionary[@"code"];
            userInfo[NSLocalizedDescriptionKey] = devMessage;
        }
    }
    
    return [[NSError alloc] initWithDomain:StripeDomain code:code userInfo:userInfo];
}

+ (nonnull NSError *)stp_genericFailedToParseResponseError {
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: STPUnexpectedError,
                               STPErrorMessageKey: @"The response from Stripe failed to get parsed into valid JSON."
                               };
    return [[NSError alloc] initWithDomain:StripeDomain code:STPAPIError userInfo:userInfo];
}

@end
