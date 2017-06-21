//
//  STPSourceVerificationTest.m
//  Stripe
//
//  Created by Joey Dong on 6/21/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@import XCTest;

#import "STPSourceVerification.h"
#import "STPSourceVerification+Private.h"

@interface STPSourceVerificationTest : XCTestCase

@end

@implementation STPSourceVerificationTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - STPSourceVerificationStatus Tests

- (void)testStatusFromString {
    XCTAssertEqual([STPSourceVerification statusFromString:@"pending"], STPSourceVerificationStatusPending);
    XCTAssertEqual([STPSourceVerification statusFromString:@"pending"], STPSourceVerificationStatusPending);

    XCTAssertEqual([STPSourceVerification statusFromString:@"succeeded"], STPSourceVerificationStatusSucceeded);
    XCTAssertEqual([STPSourceVerification statusFromString:@"SUCCEEDED"], STPSourceVerificationStatusSucceeded);

    XCTAssertEqual([STPSourceVerification statusFromString:@"failed"], STPSourceVerificationStatusFailed);
    XCTAssertEqual([STPSourceVerification statusFromString:@"FAILED"], STPSourceVerificationStatusFailed);

    XCTAssertEqual([STPSourceVerification statusFromString:@"unknown"], STPSourceVerificationStatusUnknown);
    XCTAssertEqual([STPSourceVerification statusFromString:@"UNKNOWN"], STPSourceVerificationStatusUnknown);

    XCTAssertEqual([STPSourceVerification statusFromString:@"garbage"], STPSourceVerificationStatusUnknown);
    XCTAssertEqual([STPSourceVerification statusFromString:@"GARBAGE"], STPSourceVerificationStatusUnknown);
}

- (void)testStringFromStatus {
    NSArray<NSNumber *> *values = @[
                                    @(STPSourceVerificationStatusPending),
                                    @(STPSourceVerificationStatusSucceeded),
                                    @(STPSourceVerificationStatusFailed),
                                    @(STPSourceVerificationStatusUnknown),
                                    ];

    for (NSNumber *statusNumber in values) {
        STPSourceVerificationStatus status = (STPSourceVerificationStatus)[statusNumber integerValue];
        NSString *string = [STPSourceVerification stringFromStatus:status];

        switch (status) {
            case STPSourceVerificationStatusPending:
                XCTAssertEqualObjects(string, @"pending");
                break;
            case STPSourceVerificationStatusSucceeded:
                XCTAssertEqualObjects(string, @"succeeded");
                break;
            case STPSourceVerificationStatusFailed:
                XCTAssertEqualObjects(string, @"failed");
                break;
            case STPSourceVerificationStatusUnknown:
                XCTAssertNil(string);
                break;
        }
    }
}

@end
