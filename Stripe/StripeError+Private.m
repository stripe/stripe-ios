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

+ (NSError *)stp_customerContextMissingKeyProviderError {
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: [self stp_unexpectedErrorMessage],
                               STPErrorMessageKey: @"STPCustomerContext is missing a key provider. Did you forget to set the singleton instance's key provider?"
                               };
    return [[self alloc] initWithDomain:StripeDomain code:STPCustomerContextMissingKeyProviderError userInfo:userInfo];
}

@end

void linkNSErrorPrivateCategory(void) {}
