//
//  STPAnalyticsClientTest.m
//  Stripe
//
//  Created by Ben Guo on 4/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPAnalyticsClient.h"
#import "STPPaymentConfiguration.h"
#import "STPOptimizationMetrics.h"

@interface STPAnalyticsClient (Testing)
+ (BOOL)shouldCollectAnalytics;
@property (nonatomic) NSDate *lastAppActiveTime;
@end

@interface STPAnalyticsClientTest : XCTestCase

@end

@implementation STPAnalyticsClientTest

- (void)testShouldCollectAnalytics_alwaysFalseInTest {
    XCTAssertFalse([STPAnalyticsClient shouldCollectAnalytics]);
}

- (void)testOptimizationMetrics {
    STPPaymentConfiguration *configuration = [STPPaymentConfiguration sharedConfiguration];
    configuration.publishableKey = @"pk_123";
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];
    NSInteger currentTime = (NSInteger)[[NSDate date] timeIntervalSince1970];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
    NSDictionary *payload = [[STPOptimizationMetrics sharedInstance] serialize];
    XCTAssertEqual(0, [payload[@"ios_total_app_usage_duration"] integerValue]);
    XCTAssertEqual([payload[@"ios_session_app_open_time"] integerValue], currentTime);
    XCTAssertTrue([payload[@"ios_first_app_open_time"] integerValue] <= currentTime);
    XCTAssertTrue([payload[@"ios_total_app_open_count"] integerValue] >= 1);
    XCTAssertNotNil(payload[@"ios_os_version"]);
    XCTAssertNotNil(payload[@"ios_device_type"]);
    XCTAssertNotNil(payload[@"ios_battery_status"]);
}

@end
