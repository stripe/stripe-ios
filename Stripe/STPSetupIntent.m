//
//  STPSetupIntent.m
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/27/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPSetupIntent.h"

#import "STPIntentAction.h"
#import "STPPaymentMethod+Private.h"

#import "NSArray+Stripe.h"
#import "NSDictionary+Stripe.h"

@interface STPSetupIntent()
@property (nonatomic, copy) NSString *stripeID;
@property (nonatomic, copy) NSString *clientSecret;
@property (nonatomic) NSDate *created;
@property (nonatomic, copy, nullable) NSString *customerID;
@property (nonatomic, copy, nullable) NSString *stripeDescription;
@property (nonatomic) BOOL livemode;
@property (nonatomic, copy, nullable) NSDictionary<NSString*, NSString *> *metadata;
@property (nonatomic, nullable) STPIntentAction *nextAction;
@property (nonatomic, copy, nullable) NSString *paymentMethodID;
@property (nonatomic, copy) NSArray<NSNumber *> *paymentMethodTypes;
@property (nonatomic) STPSetupIntentStatus status;
@property (nonatomic) STPSetupIntentUsage usage;

@property (nonatomic, copy, nonnull, readwrite) NSDictionary *allResponseFields;
@end

@implementation STPSetupIntent

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                       
                       // Identifier
                       [NSString stringWithFormat:@"stripeId = %@", self.stripeID],
                       
                       // SetupIntent details (alphabetical)
                       [NSString stringWithFormat:@"clientSecret = %@", (self.clientSecret) ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"created = %@", self.created],
                       [NSString stringWithFormat:@"customerId = %@", self.customerID],
                       [NSString stringWithFormat:@"description = %@", self.stripeDescription],
                       [NSString stringWithFormat:@"livemode = %@", self.livemode ? @"YES" : @"NO"],
                       [NSString stringWithFormat:@"metadata = %@", self.metadata],
                       [NSString stringWithFormat:@"nextAction = %@", self.nextAction],
                       [NSString stringWithFormat:@"paymentMethodId = %@", self.paymentMethodID],
                       [NSString stringWithFormat:@"paymentMethodTypes = %@", [self.allResponseFields stp_arrayForKey:@"payment_method_types"]],
                       [NSString stringWithFormat:@"status = %@", [self.allResponseFields stp_stringForKey:@"status"]],
                       [NSString stringWithFormat:@"usage = %@", [self.allResponseFields stp_stringForKey:@"usage"]],
                       ];
    
    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPSetupIntentEnum support

+ (STPSetupIntentStatus)statusFromString:(NSString *)string {
    NSDictionary<NSString *, NSNumber *> *map = @{
                                                  @"requires_payment_method": @(STPSetupIntentStatusRequiresPaymentMethod),
                                                  @"requires_confirmation": @(STPSetupIntentStatusRequiresConfirmation),
                                                  @"requires_action": @(STPSetupIntentStatusRequiresAction),
                                                  @"processing": @(STPSetupIntentStatusProcessing),
                                                  @"succeeded": @(STPSetupIntentStatusSucceeded),
                                                  @"canceled": @(STPSetupIntentStatusCanceled),
                                                  };
    
    NSString *key = string.lowercaseString;
    NSNumber *statusNumber = map[key] ?: @(STPSetupIntentStatusUnknown);
    return statusNumber.integerValue;
}

+ (STPSetupIntentUsage)usageFromString:(NSString *)string {
    NSDictionary<NSString *, NSNumber *> *map = @{
                                                  @"off_session": @(STPSetupIntentUsageOffSession),
                                                  @"on_session": @(STPSetupIntentUsageOnSession),
                                                  };
    
    NSString *key = string.lowercaseString;
    NSNumber *statusNumber = map[key] ?: @(STPSetupIntentUsageUnknown);
    return statusNumber.integerValue;
}

+ (nullable NSString *)idFromClientSecret:(NSString *)clientSecret {
    // see parseClientSecret from stripe-js-v3
    NSArray *components = [clientSecret componentsSeparatedByString:@"_secret_"];
    if (components.count >= 2 && [components[0] hasPrefix:@"seti_"]) {
        return components[0];
    } else {
        return nil;
    }
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
    NSString *rawStatus = [dict stp_stringForKey:@"status"];
    if (!stripeId || !clientSecret || !rawStatus || !dict[@"livemode"]) {
        return nil;
    }
    
    STPSetupIntent *setupIntent = [self new];
    
    setupIntent.stripeID = stripeId;
    setupIntent.clientSecret = clientSecret;
    setupIntent.created = [dict stp_dateForKey:@"created"];
    setupIntent.customerID = [dict stp_stringForKey:@"customer"];
    setupIntent.stripeDescription = [dict stp_stringForKey:@"description"];
    setupIntent.livemode = [dict stp_boolForKey:@"livemode" or:YES];
    setupIntent.metadata = [[dict stp_dictionaryForKey:@"metadata"] stp_dictionaryByRemovingNonStrings];
    NSDictionary *nextActionDict = [dict stp_dictionaryForKey:@"next_action"];
    setupIntent.nextAction = [STPIntentAction decodedObjectFromAPIResponse:nextActionDict];
    setupIntent.paymentMethodID = [dict stp_stringForKey:@"payment_method"];
    NSArray<NSString *> *rawPaymentMethodTypes = [[dict stp_arrayForKey:@"payment_method_types"] stp_arrayByRemovingNulls];
    if (rawPaymentMethodTypes) {
        setupIntent.paymentMethodTypes = [STPPaymentMethod typesFromStrings:rawPaymentMethodTypes];
    }
    setupIntent.status = [[self class] statusFromString:rawStatus];
    NSString *rawUsage = [dict stp_stringForKey:@"usage"];
    setupIntent.usage = rawUsage ? [[self class] usageFromString:rawUsage] : STPSetupIntentUsageNone;
    
    setupIntent.allResponseFields = dict;
    
    return setupIntent;
}

@end
