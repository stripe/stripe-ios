//
//  STPMandateOnlineParams.m
//  Stripe
//
//  Created by Cameron Sabol on 10/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPMandateOnlineParams+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPMandateOnlineParams ()

@property (nonatomic, nullable) NSNumber *inferFromClient;

@end

@implementation STPMandateOnlineParams
@synthesize additionalAPIParameters;

#pragma mark - STPFormEncodable

+ (nonnull NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
        NSStringFromSelector(@selector(ipAddress)): @"ip_address",
        NSStringFromSelector(@selector(userAgent)): @"user_agent",
        NSStringFromSelector(@selector(inferFromClient)): @"infer_from_client",
    };
}

+ (nullable NSString *)rootObjectName {
    return @"online";
}

@end

NS_ASSUME_NONNULL_END
