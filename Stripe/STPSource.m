//
//  STPSource.m
//  Stripe
//
//  Created by Ben Guo on 1/23/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//


#import "STPSource.h"
#import "STPSource+Private.h"

#import "STPImageLibrary.h"
#import "STPLocalizationUtils.h"
#import "STPSourceOwner.h"
#import "STPSourceReceiver.h"
#import "STPSourceRedirect.h"
#import "STPSourceVerification.h"

#import "NSDictionary+Stripe.h"

@interface STPSource ()

@property (nonatomic, nonnull) NSString *stripeID;
@property (nonatomic, nullable) NSNumber *amount;
@property (nonatomic, nullable) NSString *clientSecret;
@property (nonatomic, nullable) NSDate *created;
@property (nonatomic, nullable) NSString *currency;
@property (nonatomic) STPSourceFlow flow;
@property (nonatomic) BOOL livemode;
@property (nonatomic, copy, nullable, readwrite) NSDictionary<NSString *, NSString *> *metadata;
@property (nonatomic, nullable) STPSourceOwner *owner;
@property (nonatomic, nullable) STPSourceReceiver *receiver;
@property (nonatomic, nullable) STPSourceRedirect *redirect;
@property (nonatomic) STPSourceStatus status;
@property (nonatomic) STPSourceType type;
@property (nonatomic) STPSourceUsage usage;
@property (nonatomic, nullable) STPSourceVerification *verification;
@property (nonatomic, nullable) NSDictionary *details;
@property (nonatomic, nullable) STPSourceCardDetails *cardDetails;
@property (nonatomic, nullable) STPSourceSEPADebitDetails *sepaDebitDetails;
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;

// See STPSource+Private.h

@end

@implementation STPSource

#pragma mark - STPSourceType

+ (NSDictionary<NSString *,NSNumber *> *)stringToTypeMapping {
    return @{
             @"bancontact": @(STPSourceTypeBancontact),
             @"bitcoin": @(STPSourceTypeBitcoin),
             @"card": @(STPSourceTypeCard),
             @"giropay": @(STPSourceTypeGiropay),
             @"ideal": @(STPSourceTypeIDEAL),
             @"sepa_debit": @(STPSourceTypeSEPADebit),
             @"sofort": @(STPSourceTypeSofort),
             @"three_d_secure": @(STPSourceTypeThreeDSecure),
             @"alipay": @(STPSourceTypeAlipay),
             @"p24": @(STPSourceTypeP24),
             };
}

+ (STPSourceType)typeFromString:(NSString *)string {
    NSString *key = [string lowercaseString];
    NSNumber *typeNumber = [self stringToTypeMapping][key];

    if (typeNumber) {
        return (STPSourceType)[typeNumber integerValue];
    }

    return STPSourceTypeUnknown;
}

+ (nullable NSString *)stringFromType:(STPSourceType)type {
    return [[[self stringToTypeMapping] allKeysForObject:@(type)] firstObject];
}

#pragma mark - STPSourceFlow

+ (NSDictionary<NSString *,NSNumber *> *)stringToFlowMapping {
    return @{
             @"redirect": @(STPSourceFlowRedirect),
             @"receiver": @(STPSourceFlowReceiver),
             @"code_verification": @(STPSourceFlowCodeVerification),
             @"none": @(STPSourceFlowNone),
             };
}

+ (STPSourceFlow)flowFromString:(NSString *)string {
    NSString *key = [string lowercaseString];
    NSNumber *flowNumber = [self stringToFlowMapping][key];

    if (flowNumber) {
        return (STPSourceFlow)[flowNumber integerValue];
    }

    return STPSourceFlowUnknown;
}

+ (nullable NSString *)stringFromFlow:(STPSourceFlow)flow {
    return [[[self stringToFlowMapping] allKeysForObject:@(flow)] firstObject];
}

#pragma mark - STPSourceStatus

+ (NSDictionary <NSString *, NSNumber *> *)stringToStatusMapping {
    return @{
             @"pending": @(STPSourceStatusPending),
             @"chargeable": @(STPSourceStatusChargeable),
             @"consumed": @(STPSourceStatusConsumed),
             @"canceled": @(STPSourceStatusCanceled),
             @"failed": @(STPSourceStatusFailed),
             };
}

+ (STPSourceStatus)statusFromString:(NSString *)string {
    NSString *key = [string lowercaseString];
    NSNumber *statusNumber = [self stringToStatusMapping][key];

    if (statusNumber) {
        return (STPSourceStatus)[statusNumber integerValue];
    }

    return STPSourceStatusUnknown;
}

+ (nullable NSString *)stringFromStatus:(STPSourceStatus)status {
    return [[[self stringToStatusMapping] allKeysForObject:@(status)] firstObject];
}

#pragma mark - STPSourceUsage

+ (NSDictionary<NSString *,NSNumber *> *)stringToUsageMapping {
    return @{
             @"reusable": @(STPSourceUsageReusable),
             @"single_use": @(STPSourceUsageSingleUse),
             };
}

+ (STPSourceUsage)usageFromString:(NSString *)string {
    NSString *key = [string lowercaseString];
    NSNumber *usageNumber = [self stringToUsageMapping][key];

    if (usageNumber) {
        return (STPSourceUsage)[usageNumber integerValue];
    }

    return STPSourceUsageUnknown;
}

+ (nullable NSString *)stringFromUsage:(STPSourceUsage)usage {
    return [[[self stringToUsageMapping] allKeysForObject:@(usage)] firstObject];
}

#pragma mark - Equality

