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
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import <sys/utsname.h>
#endif

@interface Stripe (Internal_Analytics)
+ (BOOL)shouldCollectAnalytics;
@end

@interface STPAPIClient (Internal_Analytics)
+ (NSString *)stripeUserAgentDetails;
@end

@interface STPAnalyticsClient()

@property (nonatomic, readwrite) NSURLSession *urlSession;
@property (nonatomic, readwrite) NSURL *baseURL;

@end

@implementation STPAnalyticsClient

+ (BOOL)shouldCollectAnalytics {
    return NSClassFromString(@"XCTest") == nil && [Stripe shouldCollectAnalytics];
}

+ (NSNumber *)timestampWithDate:(NSDate *)date {
    return @((NSInteger)([date timeIntervalSince1970]*1000));
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _urlSession = [NSURLSession sessionWithConfiguration:config];
        _baseURL = [NSURL URLWithString:@"https://q.stripe.com"];
    }
    return self;
}

- (void)logRUMWithTokenType:(NSString *)tokenType
                   response:(NSURLResponse *)response
                      start:(NSDate *)startTime
                        end:(NSDate *)endTime {
    if (![[self class] shouldCollectAnalytics]) {
        return;
    }
    if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
        return;
    }
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    NSNumber *start = [[self class] timestampWithDate:startTime];
    NSNumber *end = [[self class] timestampWithDate:endTime];
    NSMutableDictionary *payload = [@{
                                      @"event": @"rum.stripeios",
                                      @"tokenType": tokenType ?: @"unknown",
                                      @"url": httpResponse.URL.absoluteString ?: @"unknown",
                                      @"status": @(httpResponse.statusCode),
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
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.baseURL];
    [request stp_addParametersToURL:payload];
    NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:request];
    [task resume];
}

@end
