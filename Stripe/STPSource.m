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
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;

@end

@implementation STPSource

+ (STPSourceType)typeFromString:(NSString *)string {
    NSString *type = [string lowercaseString];
    if ([type isEqualToString:@"bancontact"]) {
        return STPSourceTypeBancontact;
    } else if ([type isEqualToString:@"bitcoin"]) {
        return STPSourceTypeBitcoin;
    } else if ([type isEqualToString:@"card"]) {
        return STPSourceTypeCard;
    } else if ([type isEqualToString:@"giropay"]) {
        return STPSourceTypeGiropay;
    } else if ([type isEqualToString:@"ideal"]) {
        return STPSourceTypeIDEAL;
    } else if ([type isEqualToString:@"sepa_debit"]) {
        return STPSourceTypeSEPADebit;
    } else if ([type isEqualToString:@"sofort"]) {
        return STPSourceTypeSofort;
    } else if ([type isEqualToString:@"three_d_secure"]) {
        return STPSourceTypeThreeDSecure;
    } else {
        return STPSourceTypeUnknown;
    }
}

+ (STPSourceFlow)flowFromString:(NSString *)string {
    NSString *flow = [string lowercaseString];
    if ([flow isEqualToString:@"redirect"]) {
        return STPSourceFlowRedirect;
    } else if ([flow isEqualToString:@"receiver"]) {
        return STPSourceFlowReceiver;
    } else if ([flow isEqualToString:@"verification"]) {
        return STPSourceFlowVerification;
    } else if ([flow isEqualToString:@"none"]) {
        return STPSourceFlowNone;
    } else {
        return STPSourceFlowUnknown;
    }
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
    } else {
        return STPSourceStatusUnknown;
    }
}

+ (STPSourceUsage)usageFromString:(NSString *)string {
    NSString *usage = [string lowercaseString];
    if ([usage isEqualToString:@"reusable"]) {
        return STPSourceUsageReusable;
    } else if ([usage isEqualToString:@"single_use"]) {
        return STPSourceUsageSingleUse;
    } else {
        return STPSourceUsageUnknown;
    }
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
    return source;
}

@end
