//
//  STPTelemetryClientTest.m
//  Stripe
//
//  Created by Ben Guo on 4/18/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPTelemetryClient.h"

@interface STPTelemetryClientTest : XCTestCase

@end

@implementation STPTelemetryClientTest

- (void)testAddTelemetryData {
    STPTelemetryClient *sut = [STPTelemetryClient sharedInstance];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];
    NSMutableDictionary *params = [@{@"foo": @"bar"} mutableCopy];
    XCTestExpectation *exp = [self expectationWithDescription:@"delay"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [sut addTelemetryFieldsToParams:params];
        NSInteger time = [params[@"time_on_page"] integerValue];
        XCTAssertTrue(time > 0);
        XCTAssertNotNil(params[@"muid"]);
        [exp fulfill];
    });
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

@end
