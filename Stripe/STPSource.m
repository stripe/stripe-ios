//
//  STPSource.m
//  Stripe
//
//  Created by Ben Guo on 1/23/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "NSDictionary+Stripe.h"
#import "STPSource.h"
#import "STPSourceOwner.h"
#import "STPSourceReceiver.h"
#import "STPSourceRedirect.h"
#import "STPSourceVerification.h"

@interface STPSource ()

@property (nonatomic, nonnull) NSString *stripeID;
@property (nonatomic, nullable) NSNumber *amount;
@property (nonatomic, nullable) NSString *clientSecret;
@property (nonatomic, nullable) NSDate *created;
@property (nonatomic, nullable) NSString *currency;
@property (nonatomic) STPSourceFlow flow;
@property (nonatomic) BOOL livemode;
@property (nonatomic, nullable) NSDictionary *metadata;
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

@end

@implementation STPSource

+ (NSDictionary<NSString *,NSNumber *>*)stringToType {
    return @{
             @"bancontact": @(STPSourceTypeBancontact),
             @"bitcoin": @(STPSourceTypeBitcoin),
             @"card": @(STPSourceTypeCard),
             @"giropay": @(STPSourceTypeGiropay),
             @"ideal": @(STPSourceTypeIDEAL),
             @"sepa_debit": @(STPSourceTypeSEPADebit),
             @"sofort": @(STPSourceTypeSofort),
             @"three_d_secure": @(STPSourceTypeThreeDSecure)
             };
}

+ (STPSourceType)typeFromString:(NSString *)string {
    NSString *key = [string lowercaseString];
    NSNumber *value = [self stringToType][key];
    if (value) {
        return (STPSourceType)[value integerValue];
    } else {
        return STPSourceTypeUnknown;
    }
}

+ (NSString *)stringFromType:(STPSourceType)type {
    return [[[self stringToType] allKeysForObject:@(type)] firstObject];
}

+ (NSDictionary<NSString *,NSNumber *>*)stringToFlow {
    return @{
             @"redirect": @(STPSourceFlowRedirect),
             @"receiver": @(STPSourceFlowReceiver),
             @"code_verification": @(STPSourceFlowCodeVerification),
             @"none": @(STPSourceFlowNone)
             };
}

+ (STPSourceFlow)flowFromString:(NSString *)string {
    NSString *key = [string lowercaseString];
    NSNumber *value = [self stringToFlow][key];
    if (value) {
        return (STPSourceFlow)[value integerValue];
    } else {
        return STPSourceFlowUnknown;
    }
}

+ (NSString *)stringFromFlow:(STPSourceFlow)flow {
    return [[[self stringToFlow] allKeysForObject:@(flow)] firstObject];
}

+ (STPSourceStatus)statusFromString:(NSString *)string {
    NSString *status = [string lowercaseString];
    if ([status isEqualToString:@"pending"]) {
        return STPSourceStatusPending;
    } else if ([status isEqualToString:@"chargeable"]) {
        return STPSourceStatusChargeable;
    } else if ([status isEqualToString:@"consumed"]) {
        return STPSourceStatusConsumed;
    } else if ([status isEqualToString:@"canceled"]) {
        return STPSourceStatusCanceled;
    } else if ([status isEqualToString:@"failed"]) {
        return STPSourceStatusFailed;
    } else {
        return STPSourceStatusUnknown;
    }
}

+ (NSDictionary<NSString *,NSNumber *>*)stringToUsage {
    return @{
             @"reusable": @(STPSourceUsageReusable),
             @"single_use": @(STPSourceUsageSingleUse)
             };
}

+ (STPSourceUsage)usageFromString:(NSString *)string {
    NSString *key = [string lowercaseString];
    NSNumber *value = [self stringToUsage][key];
    if (value) {
        return (STPSourceUsage)[value integerValue];
    } else {
        return STPSourceUsageUnknown;
    }
}

+ (NSString *)stringFromUsage:(STPSourceUsage)usage {
    return [[[self stringToUsage] allKeysForObject:@(usage)] firstObject];
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

#pragma mark STPAPIResponseDecodable

+ (NSArray *)requiredFields {
    return @[@"id", @"livemode", @"status", @"type"];
}

+ (instancetype)decodedObjectFromAPIResponse:(NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNullsValidatingRequiredFields:[self requiredFields]];
    if (!dict) {
        return nil;
    }

    STPSource *source = [self new];
    source.stripeID = dict[@"id"];
    source.amount = dict[@"amount"];
    source.clientSecret = dict[@"client_secret"];
    source.created = [NSDate dateWithTimeIntervalSince1970:[dict[@"created"] doubleValue]];
    source.currency = dict[@"currency"];
    source.flow = [[self class] flowFromString:dict[@"flow"]];
    source.livemode = [dict[@"livemode"] boolValue];
    source.metadata = dict[@"metadata"];
    source.owner = [STPSourceOwner decodedObjectFromAPIResponse:dict[@"owner"]];
    source.receiver = [STPSourceReceiver decodedObjectFromAPIResponse:dict[@"receiver"]];
    source.redirect = [STPSourceRedirect decodedObjectFromAPIResponse:dict[@"redirect"]];
    source.status = [[self class] statusFromString:dict[@"status"]];
    NSString *typeString = dict[@"type"];
    source.type = [[self class] typeFromString:typeString];
    source.usage = [[self class] usageFromString:dict[@"usage"]];
    source.verification = [STPSourceVerification decodedObjectFromAPIResponse:dict[@"verification"]];
    source.details = dict[typeString];
    source.allResponseFields = dict;

    if (source.type == STPSourceTypeCard) {
        source.cardDetails = [STPSourceCardDetails decodedObjectFromAPIResponse:source.details];
    }
    else if (source.type == STPSourceTypeSEPADebit) {
        source.sepaDebitDetails = [STPSourceSEPADebitDetails decodedObjectFromAPIResponse:source.details];
    }

    return source;
}

@end
