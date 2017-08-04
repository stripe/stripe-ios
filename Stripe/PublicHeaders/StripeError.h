//
//  StripeError.h
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/4/12.
//
//

#import <Foundation/Foundation.h>

/**
 All Stripe iOS errors will be under this domain.
 */
FOUNDATION_EXPORT NSString * __nonnull const StripeDomain;

#define STP_ERROR_ENUM(_type, _name, _domain) \
typedef enum _name: _type _name; \
enum __attribute__((ns_error_domain(_domain))) _name: _type

#if __has_attribute(ns_error_domain)
STP_ERROR_ENUM(NSInteger, STPErrorCode, StripeDomain)
#else
typedef NS_ENUM(NSInteger, STPErrorCode)
#endif
{
    /**
     Trouble connecting to Stripe.
     */
    STPConnectionError = 40,

    /**
     Your request had invalid parameters.
     */
    STPInvalidRequestError = 50,

    /**
     General-purpose API error.
     */
    STPAPIError = 60,

    /**
     Something was wrong with the given card details.
     */
    STPCardError = 70,

    /** 
     The operation was cancelled.
     */
    STPCancellationError = 80,

    /**
     The ephemeral key could not be decoded. Make sure your backend is sending
     the unmodified JSON of the ephemeral key to your app.
     https://stripe.com/docs/mobile/ios/standard#prepare-your-api
     */
    STPEphemeralKeyDecodingError = 1000,
};

#pragma mark userInfo keys

/**
 A developer-friendly error message that explains what went wrong. You probably
 shouldn't show this to your users, but might want to use it yourself.
 */
FOUNDATION_EXPORT NSString * __nonnull const STPErrorMessageKey;

/**
 What went wrong with your STPCard (e.g., STPInvalidCVC. See below for full list).
 */
FOUNDATION_EXPORT NSString * __nonnull const STPCardErrorCodeKey;

/**
 Which parameter on the STPCard had an error (e.g., "cvc"). Useful for marking up the
 right UI element.
 */
FOUNDATION_EXPORT NSString * __nonnull const STPErrorParameterKey;

/**
 The error code returned by the Stripe API.
 @see https://stripe.com/docs/api#errors-type
 */
FOUNDATION_EXPORT NSString * __nonnull const STPStripeErrorCodeKey;

/**
 The error type returned by the Stripe API.

 @see https://stripe.com/docs/api#errors-code
 */
FOUNDATION_EXPORT NSString * __nonnull const STPStripeErrorTypeKey;

#pragma mark STPCardErrorCodeKeys

/**
 Possible string values you may receive when there was an error tokenzing
 a card. These values will come back in the error `userInfo` dictionary
 under the `STPCardErrorCodeKey` key.
 */
typedef NSString * STPCardErrorCode
#ifdef NS_STRING_ENUM
NS_STRING_ENUM
#endif
;

/**
 The card number is not a valid credit card number.
 */
FOUNDATION_EXPORT STPCardErrorCode __nonnull const STPInvalidNumber;

/**
 The card has an invalid expiration month.
 */
FOUNDATION_EXPORT STPCardErrorCode __nonnull const STPInvalidExpMonth;

/**
 The card has an invalid expiration year.
 */
FOUNDATION_EXPORT STPCardErrorCode __nonnull const STPInvalidExpYear;

/**
 The card has an invalid CVC.
 */
FOUNDATION_EXPORT STPCardErrorCode __nonnull const STPInvalidCVC;

/**
 The card number is incorrect.
 */
FOUNDATION_EXPORT STPCardErrorCode __nonnull const STPIncorrectNumber;

/**
 The card is expired.
 */
FOUNDATION_EXPORT STPCardErrorCode __nonnull const STPExpiredCard;

/**
 The card was declined.
 */
FOUNDATION_EXPORT STPCardErrorCode __nonnull const STPCardDeclined;

/**
 The card has na incorrect CVC.
 */
FOUNDATION_EXPORT STPCardErrorCode __nonnull const STPIncorrectCVC;

/**
 An error occured while processing this card.
 */
FOUNDATION_EXPORT STPCardErrorCode __nonnull const STPProcessingError;


@interface NSError(Stripe)

/**
 Creates an NSError object from a given Stripe API json response.

 @param jsonDictionary The root dictionary from the JSON response.

 @return An NSError object with the error information from the JSON response,
 or nil if there was no error information included in the JSON dictionary.
 */
+ (nullable NSError *)stp_errorFromStripeResponse:(nullable NSDictionary *)jsonDictionary;

@end

/**
 This function should not be called directly.

 It is used by the SDK when it is built as a static library to force the
 compiler to link in category methods regardless of the integrating
 app's compiler flags.
 */
void linkNSErrorCategory(void);

