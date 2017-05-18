//
//  STPSourcePrecheckResult.m
//  Stripe
//
//  Created by Brian Dorfman on 5/8/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPSourcePrecheckResult.h"

#import "NSDictionary+Stripe.h"

@interface STPSourcePrecheckResult()
@property(nonatomic, copy) NSDictionary *allResponseFields;
@end

@implementation STPSourcePrecheckResult

+ (NSArray *)requiredFields {
    return @[@"required_actions"];
}

+ (instancetype)decodedObjectFromAPIResponse:(NSDictionary *)response {
    return [[self alloc] initWithAPIResponse:response];
}

- (instancetype)initWithAPIResponse:(NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNullsValidatingRequiredFields:[self.class requiredFields]];
    if (!dict) {
        return nil;
    }

    self = [super init];

    if (self) {
        _requiredActions = dict[@"required_actions"];
        _reason = dict[@"reason"];
        _rule = dict[@"rule"];
        _allResponseFields = response;

    }
    return self;
}

@end
