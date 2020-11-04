//
//  STPSourceVerificationTest.m
//  Stripe
//
//  Created by Joey Dong on 6/21/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@import XCTest;


#import "STPTestUtils.h"

@interface STPSourceVerification ()

+ (STPSourceVerificationStatus)statusFromString:(NSString *)string;
+ (NSString *)stringFromStatus:(STPSourceVerificationStatus)status;

@end

@interface STPSourceVerificationTest : XCTestCase

@end

@implementation STPSourceVerificationTest

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
    STPSourceVerification *verification = [STPSourceVerification decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"SEPADebitSource"][@"verification"]];
    XCTAssert(verification.description);
}

#pragma mark - STPAPIResponseDecodable Tests

- (void)testDecodedObjectFromAPIResponseRequiredFields {
    NSArray<NSString *> *requiredFields = @[
                                            @"status",
                                            ];

    for (NSString *field in requiredFields) {
        NSMutableDictionary *response = [[STPTestUtils jsonNamed:@"SEPADebitSource"][@"verification"] mutableCopy];
        [response removeObjectForKey:field];

        XCTAssertNil([STPSourceVerification decodedObjectFromAPIResponse:response]);
    }

    XCTAssert([STPSourceVerification decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"SEPADebitSource"][@"verification"]]);
}

- (void)testDecodedObjectFromAPIResponseMapping {
    NSDictionary *response = [STPTestUtils jsonNamed:@"SEPADebitSource"][@"verification"];
    STPSourceVerification *verification = [STPSourceVerification decodedObjectFromAPIResponse:response];

    XCTAssertEqualObjects(verification.attemptsRemaining, @5);
    XCTAssertEqual(verification.status, STPSourceVerificationStatusPending);

    XCTAssertNotEqual(verification.allResponseFields, response);
    XCTAssertEqualObjects(verification.allResponseFields, response);
}

@end
