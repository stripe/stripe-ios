//
//  StripeError.h
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/4/12.
//
//

#import <Foundation/Foundation.h>

/**
 *  All Stripe iOS errors will be under this domain.
 */
FOUNDATION_EXPORT NSString * __nonnull const StripeDomain;

#define STP_ERROR_ENUM(_type, _name, _domain) \
typedef enum _name: _type _name; \
enum __attribute__((ns_error_domain(_domain))) _name: _type

#if __has_attribute(ns_error_domain)
STP_ERROR_ENUM(NSInteger, STPErrorCode, StripeDomain) {
#else
typedef NS_ENUM(NSInteger, STPErrorCode) {
#endif
    // Trouble connecting to Stripe.
    STPConnectionError = 40,
    // Your request had invalid parameters.
    STPInvalidRequestError = 50,
    // General-purpose API error.
    STPAPIError = 60,
    // Something was wrong with the given card details.
    STPCardError = 70,
    // The operation was cancelled.
    STPCancellationError = 80,
    /**
     The ephemeral key could not be decoded. Make sure your backend is sending
     the unmodified JSON of the ephemeral key to your app.
     https://stripe.com/docs/mobile/ios/standard#prepare-your-api
     */
    STPEphemeralKeyDecodingError = 1000,
};

#pragma mark userInfo keys

// A developer-friendly error message that explains what went wrong. You probably
// shouldn't show this to your users, but might want to use it yourself.
FOUNDATION_EXPORT NSString * __nonnull const STPErrorMessageKey;

// What went wrong with your STPCard (e.g., STPInvalidCVC. See below for full list).
FOUNDATION_EXPORT NSString * __nonnull const STPCardErrorCodeKey;

// Which parameter on the STPCard had an error (e.g., "cvc"). Useful for marking up the
// right UI element.
FOUNDATION_EXPORT NSString * __nonnull const STPErrorParameterKey;

// The error code returned by the Stripe API.
// https://stripe.com/docs/api#errors-type
FOUNDATION_EXPORT NSString * __nonnull const STPStripeErrorCodeKey;

// The error type returned by the Stripe API.
// https://stripe.com/docs/api#errors-code
FOUNDATION_EXPORT NSString * __nonnull const STPStripeErrorTypeKey;

#pragma mark STPCardErrorCodeKeys

typedef NSString * STPCardErrorCode
#ifdef NS_STRING_ENUM
NS_STRING_ENUM
#endif
;

// (Usually determined locally:)
FOUNDATION_EXPORT STPCardErrorCode __nonnull const STPInvalidNumber;
FOUNDATION_EXPORT STPCardErrorCode __nonnull const STPInvalidExpMonth;
FOUNDATION_EXPORT STPCardErrorCode __nonnull const STPInvalidExpYear;
FOUNDATION_EXPORT STPCardErrorCode __nonnull const STPInvalidCVC;

// (Usually sent from the server:)
FOUNDATION_EXPORT STPCardErrorCode __nonnull const STPIncorrectNumber;
FOUNDATION_EXPORT STPCardErrorCode __nonnull const STPExpiredCard;
FOUNDATION_EXPORT STPCardErrorCode __nonnull const STPCardDeclined;
FOUNDATION_EXPORT STPCardErrorCode __nonnull const STPProcessingError;
FOUNDATION_EXPORT STPCardErrorCode __nonnull const STPIncorrectCVC;


@interface NSError(Stripe)

+ (nullable NSError *)stp_errorFromStripeResponse:(nullable NSDictionary *)jsonDictionary;
+ (nonnull NSError *)stp_genericConnectionError;
+ (nonnull NSError *)stp_genericFailedToParseResponseError;

#pragma mark Strings

+ (nonnull NSString *)stp_cardErrorInvalidNumberUserMessage;
+ (nonnull NSString *)stp_cardInvalidCVCUserMessage;
+ (nonnull NSString *)stp_cardErrorInvalidExpMonthUserMessage;
+ (nonnull NSString *)stp_cardErrorInvalidExpYearUserMessage;
+ (nonnull NSString *)stp_cardErrorExpiredCardUserMessage;
+ (nonnull NSString *)stp_cardErrorDeclinedUserMessage;
+ (nonnull NSString *)stp_cardErrorProcessingErrorUserMessage;
+ (nonnull NSString *)stp_unexpectedErrorMessage;

@end

void linkNSErrorCategory(void);

