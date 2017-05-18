//
//  STPSourcePrecheckParams.m
//  Stripe
//
//  Created by Brian Dorfman on 5/8/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPSourcePrecheckParams.h"

@implementation STPSourcePrecheckParams

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
             NSStringFromSelector(@selector(sourceID)): @"source",
             NSStringFromSelector(@selector(paymentAmount)): @"amount",
             NSStringFromSelector(@selector(paymentCurrency)): @"currency",
             NSStringFromSelector(@selector(metadata)): @"metadata",
             };
}


@end
