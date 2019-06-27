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
@property (nonatomic) NSString *stripeId;
@property (nonatomic) NSString *clientSecret;
@property (nonatomic) NSDate *created;
@property (nonatomic, nullable) NSString *customerId;
@property (nonatomic, nullable) NSString *stripeDescription;
@property (nonatomic) BOOL livemode;
@property (nonatomic, nullable) NSDictionary<NSString*, NSString *> *metadata;
@property (nonatomic, nullable) STPIntentAction *nextAction;
@property (nonatomic, nullable) NSString *paymentMethodId;
@property (nonatomic) NSArray<NSNumber *> *paymentMethodTypes;
@property (nonatomic) STPSetupIntentStatus status;

@property (nonatomic, copy, nonnull, readwrite) NSDictionary *allResponseFields;
@end

@implementation STPSetupIntent

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                       
                       // Identifier
                       [NSString stringWithFormat:@"stripeId = %@", self.stripeId],
                       
                       // SetupIntent details (alphabetical)
                       [NSString stringWithFormat:@"clientSecret = %@", (self.clientSecret) ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"created = %@", self.created],
                       [NSString stringWithFormat:@"customerId = %@", self.customerId],
                       [NSString stringWithFormat:@"description = %@", self.stripeDescription],
                       [NSString stringWithFormat:@"livemode = %@", self.livemode ? @"YES" : @"NO"],
                       [NSString stringWithFormat:@"metadata = %@", self.metadata],
                       [NSString stringWithFormat:@"nextAction = %@", self.nextAction],
                       [NSString stringWithFormat:@"paymentMethodId = %@", self.paymentMethodId],
                       [NSString stringWithFormat:@"paymentMethodTypes = %@", [self.allResponseFields stp_arrayForKey:@"payment_method_types"]],
                       [NSString stringWithFormat:@"status = %@", [self.allResponseFields stp_stringForKey:@"status"]],
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
    
    setupIntent.stripeId = stripeId;
    setupIntent.clientSecret = clientSecret;
    setupIntent.created = [dict stp_dateForKey:@"created"];
    setupIntent.customerId = [dict stp_stringForKey:@"customer"];
    setupIntent.stripeDescription = [dict stp_stringForKey:@"description"];
    setupIntent.livemode = [dict stp_boolForKey:@"livemode" or:YES];
    setupIntent.metadata = [[dict stp_dictionaryForKey:@"metadata"] stp_dictionaryByRemovingNonStrings];
    NSDictionary *nextActionDict = [dict stp_dictionaryForKey:@"next_action"];
    setupIntent.nextAction = [STPIntentAction decodedObjectFromAPIResponse:nextActionDict];
    setupIntent.paymentMethodId = [dict stp_stringForKey:@"payment_method"];
    NSArray<NSString *> *rawPaymentMethodTypes = [[dict stp_arrayForKey:@"payment_method_types"] stp_arrayByRemovingNulls];
    if (rawPaymentMethodTypes) {
        setupIntent.paymentMethodTypes = [STPPaymentMethod typesFromStrings:rawPaymentMethodTypes];
    }
    setupIntent.status = [[self class] statusFromString:rawStatus];
    
    setupIntent.allResponseFields = dict;
    
    return setupIntent;
}

@end
