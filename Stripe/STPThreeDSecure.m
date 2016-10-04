//
//  STPThreeDSecure.m
//  Stripe
//
//  Created by Brian Dorfman on 9/26/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPThreeDSecure.h"
#import "NSDictionary+Stripe.h"
#import "STPCard.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPThreeDSecure()
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;
@property (nonatomic, readwrite) BOOL authenticated;
@end

@implementation STPThreeDSecure

+ (NSArray *)requiredFields {
    return @[];
}

+ (STPThreeDSecureStatus)statusFromString:(NSString *)string {
    NSString *status = string.lowercaseString;
    if ([status isEqualToString:@"redirect_pending"]) {
        return STPThreeDSecureStatusRedirectPending;
    }
    else if ([status isEqualToString:@"succeeded"]) {
        return STPThreeDSecureStatusSucceeded;
    }
    else {
        return STPThreeDSecureStatusFailed;
    }
}

- (nullable instancetype)initWithAPIResponse:(NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNullsValidatingRequiredFields:[[self class] requiredFields]];
    if (!dict) {
        return nil;
    }
    
    if ((self = [super init])) {
        self.allResponseFields = dict;
        _threeDSecureId = dict[@"id"];
        _paymentAmount = [dict[@"amount"] integerValue];
        _paymentCurrency = dict[@"currency"];
        _authenticated = [dict[@"authenticated"] boolValue];
        _redirectURL = dict[@"redirect_url"];
        _status = [self.class statusFromString:dict[@"status"]];
        _card = [STPCard decodedObjectFromAPIResponse:dict[@"card"]];
    }
    
    return self;
}

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    return [[self alloc] initWithAPIResponse:response];
}

- (NSString *)stripeID {
    return self.threeDSecureId;
}

@end

@implementation STPThreeDSecureParams

@end

NS_ASSUME_NONNULL_END
