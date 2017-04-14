//
//  NSError+STPPaymentContext.m
//  Stripe
//
//  Created by Brian Dorfman on 4/13/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "NSError+STPPaymentContext.h"

@implementation NSError (STPPaymentContext)

+ (NSError *)stp_paymentContextUnknownError {
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: [self stp_unexpectedErrorMessage],
                               STPErrorMessageKey: @"There was an error using payment context."
                               };
    return [[self alloc] initWithDomain:StripeDomain code:STPPaymentContextUnknownError userInfo:userInfo];
}

+ (NSError *)stp_paymentContextUnsupportedPaymentMethodError {
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: [self stp_unexpectedErrorMessage],
                               STPErrorMessageKey: @"Attempt to pay using STPPaymentContext with an unsupported payment method failed."
                               };
    return [[self alloc] initWithDomain:StripeDomain code:STPPaymentContextUnsupportedPaymentMethodError userInfo:userInfo];
}

+ (NSError *)stp_paymentContextInvalidSourceStatusErrorWithStatus:(STPSourceStatus)status {
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: [self stp_unexpectedErrorMessage],
                               STPErrorMessageKey: @"Failed to complete charge because source was in an invalid state.",
                               STPSourceStatusErrorKey: @(status)
                               };
    return [[self alloc] initWithDomain:StripeDomain code:STPPaymentContextInvalidSourceStatusError userInfo:userInfo];
}

@end
