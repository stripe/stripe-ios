//
//  STPSourceCardDetailsTest.m
//  Stripe
//
//  Created by Joey Dong on 6/21/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@import XCTest;

#import "STPSourceCardDetails.h"
#import "STPSourceCardDetails+Private.h"

#import "STPTestUtils.h"

@interface STPSourceCardDetails ()

+ (STPSourceCard3DSecureStatus)threeDSecureStatusFromString:(NSString *)string;
+ (NSString *)stringFromThreeDSecureStatus:(STPSourceCard3DSecureStatus)threeDSecureStatus;

@end

@interface STPSourceCardDetailsTest : XCTestCase

@end

@implementation STPSourceCardDetailsTest

#pragma mark - STPSourceCard3DSecureStatus Tests

- (void)testThreeDSecureStatusFromString {
    XCTAssertEqual([STPSourceCardDetails threeDSecureStatusFromString:@"required"], STPSourceCard3DSecureStatusRequired);
    XCTAssertEqual([STPSourceCardDetails threeDSecureStatusFromString:@"REQUIRED"], STPSourceCard3DSecureStatusRequired);

    XCTAssertEqual([STPSourceCardDetails threeDSecureStatusFromString:@"optional"], STPSourceCard3DSecureStatusOptional);
    XCTAssertEqual([STPSourceCardDetails threeDSecureStatusFromString:@"OPTIONAL"], STPSourceCard3DSecureStatusOptional);

    XCTAssertEqual([STPSourceCardDetails threeDSecureStatusFromString:@"not_supported"], STPSourceCard3DSecureStatusNotSupported);
    XCTAssertEqual([STPSourceCardDetails threeDSecureStatusFromString:@"NOT_SUPPORTED"], STPSourceCard3DSecureStatusNotSupported);
    
    XCTAssertEqual([STPSourceCardDetails threeDSecureStatusFromString:@"recommended"], STPSourceCard3DSecureStatusRecommended);
    XCTAssertEqual([STPSourceCardDetails threeDSecureStatusFromString:@"RECOMMENDED"], STPSourceCard3DSecureStatusRecommended);

    XCTAssertEqual([STPSourceCardDetails threeDSecureStatusFromString:@"unknown"], STPSourceCard3DSecureStatusUnknown);
    XCTAssertEqual([STPSourceCardDetails threeDSecureStatusFromString:@"UNKNOWN"], STPSourceCard3DSecureStatusUnknown);

    XCTAssertEqual([STPSourceCardDetails threeDSecureStatusFromString:@"garbage"], STPSourceCard3DSecureStatusUnknown);
    XCTAssertEqual([STPSourceCardDetails threeDSecureStatusFromString:@"GARBAGE"], STPSourceCard3DSecureStatusUnknown);
}

- (void)testStringFromThreeDSecureStatus {
    NSArray<NSNumber *> *values = @[
                                    @(STPSourceCard3DSecureStatusRequired),
                                    @(STPSourceCard3DSecureStatusOptional),
                                    @(STPSourceCard3DSecureStatusNotSupported),
                                    @(STPSourceCard3DSecureStatusRecommended),
                                    @(STPSourceCard3DSecureStatusUnknown),
                                    ];

    for (NSNumber *threeDSecureStatusNumber in values) {
        STPSourceCard3DSecureStatus threeDSecureStatus = (STPSourceCard3DSecureStatus)[threeDSecureStatusNumber integerValue];
        NSString *string = [STPSourceCardDetails stringFromThreeDSecureStatus:threeDSecureStatus];

        switch (threeDSecureStatus) {
            case STPSourceCard3DSecureStatusRequired:
                XCTAssertEqualObjects(string, @"required");
                break;
            case STPSourceCard3DSecureStatusOptional:
                XCTAssertEqualObjects(string, @"optional");
                break;
            case STPSourceCard3DSecureStatusNotSupported:
                XCTAssertEqualObjects(string, @"not_supported");
                break;
            case STPSourceCard3DSecureStatusRecommended:
                XCTAssertEqualObjects(string, @"recommended");
                break;
            case STPSourceCard3DSecureStatusUnknown:
                XCTAssertNil(string);
                break;
        }
    }
}

#pragma mark - Description Tests

- (void)testDescription {
    STPSourceCardDetails *cardDetails = [STPSourceCardDetails decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"CardSource"][@"card"]];
    XCTAssert(cardDetails.description);
}

#pragma mark - STPAPIResponseDecodable Tests

- (void)testDecodedObjectFromAPIResponseRequiredFields {
    NSArray<NSString *> *requiredFields = @[];

    for (NSString *field in requiredFields) {
        NSMutableDictionary *response = [[STPTestUtils jsonNamed:@"CardSource"][@"card"] mutableCopy];
        [response removeObjectForKey:field];

        XCTAssertNil([STPSourceCardDetails decodedObjectFromAPIResponse:response]);
    }

    XCTAssert([STPSourceCardDetails decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"CardSource"][@"card"]]);
}

- (void)testDecodedObjectFromAPIResponseMapping {
    NSDictionary *response = [STPTestUtils jsonNamed:@"CardSource"][@"card"];
    STPSourceCardDetails *cardDetails = [STPSourceCardDetails decodedObjectFromAPIResponse:response];

    XCTAssertEqual(cardDetails.brand, STPCardBrandVisa);
    XCTAssertEqualObjects(cardDetails.country, @"US");
    XCTAssertEqual(cardDetails.expMonth, (NSUInteger)12);
    XCTAssertEqual(cardDetails.expYear, (NSUInteger)2034);
    XCTAssertEqual(cardDetails.funding, STPCardFundingTypeDebit);
    XCTAssertEqualObjects(cardDetails.last4, @"5556");
    XCTAssertEqual(cardDetails.threeDSecure, STPSourceCard3DSecureStatusNotSupported);

    XCTAssertNotEqual(cardDetails.allResponseFields, response);
    XCTAssertEqualObjects(cardDetails.allResponseFields, response);
}

@end