- (BOOL)isEqual:(STPSource *)source {
    return [self isEqualToSource:source];
}

- (NSUInteger)hash {
    return [self.stripeID hash];
}

- (BOOL)isEqualToSource:(STPSource *)source {
    if (self == source) {
        return YES;
    }

    if (!source || ![source isKindOfClass:self.class]) {
        return NO;
    }

    return [self.stripeID isEqualToString:source.stripeID];
}

#pragma mark - Description

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                       // Identifier
                       [NSString stringWithFormat:@"stripeID = %@", self.stripeID],

                       // Source details (alphabetical)
                       [NSString stringWithFormat:@"amount = %@", self.amount],
                       [NSString stringWithFormat:@"clientSecret = %@", (self.clientSecret) ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"created = %@", self.created],
                       [NSString stringWithFormat:@"currency = %@", self.currency],
                       [NSString stringWithFormat:@"flow = %@", ([self.class stringFromFlow:self.flow]) ?: @"unknown"],
                       [NSString stringWithFormat:@"livemode = %@", (self.livemode) ? @"YES" : @"NO"],
                       [NSString stringWithFormat:@"metadata = %@", (self.metadata) ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"owner = %@", (self.owner) ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"receiver = %@", self.receiver],
                       [NSString stringWithFormat:@"redirect = %@", self.redirect],
                       [NSString stringWithFormat:@"status = %@", ([self.class stringFromStatus:self.status]) ?: @"unknown"],
                       [NSString stringWithFormat:@"type = %@", ([self.class stringFromType:self.type]) ?: @"unknown"],
                       [NSString stringWithFormat:@"usage = %@", ([self.class stringFromUsage:self.usage]) ?: @"unknown"],
                       [NSString stringWithFormat:@"verification = %@", self.verification],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPAPIResponseDecodable

- (NSString *)stripeObject {
    return @"source";
}

+ (instancetype)decodedObjectFromAPIResponse:(NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }

    // required fields
    NSString *stripeId = [dict stp_stringForKey:@"id"];
    NSString *rawStatus = [dict stp_stringForKey:@"status"];
    NSString *rawType = [dict stp_stringForKey:@"type"];
    if (!stripeId || !rawStatus || !rawType || !dict[@"livemode"]) {
        return nil;
    }

    STPSource *source = [self new];
    source.stripeID = stripeId;
    source.amount = [dict stp_numberForKey:@"amount"];
    source.clientSecret = [dict stp_stringForKey:@"client_secret"];
    source.created = [dict stp_dateForKey:@"created"];
    source.currency = [dict stp_stringForKey:@"currency"];
    NSString *rawFlow = [dict stp_stringForKey:@"flow"];
    source.flow = [[self class] flowFromString:rawFlow];
    source.livemode = [dict stp_boolForKey:@"livemode" or:YES];
    source.metadata = [[dict stp_dictionaryForKey:@"metadata"] stp_dictionaryByRemovingNonStrings];
    NSDictionary *rawOwner = [dict stp_dictionaryForKey:@"owner"];
    source.owner = [STPSourceOwner decodedObjectFromAPIResponse:rawOwner];
    NSDictionary *rawReceiver = [dict stp_dictionaryForKey:@"receiver"];
    source.receiver = [STPSourceReceiver decodedObjectFromAPIResponse:rawReceiver];
    NSDictionary *rawRedirect = [dict stp_dictionaryForKey:@"redirect"];
    source.redirect = [STPSourceRedirect decodedObjectFromAPIResponse:rawRedirect];
    source.status = [[self class] statusFromString:rawStatus];
    source.type = [[self class] typeFromString:rawType];
    NSString *rawUsage = [dict stp_stringForKey:@"usage"];
    source.usage = [[self class] usageFromString:rawUsage];
    NSDictionary *rawVerification = [dict stp_dictionaryForKey:@"verification"];
    if (rawVerification) {
        source.verification = [STPSourceVerification decodedObjectFromAPIResponse:rawVerification];
    }
    source.details = [dict stp_dictionaryForKey:rawType];
    source.allResponseFields = dict;

    if (source.type == STPSourceTypeCard) {
        source.cardDetails = [STPSourceCardDetails decodedObjectFromAPIResponse:source.details];
    }
    else if (source.type == STPSourceTypeSEPADebit) {
        source.sepaDebitDetails = [STPSourceSEPADebitDetails decodedObjectFromAPIResponse:source.details];
    }

    return source;
}

#pragma mark - STPPaymentMethod

- (UIImage *)image {
    if (self.type == STPSourceTypeCard
        && self.cardDetails != nil) {
        return [STPImageLibrary brandImageForCardBrand:self.cardDetails.brand];
    }
    else {
        return [STPImageLibrary brandImageForCardBrand:STPCardBrandUnknown];
    }
}

- (UIImage *)templateImage {
    if (self.type == STPSourceTypeCard
        && self.cardDetails != nil) {
        return [STPImageLibrary templatedBrandImageForCardBrand:self.cardDetails.brand];
    }
    else {
        return [STPImageLibrary templatedBrandImageForCardBrand:STPCardBrandUnknown];
    }
}

- (NSString *)label {
    if (self.type == STPSourceTypeCard
        && self.cardDetails != nil) {
        NSString *brand = [STPCard stringFromBrand:self.cardDetails.brand];
        return [NSString stringWithFormat:@"%@ %@", brand, self.cardDetails.last4];;
    }
    else {
        return [STPCard stringFromBrand:STPCardBrandUnknown];
    }
}


@end
