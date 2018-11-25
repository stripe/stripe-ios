//
//  STPTelemetryClient.m
//  Stripe
//
//  Created by Ben Guo on 4/18/17.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sys/utsname.h>

#import "NSBundle+Stripe_AppName.h"
#import "STPTelemetryClient.h"
#import "STPAPIClient.h"
#import "STPAPIClient+Private.h"

@interface STPTelemetryClient ()
@property (nonatomic) NSDate *appOpenTime;
@property (nonatomic, readwrite) NSURLSession *urlSession;
@end

@implementation STPTelemetryClient

+ (BOOL)shouldSendTelemetry {
#if TARGET_OS_SIMULATOR
    return NO;
#else
    return NSClassFromString(@"XCTest") == nil;
#endif
}

+ (instancetype)sharedInstance {
    NSURLSessionConfiguration *config = [STPAPIClient sharedUrlSessionConfiguration];
    static STPTelemetryClient *sharedClient;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[self alloc] initWithSessionConfiguration:config];
    });
    return sharedClient;
}

- (instancetype)init {
    return [self initWithSessionConfiguration:[STPAPIClient sharedUrlSessionConfiguration]];
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)config {
    self = [super init];
    if (self) {
        _urlSession = [NSURLSession sessionWithConfiguration:config];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
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
    return [@[[self deviceModel], [self osVersion]] componentsJoinedByString:@" "];
}

- (NSString *)deviceModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    return @(systemInfo.machine) ?: @"";
}

- (NSString *)osVersion {
    return [UIDevice currentDevice].systemVersion ?: @"";
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

- (NSDictionary *)encodeValue:(NSString *)value {
    if (value) {
        return @{@"v": value};
    }
    return nil;
}

- (NSDictionary *)payload {
    NSMutableDictionary *payload = [NSMutableDictionary new];
    NSMutableDictionary *data = [NSMutableDictionary new];
    data[@"c"] = [self encodeValue:[self language]];
    data[@"d"] = [self encodeValue:[self platform]];
    data[@"f"] = [self encodeValue:[self screenSize]];
    data[@"g"] = [self encodeValue:[self timeZoneOffset]];
    payload[@"a"] = [data copy];
    NSMutableDictionary *otherData = [NSMutableDictionary new];
    otherData[@"d"] = [self muid];
    otherData[@"k"] = [NSBundle stp_applicationName];
    otherData[@"l"] = [NSBundle stp_applicationVersion];
    otherData[@"m"] = @([Stripe deviceSupportsApplePay]);
    otherData[@"o"] = [self osVersion];
    otherData[@"s"] = [self deviceModel];
    payload[@"b"] = [otherData copy];
    payload[@"tag"] = STPSDKVersion;
    payload[@"src"] = @"ios-sdk";
    payload[@"v2"] = @1;
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
