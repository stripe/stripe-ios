//
//  NSError+Stripe.m
//  Stripe
//
//  Created by Brian Dorfman on 8/4/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "NSError+Stripe.h"

#import "STPLocalizationUtils.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSError (StripePrivate)

+ (NSError *)stp_genericFailedToParseResponseError {
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: [self stp_unexpectedErrorMessage],
                               STPErrorMessageKey: @"The response from Stripe failed to get parsed into valid JSON."
                               };
    return [[self alloc] initWithDomain:StripeDomain code:STPAPIError userInfo:userInfo];
}

+ (NSError *)stp_genericConnectionError {
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: [self stp_unexpectedErrorMessage],
                               STPErrorMessageKey: @"There was an error connecting to Stripe."
                               };
    return [[self alloc] initWithDomain:StripeDomain code:STPConnectionError userInfo:userInfo];
}

+ (NSError *)stp_ephemeralKeyDecodingError {
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: [self stp_unexpectedErrorMessage],
                               STPErrorMessageKey: @"Failed to decode the ephemeral key. Make sure your backend is sending the unmodified JSON of the ephemeral key to your app."
                               };
    return [[self alloc] initWithDomain:StripeDomain code:STPEphemeralKeyDecodingError userInfo:userInfo];
}


#pragma mark Strings

+ (NSString *)stp_cardErrorInvalidNumberUserMessage {
    return STPLocalizedString(@"Your card's number is invalid", @"Error when the card number is not valid");
}

+ (NSString *)stp_cardInvalidCVCUserMessage {
    return STPLocalizedString(@"Your card's security code is invalid", @"Error when the card's CVC is not valid");
}

+ (NSString *)stp_cardErrorInvalidExpMonthUserMessage {
    return STPLocalizedString(@"Your card's expiration month is invalid", @"Error when the card's expiration month is not valid");
}

+ (NSString *)stp_cardErrorInvalidExpYearUserMessage {
    return STPLocalizedString(@"Your card's expiration year is invalid", @"Error when the card's expiration year is not valid");
}

+ (NSString *)stp_cardErrorExpiredCardUserMessage {
    return STPLocalizedString(@"Your card has expired", @"Error when the card has already expired");
}

+ (NSString *)stp_cardErrorDeclinedUserMessage {
    return STPLocalizedString(@"Your card was declined", @"Error when the card was declined by the credit card networks");
}

+ (NSString *)stp_unexpectedErrorMessage {
    return STPLocalizedString(@"There was an unexpected error -- try again in a few seconds", @"Unexpected error, such as a 500 from Stripe or a JSON parse error");
}

+ (NSString *)stp_cardErrorProcessingErrorUserMessage {
    return STPLocalizedString(@"There was an error processing your card -- try again in a few seconds", @"Error when there is a problem processing the credit card");
}

@end


void linkNSErrorPrivateCategory(void) {}

NS_ASSUME_NONNULL_END
