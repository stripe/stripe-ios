//
//  STPSourceParams.m
//  Stripe
//
//  Created by Ben Guo on 1/23/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPSourceParams.h"

@implementation STPSourceParams

@synthesize additionalAPIParameters = _additionalAPIParameters;

- (instancetype)init {
    self = [super init];
    if (self) {
        _additionalAPIParameters = @{};
    }
    return self;
}

#pragma mark - STPFormEncodable

+ (NSString *)rootObjectName {
    return nil;
}

+ (NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(type)): @"type",
             NSStringFromSelector(@selector(amount)): @"amount",
             NSStringFromSelector(@selector(currency)): @"currency",
             NSStringFromSelector(@selector(flow)): @"flow",
             NSStringFromSelector(@selector(metadata)): @"metadata",
             NSStringFromSelector(@selector(owner)): @"owner",
             NSStringFromSelector(@selector(redirect)): @"redirect",
             NSStringFromSelector(@selector(token)): @"token",
             NSStringFromSelector(@selector(usage)): @"usage",
             };
}

@end
