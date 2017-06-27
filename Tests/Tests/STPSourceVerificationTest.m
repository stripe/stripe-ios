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

#pragma mark - Description Tests

- (void)testDescription {
    STPSourceVerification *verification = [STPSourceVerification decodedObjectFromAPIResponse:[self completeAttributeDictionary]];
    XCTAssert(verification.description);
}

#pragma mark - STPAPIResponseDecodable Tests

- (NSDictionary *)completeAttributeDictionary {
    // Source: https://stripe.com/docs/sources/sepa-debit
    return @{
             @"attempts_remaining": @(5),
             @"status": @"pending",
             };
}

- (void)testDecodedObjectFromAPIResponseRequiredFields {
    NSArray<NSString *> *requiredFields = @[
                                            @"status",
                                            ];

    for (NSString *field in requiredFields) {
        NSMutableDictionary *response = [[self completeAttributeDictionary] mutableCopy];
        [response removeObjectForKey:field];

        XCTAssertNil([STPSourceVerification decodedObjectFromAPIResponse:response]);
    }

    XCTAssert([STPSourceVerification decodedObjectFromAPIResponse:[self completeAttributeDictionary]]);
}

- (void)testDecodedObjectFromAPIResponseMapping {
    NSDictionary *response = [self completeAttributeDictionary];
    STPSourceVerification *verification = [STPSourceVerification decodedObjectFromAPIResponse:response];

    XCTAssertEqualObjects(verification.attemptsRemaining, @5);
    XCTAssertEqual(verification.status, STPSourceVerificationStatusPending);

    XCTAssertNotEqual(verification.allResponseFields, response);
    XCTAssertEqualObjects(verification.allResponseFields, response);
}

@end
