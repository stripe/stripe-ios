//
//  NSError+Stripe.h
//  Stripe
//
//  Created by Brian Dorfman on 8/4/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "StripeError.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSError(StripePrivate)

+ (NSError *)stp_genericConnectionError;
+ (NSError *)stp_genericFailedToParseResponseError;
+ (NSError *)stp_ephemeralKeyDecodingError;

#pragma mark Strings

+ (NSString *)stp_cardErrorInvalidNumberUserMessage;
+ (NSString *)stp_cardInvalidCVCUserMessage;
+ (NSString *)stp_cardErrorInvalidExpMonthUserMessage;
+ (NSString *)stp_cardErrorInvalidExpYearUserMessage;
+ (NSString *)stp_cardErrorExpiredCardUserMessage;
+ (NSString *)stp_cardErrorDeclinedUserMessage;
+ (NSString *)stp_cardErrorProcessingErrorUserMessage;
+ (NSString *)stp_unexpectedErrorMessage;

@end

NS_ASSUME_NONNULL_END

void linkNSErrorPrivateCategory(void);
