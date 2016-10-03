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
@property (nonatomic) NSDate *sessionAppOpenTime;
@property (nonatomic) NSDate *lastAppActiveTime;
@end

@implementation STPOptimizationMetrics

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
        [UIDevice currentDevice].batteryMonitoringEnabled = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reset {
    self.lastAppActiveTime = nil;
    self.sessionAppOpenTime = nil;
}

- (void)applicationDidBecomeActive {
    NSDate *currentTime = [NSDate date];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (![userDefaults objectForKey:STPUserDefaultsKeyFirstAppOpenTime]) {
        [userDefaults setObject:currentTime forKey:STPUserDefaultsKeyFirstAppOpenTime];
    }
    NSInteger totalAppOpenCount = [userDefaults integerForKey:STPUserDefaultsKeyTotalAppOpenCount];
    [userDefaults setInteger:(totalAppOpenCount + 1) forKey:STPUserDefaultsKeyTotalAppOpenCount];
    NSTimeInterval threshold = 60*5;
    if (self.lastAppActiveTime == nil || [currentTime timeIntervalSinceDate:self.lastAppActiveTime] > threshold) {
        [self reset];
        self.sessionAppOpenTime = currentTime;
    }
    [userDefaults synchronize];
    self.lastAppActiveTime = currentTime;
}

- (void)applicationDidEnterBackground {
    if (!self.lastAppActiveTime) {
        return;
    }
    NSInteger seconds = (NSInteger)[[NSDate date] timeIntervalSinceDate:self.lastAppActiveTime];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger usageDuration = [userDefaults integerForKey:STPUserDefaultsKeyTotalAppUsageDuration];
    [userDefaults setInteger:(usageDuration + seconds) forKey:STPUserDefaultsKeyTotalAppUsageDuration];
    [userDefaults synchronize];
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
    payload[@"first_app_open_time"] = [self timestampWithDate:[self firstAppOpenTime]];
    payload[@"total_app_open_count"] = [self totalAppOpenCount];
    payload[@"total_app_usage_duration"] = [self totalAppUsageDuration];
    payload[@"session_app_open_time"] = [self timestampWithDate:self.sessionAppOpenTime];
    UIDevice *device = [UIDevice currentDevice];
    NSString *version = device.systemVersion;
    if (version) {
        payload[@"os_version"] = version;
    }
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceType = @(systemInfo.machine);
    if (deviceType) {
        payload[@"device_type"] = deviceType;
    }
    float batteryLevel = device.batteryLevel;
    if (batteryLevel > 0) {
        payload[@"battery_level"] = @(batteryLevel);
    }
    payload[@"battery_status"] = [self stringForBatteryState:device.batteryState];
    return payload;
}

@end
