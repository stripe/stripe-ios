//
//  STPPaymentIntent.m
//  Stripe
//
//  Created by Daniel Jackson on 6/27/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import "STPPaymentIntent.h"
#import "STPPaymentIntent+Private.h"

#import "NSDictionary+Stripe.h"

@interface STPPaymentIntent ()
@property (nonatomic, copy, readwrite) NSString *stripeId;
@property (nonatomic, copy, readwrite) NSString *clientSecret;
@property (nonatomic, copy, readwrite) NSNumber *amount;
@property (nonatomic, strong, nullable, readwrite) NSDate *canceledAt;
@property (nonatomic, assign, readwrite) STPPaymentIntentCaptureMethod captureMethod;
@property (nonatomic, assign, readwrite) STPPaymentIntentConfirmationMethod confirmationMethod;
@property (nonatomic, strong, nullable, readwrite) NSDate *created;
@property (nonatomic, copy, readwrite) NSString *currency;
@property (nonatomic, copy, nullable, readwrite) NSString *stripeDescription;
@property (nonatomic, assign, readwrite) BOOL livemode;
@property (nonatomic, copy, nullable, readwrite) NSString *receiptEmail;
@property (nonatomic, copy, nullable, readwrite) NSURL *returnUrl;
@property (nonatomic, copy, nullable, readwrite) NSString *sourceId;
@property (nonatomic, assign, readwrite) STPPaymentIntentStatus status;

@property (nonatomic, copy, nonnull, readwrite) NSDictionary *allResponseFields;
@end

@implementation STPPaymentIntent

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                       // Identifier
                       [NSString stringWithFormat:@"stripeId = %@", self.stripeId],

                       // PaymentIntent details (alphabetical)
                       [NSString stringWithFormat:@"amount = %@", self.amount],
                       [NSString stringWithFormat:@"canceledAt = %@", self.canceledAt],
                       [NSString stringWithFormat:@"captureMethod = %@", [self.allResponseFields stp_stringForKey:@"capture_method"]],
                       [NSString stringWithFormat:@"clientSecret = %@", (self.clientSecret) ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"confirmationMethod = %@", [self.allResponseFields stp_stringForKey:@"confirmation_method"]],
                       [NSString stringWithFormat:@"created = %@", self.created],
                       [NSString stringWithFormat:@"currency = %@", self.currency],
                       [NSString stringWithFormat:@"description = %@", self.stripeDescription],
                       [NSString stringWithFormat:@"livemode = %@", self.livemode ? @"YES" : @"NO"],
                       [NSString stringWithFormat:@"nextSourceAction = %@", self.allResponseFields[@"next_source_action"]],
                       [NSString stringWithFormat:@"receiptEmail = %@", self.receiptEmail],
                       [NSString stringWithFormat:@"returnUrl = %@", self.returnUrl],
                       [NSString stringWithFormat:@"shipping = %@", self.allResponseFields[@"shipping"]],
                       [NSString stringWithFormat:@"sourceId = %@", self.sourceId],
                       [NSString stringWithFormat:@"status = %@", [self.allResponseFields stp_stringForKey:@"status"]],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPPaymentIntent+Private.h

+ (nullable NSString *)idFromClientSecret:(NSString *)clientSecret {
    // see parseClientSecret from stripe-js-v3
    NSArray *components = [clientSecret componentsSeparatedByString:@"_secret_"];
    if (components.count >= 2 && [components[0] hasPrefix:@"pi_"]) {
        return components[0];
    }
    else {
        return nil;
    }
}

#pragma mark - STPPaymentIntentEnum support

