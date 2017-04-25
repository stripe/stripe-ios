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
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceType = @(systemInfo.machine) ?: @"";
    NSString *version = [UIDevice currentDevice].systemVersion ?: @"";
    return [@[deviceType, version] componentsJoinedByString:@" "];
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

- (NSString *)batteryLevel {
    UIDevice *device = [UIDevice currentDevice];
    return [NSString stringWithFormat:@"%.2f", device.batteryLevel];
}

- (NSString *)batteryState {
    UIDevice *device = [UIDevice currentDevice];
    switch (device.batteryState) {
        case UIDeviceBatteryStateFull: return @"full";
        case UIDeviceBatteryStateCharging: return @"charging";
        case UIDeviceBatteryStateUnplugged: return @"unplugged";
        case UIDeviceBatteryStateUnknown: return @"unknown";
    }
}

- (NSString *)deviceOrientation {
    UIDevice *device = [UIDevice currentDevice];
    switch (device.orientation) {
        case UIDeviceOrientationFaceUp: return @"face_up";
        case UIDeviceOrientationFaceDown: return @"face_down";
        case UIDeviceOrientationLandscapeLeft: return @"landscape_left";
        case UIDeviceOrientationLandscapeRight: return @"landscape_right";
        case UIDeviceOrientationPortrait: return @"portrait";
        case UIDeviceOrientationPortraitUpsideDown: return @"portrait_upside_down";
        case UIDeviceOrientationUnknown: return @"unknown";
    }
    return @"";
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
            default:
                [fields addObject:@[]];
                break;
        }
    }
    payload[@"f"] = fields;
    NSMutableDictionary *platformData = [NSMutableDictionary new];
    platformData[@"muid"] = [self muid];
    platformData[@"app_name"] = [NSBundle stp_applicationName];
    platformData[@"app_version"] = [NSBundle stp_applicationVersion];
    platformData[@"battery_level"] = [self batteryLevel];
    platformData[@"battery_state"] = [self batteryState];
    platformData[@"device_orientation"] = [self deviceOrientation];
    platformData[@"apple_pay_enabled"] = @([Stripe deviceSupportsApplePay]);
    payload[@"d"] = @[
                      @"",
                      [platformData copy]
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
