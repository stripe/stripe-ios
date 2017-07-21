//
//  StripeError+Private.m
//  Stripe
//
//  Created by Ben Guo on 6/22/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "StripeError+Private.h"
#import "StripeError.h"

@implementation NSError (StripePrivate)

+ (NSError *)stp_ephemeralKeyDecodingError {
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: [self stp_unexpectedErrorMessage],
                               STPErrorMessageKey: @"Failed to decode the ephemeral key. Make sure your backend is sending the unmodified JSON of the ephemeral key to your app."
                               };
    return [[self alloc] initWithDomain:StripeDomain code:STPEphemeralKeyDecodingError userInfo:userInfo];
}

@end

void linkNSErrorPrivateCategory(void) {}
