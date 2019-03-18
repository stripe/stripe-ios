//
//  STPPaymentIntent.m
//  Stripe
//
//  Created by Daniel Jackson on 6/27/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import "STPPaymentIntent.h"
#import "STPPaymentIntent+Private.h"
#import "STPPaymentIntentSourceAction.h"
#import "STPPaymentIntentAction.h"
#import "STPPaymentMethod+Private.h"

#import "NSDictionary+Stripe.h"
#import "NSArray+Stripe.h"

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
@property (nonatomic, strong, nullable, readwrite) STPPaymentIntentAction* nextAction;
@property (nonatomic, copy, nullable, readwrite) NSString *receiptEmail;
@property (nonatomic, copy, nullable, readwrite) NSString *sourceId;
@property (nonatomic, copy, nullable, readwrite) NSString *paymentMethodId;
@property (nonatomic, assign, readwrite) STPPaymentIntentStatus status;
@property (nonatomic, copy, nullable, readwrite) NSArray<NSNumber *> *paymentMethodTypes;

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
                       [NSString stringWithFormat:@"nextAction = %@", self.nextAction],
                       [NSString stringWithFormat:@"paymentMethodId = %@", self.paymentMethodId],
                       [NSString stringWithFormat:@"paymentMethodTypes = %@", [self.allResponseFields stp_arrayForKey:@"payment_method_types"]],
                       [NSString stringWithFormat:@"receiptEmail = %@", self.receiptEmail],
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
                                                  @"requires_source": @(STPPaymentIntentStatusRequiresPaymentMethod), // 2015-10-12 API version still returns this instead of 'requires_payment_method'
                                                  @"requires_payment_method": @(STPPaymentIntentStatusRequiresPaymentMethod),
                                                  @"requires_confirmation": @(STPPaymentIntentStatusRequiresConfirmation),
                                                  @"requires_source_action": @(STPPaymentIntentStatusRequiresAction), // 2015-10-12 API version still returns this instead of 'requires_action'
                                                  @"requires_action": @(STPPaymentIntentStatusRequiresAction),
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

+ (STPPaymentIntentActionType)actionTypeFromString:(NSString *)string {
    NSDictionary<NSString *, NSNumber *> *map = @{
                                                  @"redirect_to_url": @(STPPaymentIntentActionTypeRedirectToURL),
                                                  };
    
    NSString *key = string.lowercaseString;
    NSNumber *statusNumber = map[key] ?: @(STPPaymentIntentActionTypeUnknown);
    return statusNumber.integerValue;
}

+ (NSString *)stringFromActionType:(STPPaymentIntentActionType)actionType {
    switch (actionType) {
        case STPPaymentIntentActionTypeRedirectToURL:
            return @"redirect_to_url";
        case STPPaymentIntentActionTypeUnknown:
            break;
    }
    
    // catch any unknown values here
    return @"unknown";
}

#pragma mark - Deprecated

- (STPPaymentIntentAction *)nextSourceAction {
    return self.nextAction;
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
    NSDictionary *nextActionDict = [dict stp_dictionaryForKey:@"next_action"];
    paymentIntent.nextAction = [STPPaymentIntentAction decodedObjectFromAPIResponse:nextActionDict];
    paymentIntent.receiptEmail = [dict stp_stringForKey:@"receipt_email"];
    // FIXME: add support for `shipping`
    paymentIntent.sourceId = [dict stp_stringForKey:@"source"];
    paymentIntent.paymentMethodId = [dict stp_stringForKey:@"payment_method"];
    NSArray<NSString *> *rawPaymentMethodTypes = [[dict stp_arrayForKey:@"payment_method_types"] stp_arrayByRemovingNulls];
    if (rawPaymentMethodTypes) {
        paymentIntent.paymentMethodTypes = [STPPaymentMethod typesFromStrings:rawPaymentMethodTypes];
    }
    paymentIntent.status = [[self class] statusFromString:rawStatus];

    paymentIntent.allResponseFields = dict;

    return paymentIntent;
}

@end
