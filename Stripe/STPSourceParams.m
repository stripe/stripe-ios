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
             @"type": @"type",
             @"amount": @"amount",
             @"currency": @"currency",
             @"flow": @"flow",
             @"metadata": @"metadata",
             @"owner": @"owner",
             @"redirect": @"redirect",
             @"token": @"token",
             @"usage": @"usage",
             };
}

@end
