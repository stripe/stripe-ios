//
//  STPOptimizationMetrics.m
//  Stripe
//
//  Created by Ben Guo on 7/15/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPOptimizationMetrics.h"
#import <UIKit/UIKit.h>
#import <sys/utsname.h>

NSString *const STPUserDefaultsKeyFirstAppOpenTime = @"STPFirstAppOpenTime";
NSString *const STPUserDefaultsKeyTotalAppOpenCount = @"STPTotalAppOpenCount";
NSString *const STPUserDefaultsKeyTotalAppUsageDuration = @"STPTotalAppUsageDuration";

@interface STPOptimizationMetrics ()
@end

@implementation STPOptimizationMetrics

- (instancetype)init {
    self = [super init];
    if (self) {
        [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    }
    return self;
}

- (NSDate *)firstAppOpenTime {
    id object = [[NSUserDefaults standardUserDefaults] objectForKey:STPUserDefaultsKeyFirstAppOpenTime];
    if ([object isKindOfClass:[NSDate class]]) {
        return (NSDate *)object;
    }
    return nil;
}

- (NSNumber *)totalAppOpenCount {
    return @([[NSUserDefaults standardUserDefaults] integerForKey:STPUserDefaultsKeyTotalAppOpenCount]);
}

- (NSNumber *)totalAppUsageDuration {
    NSInteger duration = [[NSUserDefaults standardUserDefaults] integerForKey:STPUserDefaultsKeyTotalAppUsageDuration];
    if (self.sessionAppOpenTime != nil) {
        duration += (NSInteger)[[NSDate date] timeIntervalSinceDate:self.sessionAppOpenTime];
    }
    return @(duration);
}

- (NSNumber *)timestampWithDate:(NSDate *)date {
    if (!date) {
        return nil;
    }
    return @((NSInteger)[date timeIntervalSince1970]);
}

- (NSString *)stringForBatteryState:(UIDeviceBatteryState)state {
    switch (state) {
        case UIDeviceBatteryStateFull:
            return @"full";
        case UIDeviceBatteryStateCharging:
            return @"charging";
        case UIDeviceBatteryStateUnplugged:
            return @"unplugged";
        case UIDeviceBatteryStateUnknown:
            return @"unknown";
    }
}

- (NSDictionary *)serialize {
    NSMutableDictionary *payload = [NSMutableDictionary new];
    payload[@"ios_first_app_open_time"] = [self timestampWithDate:[self firstAppOpenTime]];
    payload[@"ios_total_app_open_count"] = [self totalAppOpenCount];
    payload[@"ios_total_app_usage_duration"] = [self totalAppUsageDuration];
    payload[@"ios_session_app_open_time"] = [self timestampWithDate:self.sessionAppOpenTime];
    UIDevice *device = [UIDevice currentDevice];
    NSString *version = device.systemVersion;
    if (version) {
        payload[@"ios_os_version"] = version;
    }
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceType = @(systemInfo.machine);
    if (deviceType) {
        payload[@"ios_device_type"] = deviceType;
    }
    float batteryLevel = device.batteryLevel;
    if (batteryLevel > 0) {
        payload[@"ios_battery_level"] = @(batteryLevel);
    }
    payload[@"ios_battery_status"] = [self stringForBatteryState:device.batteryState];
    return payload;
}

@end
