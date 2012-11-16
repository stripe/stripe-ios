//
//  StripeError.h
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/4/12.
//
//

#import <Foundation/Foundation.h>

// The domain of all NSErrors returned by the Stripe iOS library
FOUNDATION_EXPORT NSString * const StripeDomain;

/*
 These NSError codes match up to the errors listed in the Stripe API docs:
 https://stripe.com/docs/api?lang=curl#errors .  In addition to being returned
 by our REST API, certain parts of the iOS bindings can return errors with these
 codes.
*/
typedef enum STPErrorCode {
    STPInvalidRequestError = 50,
    STPAPIError = 60,
    STPCardError = 70
} STPErrorCode;



/*
 The parameter that an NSError is for.  Corresponds to the "param" property
 returned in errors from the Stripe API.  These match up to the properties on
 STPCard.
 */
FOUNDATION_EXPORT NSString * const STPErrorParameterKey;

/*
 Stripe API error messages are intended to be developer-facing, not customer-
 facing, so this key holds the message.  Corresponds to the "message" property
 returned in errors from the Stripe API.
 */
FOUNDATION_EXPORT NSString * const STPErrorMessageKey;

/*
 NSErrors that have a code of STPCardError will have an STPCardErrorCodeKey
 in the userInfo dictionary.  This gives more information about the card error.
 */
FOUNDATION_EXPORT NSString * const STPCardErrorCodeKey;



/*
 These are possible values for the STPCardErrorCodeKey in the userInfo dictionary
 of an NSError returned by this library
 */

/*
 These four values may be returned for STPCardErrorCodeKey by the client-side
 validations done in STPCard as well as by the call to createTokenWithCard
 */
FOUNDATION_EXPORT NSString * const STPInvalidNumber;
FOUNDATION_EXPORT NSString * const STPInvalidExpMonth;
FOUNDATION_EXPORT NSString * const STPInvalidExpYear;
FOUNDATION_EXPORT NSString * const STPInvalidCVC;

/*
 These values may be returned for STPCardErrorCodeKey from the call to
 createTokenWithCard
 */
FOUNDATION_EXPORT NSString * const STPIncorrectNumber;
FOUNDATION_EXPORT NSString * const STPExpiredCard;
FOUNDATION_EXPORT NSString * const STPCardDeclined;
FOUNDATION_EXPORT NSString * const STPProcessingError;
FOUNDATION_EXPORT NSString * const STPIncorrectCVC;



/*
 These define user-facing, localizable error messages in all NSErrors returned
 by this library. We use macros instead of string constants so that you can use
 genstrings to generate your Localizable.strings file
 */
#define STPCardErrorInvalidNumberUserMessage NSLocalizedString(@"Your card's number is invalid", @"Error when the card number is not valid")
#define STPCardErrorInvalidCVCUserMessage NSLocalizedString(@"Your card's security code is invalid", @"Error when the card's CVC is not valid")
#define STPCardErrorInvalidExpMonthUserMessage NSLocalizedString(@"Your card's expiration month is invalid", @"Error when the card's expiration month is not valid")
#define STPCardErrorInvalidExpYearUserMessage NSLocalizedString(@"Your card's expiration year is invalid", @"Error when the card's expiration year is not valid")
#define STPCardErrorExpiredCardUserMessage NSLocalizedString(@"Your card has expired", @"Error when the card has already expired")
#define STPCardErrorDeclinedUserMessage NSLocalizedString(@"Your card was declined", @"Error when the card was declined by the credit card networks")
#define STPUnexpectedError NSLocalizedString(@"There was an unexpected error -- try again in a few seconds", @"Unexpected error, such as a 500 from Stripe or a JSON parse error")
#define STPCardErrorProcessingErrorUserMessage NSLocalizedString(@"There was an error processing your card -- try again in a few seconds", @"Error when there is a problem processing the credit card")