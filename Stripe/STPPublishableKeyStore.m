//
//  STPPublishableKeyStore.m
//  Stripe
//
//  Created by Ben Guo on 5/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPPublishableKeyStore.h"
#import "STPAnalyticsClient.h"
#import "STPTelemetryClient.h"

@implementation STPPublishableKeyStore

+ (instancetype)sharedInstance {
    static STPPublishableKeyStore *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

@end
