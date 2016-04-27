//
//  STPAnalyticsClient.m
//  Stripe
//
//  Created by Ben Guo on 4/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPAnalyticsClient.h"
#import "STPFormEncoder.h"
#import "NSMutableURLRequest+Stripe.h"
#import "STPAPIClient.h"
#import "TargetConditionals.h"
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import <sys/utsname.h>
#endif

static BOOL STPShouldCollectAnalytics = YES;

@interface STPAnalyticsClient()

@property (nonatomic, readwrite) NSURLSession *urlSession;

@end

@implementation STPAnalyticsClient

+ (void)disableAnalytics {
    STPShouldCollectAnalytics = NO;
}

+ (BOOL)shouldCollectAnalytics {
#if TARGET_OS_SIMULATOR
    return NO;
#endif
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
    return NSClassFromString(@"XCTest") == nil && STPShouldCollectAnalytics;
#pragma clang diagnostic pop
}

+ (NSNumber *)timestampWithDate:(NSDate *)date {
    return @((NSInteger)([date timeIntervalSince1970]*1000));
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _urlSession = [NSURLSession sessionWithConfiguration:config];
    }
    return self;
}

- (void)logRUMWithTokenType:(STPTokenType)tokenType
             publishableKey:(NSString *)publishableKey
                   response:(NSHTTPURLResponse *)response
                      start:(NSDate *)startTime
                        end:(NSDate *)endTime {
    if (![[self class] shouldCollectAnalytics]) {
        return;
    }
    NSString *tokenTypeString;
    switch (tokenType) {
        case STPTokenTypeCard:
            tokenTypeString = @"card";
            break;
        case STPTokenTypeApplePay:
            tokenTypeString = @"apple_pay";
            break;
        case STPTokenTypeBankAccount:
            tokenTypeString = @"bank_account";
            break;
    }
    NSNumber *start = [[self class] timestampWithDate:startTime];
    NSNumber *end = [[self class] timestampWithDate:endTime];
    NSMutableDictionary *payload = [@{
                                      @"event": @"rum.stripeios",
                                      @"tokenType": tokenTypeString,
                                      @"url": response.URL.absoluteString ?: @"unknown",
                                      @"status": @(response.statusCode),
                                      @"publishable_key": publishableKey ?: @"unknown",
                                      @"start": start,
                                      @"end": end,
                                      @"bindings_version": STPSDKVersion,
                                      } mutableCopy];
#if TARGET_OS_IPHONE
    NSString *version = [UIDevice currentDevice].systemVersion;
    if (version) {
        payload[@"os_version"] = version;
    }
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceType = @(systemInfo.machine);
    if (deviceType) {
        payload[@"device_type"] = deviceType;
    }
#endif
    NSURL *url = [NSURL URLWithString:@"https://q.stripe.com"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request stp_addParametersToURL:payload];
    NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:request];
    [task resume];
}

@end
