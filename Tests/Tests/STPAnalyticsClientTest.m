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
#import "STPPaymentMethodsViewController.h"
#import "STPAddCardViewController.h"
#import "STPSMSCodeViewController.h"

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
    NSString *event = [STPOptimizationMetrics eventNameWithClass:[STPPaymentMethodsViewController class] suffix:@"viewDidAppear"];
    [[STPAnalyticsClient sharedClient].optimizationMetrics logEvent:event];
    [[STPAnalyticsClient sharedClient].optimizationMetrics logEvent:event];
    id<STPSMSCodeViewControllerDelegate> addCardVC = (id<STPSMSCodeViewControllerDelegate>)[[STPAddCardViewController alloc] initWithConfiguration:configuration theme:[STPTheme defaultTheme]];
    [addCardVC smsCodeViewController:nil didAuthenticateAccount:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
    NSDictionary *payload = [[STPAnalyticsClient sharedClient].optimizationMetrics serialize];
    XCTAssertEqual(0, [payload[@"ios_total_app_usage_duration"] integerValue]);
    XCTAssertEqual([payload[@"ios_session_app_open_time"] integerValue], currentTime);
    XCTAssertTrue([payload[@"ios_first_app_open_time"] integerValue] <= currentTime);
    XCTAssertTrue([payload[@"ios_total_app_open_count"] integerValue] >= 1);
    XCTAssertEqualObjects(payload[@"ios_sms_autofill_used"], @"true");
    XCTAssertNotNil(payload[@"ios_os_version"]);
    XCTAssertNotNil(payload[@"ios_device_type"]);
    XCTAssertNotNil(payload[@"ios_battery_status"]);
    NSDictionary *events = payload[@"ios_events"];
    XCTAssertEqual((int)[((NSArray *)events[@"STPPaymentMethodsViewController_viewDidAppear"]) count], 2);
}

@end
