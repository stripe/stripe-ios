//
//  STPTelemetryClient.m
//  Stripe
//
//  Created by Ben Guo on 4/18/17.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

@import WebKit;
@import UIKit;
#import <sys/utsname.h>

#import "STPTelemetryClient.h"
#import "STPAPIClient.h"

typedef NS_ENUM(NSInteger, STPMetricField) {
    STPMetricFieldCookieSupport = 0,
    STPMetricFieldDoNotTrack,
    STPMetricFieldLanguage,
    STPMetricFieldPlatform,
    STPMetricFieldPlugins,
    STPMetricFieldScreenSize,
    STPMetricFieldTimeZoneOffset,
    STPMetricFieldTouchSupport,
    STPMetricFieldAvailableStorage,
    STPMetricFieldFonts,
    STPMetricFieldGraphicsConfiguration,
    STPMetricFieldUserAgent,
    STPMetricFieldFlashVersion,
    STPMetricFieldHasAdBlocker,
    STPMetricFieldCanvasId,
    STPMetricFieldMax
};

@interface STPTelemetryClient ()
@property (nonatomic) NSDate *appOpenTime;
@property (nonatomic, readwrite) NSURLSession *urlSession;
@property (nonatomic, readwrite) NSString *userAgent;
@property (nonatomic, readwrite) WKWebView *webView;
@end

@implementation STPTelemetryClient

+ (BOOL)shouldSendTelemetry {
#if TARGET_OS_SIMULATOR
    return NO;
#endif
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
    return NSClassFromString(@"XCTest") == nil;
#pragma clang diagnostic pop
}

+ (instancetype)sharedInstance {
    static id sharedClient;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [self new];
    });
    return sharedClient;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _urlSession = [NSURLSession sessionWithConfiguration:config];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        WKWebView *webView = [WKWebView new];
        [webView loadHTMLString:@"<html></html>" baseURL:nil];
        [webView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id result, __unused NSError *error) {
            self.userAgent = result;
        }];
        _webView = webView;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)addTelemetryFieldsToParams:(NSMutableDictionary *)params {
    params[@"muid"] = [self muid];
    params[@"time_on_page"] = [self timeOnPage];
}

- (void)applicationDidBecomeActive {
    self.appOpenTime = [NSDate date];
}

- (NSString *)muid {
    NSString *muid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    return muid ?: @"";
}

- (NSNumber *)timeOnPage {
    if (!self.appOpenTime) {
        return @(0);
    }
    NSTimeInterval seconds = [[NSDate date] timeIntervalSinceDate:self.appOpenTime];
    NSInteger millis = (NSInteger)round(seconds*1000);
    return @(MAX(millis, 0));
}

- (NSString *)language {
    NSString *localeID = [[NSLocale currentLocale] localeIdentifier];
    return localeID ?: @"";
}

- (NSString *)platform {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceType = @(systemInfo.machine);
    return deviceType ?: @"";
}

- (NSString *)screenSize {
    UIScreen *screen = [UIScreen mainScreen];
    CGRect screenRect = [screen bounds];
    CGFloat width = screenRect.size.width;
    CGFloat height = screenRect.size.height;
    CGFloat scale = [screen scale];
    return [NSString stringWithFormat:@"%.0fw_%.0fh_%.0fr", width, height, scale];
}

- (NSString *)timeZoneOffset {
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    double hoursFromGMT = (double)timeZone.secondsFromGMT/(60*60);
    return [NSString stringWithFormat:@"%.0f", hoursFromGMT];
}

- (NSString *)userAgent {
    return _userAgent ?: @"";
}

- (NSDictionary *)payload {
    NSMutableDictionary *payload = [NSMutableDictionary new];
    NSMutableArray *fields = [NSMutableArray new];
    for (STPMetricField i = 0; i < STPMetricFieldMax; i++) {
        switch (i) {
            case STPMetricFieldLanguage:
                [fields addObject:@[[self language]]];
                break;
            case STPMetricFieldPlatform:
                [fields addObject:@[[self platform]]];
                break;
            case STPMetricFieldScreenSize:
                [fields addObject:@[[self screenSize]]];
                break;
            case STPMetricFieldTimeZoneOffset:
                [fields addObject:@[[self timeZoneOffset]]];
                break;
            case STPMetricFieldUserAgent:
                [fields addObject:@[[self userAgent]]];
                break;
            default:
                [fields addObject:@[]];
                break;
        }
    }
    payload[@"f"] = fields;
    payload[@"d"] = @[
                      @"",
                      @{@"muid": [self muid]},
                      ];
    payload[@"tag"] = STPSDKVersion;
    payload[@"src"] = @"ios-sdk";
    return [payload copy];
}

- (void)sendTelemetryData {
    if (![[self class] shouldSendTelemetry]) {
        return;
    }
    NSString *path = @"ios-sdk-1";
    NSURL *url = [[NSURL URLWithString:@"https://m.stripe.com"] URLByAppendingPathComponent:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSDictionary *payload = [self payload];
    NSData *data = [NSJSONSerialization dataWithJSONObject:payload options:(NSJSONWritingOptions)0 error:nil];
    request.HTTPBody = data;
    NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:request];
    [task resume];
}

@end
