//
//  STPSourceRedirectTest.m
//  Stripe
//
//  Created by Joey Dong on 6/21/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@import XCTest;

#import "STPSourceRedirect.h"
#import "STPSourceRedirect+Private.h"

@interface STPSourceRedirectTest : XCTestCase

@end

@implementation STPSourceRedirectTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - STPSourceRedirectStatus Tests

- (void)testStatusFromString {
    XCTAssertEqual([STPSourceRedirect statusFromString:@"pending"], STPSourceRedirectStatusPending);
    XCTAssertEqual([STPSourceRedirect statusFromString:@"PENDING"], STPSourceRedirectStatusPending);

    XCTAssertEqual([STPSourceRedirect statusFromString:@"succeeded"], STPSourceRedirectStatusSucceeded);
    XCTAssertEqual([STPSourceRedirect statusFromString:@"SUCCEEDED"], STPSourceRedirectStatusSucceeded);

    XCTAssertEqual([STPSourceRedirect statusFromString:@"failed"], STPSourceRedirectStatusFailed);
    XCTAssertEqual([STPSourceRedirect statusFromString:@"FAILED"], STPSourceRedirectStatusFailed);

    XCTAssertEqual([STPSourceRedirect statusFromString:@"unknown"], STPSourceRedirectStatusUnknown);
    XCTAssertEqual([STPSourceRedirect statusFromString:@"UNKNOWN"], STPSourceRedirectStatusUnknown);

    XCTAssertEqual([STPSourceRedirect statusFromString:@"garbage"], STPSourceRedirectStatusUnknown);
    XCTAssertEqual([STPSourceRedirect statusFromString:@"GARBAGE"], STPSourceRedirectStatusUnknown);
}

- (void)testStringFromStatus {
    NSArray<NSNumber *> *values = @[
                                    @(STPSourceRedirectStatusPending),
                                    @(STPSourceRedirectStatusSucceeded),
                                    @(STPSourceRedirectStatusFailed),
                                    @(STPSourceRedirectStatusUnknown),
                                    ];

    for (NSNumber *statusNumber in values) {
        STPSourceRedirectStatus status = (STPSourceRedirectStatus)[statusNumber integerValue];
        NSString *string = [STPSourceRedirect stringFromStatus:status];

        switch (status) {
            case STPSourceRedirectStatusPending:
                XCTAssertEqualObjects(string, @"pending");
                break;
            case STPSourceRedirectStatusSucceeded:
                XCTAssertEqualObjects(string, @"succeeded");
                break;
            case STPSourceRedirectStatusFailed:
                XCTAssertEqualObjects(string, @"failed");
                break;
            case STPSourceRedirectStatusUnknown:
                XCTAssertNil(string);
                break;
        }
    }
}

@end
