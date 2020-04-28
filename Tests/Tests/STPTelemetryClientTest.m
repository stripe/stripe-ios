//
//  STPTelemetryClientTest.m
//  Stripe
//
//  Created by Ben Guo on 4/18/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPTelemetryClient.h"
#import "STPAPIClient.h"

@interface STPTelemetryClientTest : XCTestCase

@end

@implementation STPTelemetryClientTest

- (void)testAddTelemetryData {
    STPTelemetryClient *sut = [STPTelemetryClient sharedInstance];
    NSMutableDictionary *params = [@{@"foo": @"bar"} mutableCopy];
    XCTestExpectation *exp = [self expectationWithDescription:@"delay"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [sut addTelemetryFieldsToParams:params];
        XCTAssertNotNil(params[@"muid"]);
        [exp fulfill];
    });
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testAdvancedFraudSignalsSwitch {
    XCTAssertTrue([Stripe advancedFraudSignalsEnabled]);
    [Stripe setAdvancedFraudSignalsEnabled:NO];
    XCTAssertFalse([Stripe advancedFraudSignalsEnabled]);
}

@end