+ (STPPaymentIntentStatus)statusFromString:(NSString *)string {
    NSDictionary<NSString *, NSNumber *> *map = @{
                                                  @"requires_source": @(STPPaymentIntentStatusRequiresSource),
                                                  @"requires_confirmation": @(STPPaymentIntentStatusRequiresConfirmation),
                                                  @"requires_source_action": @(STPPaymentIntentStatusRequiresSourceAction),
                                                  @"processing": @(STPPaymentIntentStatusProcessing),
                                                  @"succeeded": @(STPPaymentIntentStatusSucceeded),
                                                  @"requires_capture": @(STPPaymentIntentStatusRequiresCapture),
                                                  @"canceled": @(STPPaymentIntentStatusCanceled),
                                                  };

    NSString *key = string.lowercaseString;
    NSNumber *statusNumber = map[key] ?: @(STPPaymentIntentStatusUnknown);
    return statusNumber.integerValue;
}

+ (STPPaymentIntentCaptureMethod)captureMethodFromString:(NSString *)string {
    NSDictionary<NSString *, NSNumber *> *map = @{
                                                  @"manual": @(STPPaymentIntentCaptureMethodManual),
                                                  @"automatic": @(STPPaymentIntentCaptureMethodAutomatic),
                                                  };

    NSString *key = string.lowercaseString;
    NSNumber *statusNumber = map[key] ?: @(STPPaymentIntentCaptureMethodUnknown);
    return statusNumber.integerValue;
}

+ (STPPaymentIntentConfirmationMethod)confirmationMethodFromString:(NSString *)string {
    NSDictionary<NSString *, NSNumber *> *map = @{
                                                  @"secret": @(STPPaymentIntentConfirmationMethodSecret),
                                                  @"publishable": @(STPPaymentIntentConfirmationMethodPublishable),
                                                  };

    NSString *key = string.lowercaseString;
    NSNumber *statusNumber = map[key] ?: @(STPPaymentIntentConfirmationMethodUnknown);
    return statusNumber.integerValue;
}


#pragma mark - STPAPIResponseDecodable

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }

    // required fields
    NSString *stripeId = [dict stp_stringForKey:@"id"];
    NSString *clientSecret = [dict stp_stringForKey:@"client_secret"];
    NSNumber *amount = [dict stp_numberForKey:@"amount"];
    NSString *currency = [dict stp_stringForKey:@"currency"];
    NSString *rawStatus = [dict stp_stringForKey:@"status"];
    if (!stripeId || !clientSecret || amount == nil || !currency || !rawStatus || !dict[@"livemode"]) {
        return nil;
    }

    STPPaymentIntent *paymentIntent = [self new];

    paymentIntent.stripeId = stripeId;
    paymentIntent.clientSecret = clientSecret;
    paymentIntent.amount = amount;
    paymentIntent.canceledAt = [dict stp_dateForKey:@"canceled_at"];
    NSString *rawCaptureMethod = [dict stp_stringForKey:@"capture_method"];
    paymentIntent.captureMethod = [[self class] captureMethodFromString:rawCaptureMethod];
    NSString *rawConfirmationMethod = [dict stp_stringForKey:@"confirmation_method"];
    paymentIntent.confirmationMethod = [[self class] confirmationMethodFromString:rawConfirmationMethod];
    paymentIntent.created = [dict stp_dateForKey:@"created"];
    paymentIntent.currency = currency;
    paymentIntent.stripeDescription = [dict stp_stringForKey:@"description"];
    paymentIntent.livemode = [dict stp_boolForKey:@"livemode" or:YES];
    // next_source_action is not being parsed. Today type=`authorize_with_url` is the only one
    // and STPRedirectContext reaches directly into it. Not yet sure how I want to model
    // this polymorphic object, so keeping it out of the public API.
    paymentIntent.returnUrl = [dict stp_urlForKey:@"return_url"];
    paymentIntent.receiptEmail = [dict stp_stringForKey:@"receipt_email"];
    // FIXME: add support for `shipping`
    paymentIntent.sourceId = [dict stp_stringForKey:@"source"];
    paymentIntent.status = [[self class] statusFromString:rawStatus];

    paymentIntent.allResponseFields = dict;

    return paymentIntent;
}

@end
