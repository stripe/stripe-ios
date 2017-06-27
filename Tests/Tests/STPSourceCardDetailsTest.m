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

@interface STPSourceCardDetailsTest : XCTestCase

@end

@implementation STPSourceCardDetailsTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - STPSourceCard3DSecureStatus Tests

- (void)testThreeDSecureStatusFromString {
    XCTAssertEqual([STPSourceCardDetails threeDSecureStatusFromString:@"required"], STPSourceCard3DSecureStatusRequired);
    XCTAssertEqual([STPSourceCardDetails threeDSecureStatusFromString:@"REQUIRED"], STPSourceCard3DSecureStatusRequired);

    XCTAssertEqual([STPSourceCardDetails threeDSecureStatusFromString:@"optional"], STPSourceCard3DSecureStatusOptional);
    XCTAssertEqual([STPSourceCardDetails threeDSecureStatusFromString:@"OPTIONAL"], STPSourceCard3DSecureStatusOptional);

    XCTAssertEqual([STPSourceCardDetails threeDSecureStatusFromString:@"not_supported"], STPSourceCard3DSecureStatusNotSupported);
    XCTAssertEqual([STPSourceCardDetails threeDSecureStatusFromString:@"NOT_SUPPORTED"], STPSourceCard3DSecureStatusNotSupported);

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
            case STPSourceCard3DSecureStatusUnknown:
                XCTAssertNil(string);
                break;
        }
    }
}

#pragma mark - Description Tests

- (void)testDescription {
    STPSourceCardDetails *cardDetails = [STPSourceCardDetails decodedObjectFromAPIResponse:[self completeAttributeDictionary]];
    XCTAssert(cardDetails.description);
}

#pragma mark - STPAPIResponseDecodable Tests

- (NSDictionary *)completeAttributeDictionary {
    return @{
             @"brand": @"Visa",
             @"country": @"US",
             @"exp_month": @(12),
             @"exp_year": @(2034),
             @"funding": @"debit",
             @"last4": @"5556",
             @"three_d_secure": @"not_supported",
             };
}

- (void)testDecodedObjectFromAPIResponseRequiredFields {
    NSArray<NSString *> *requiredFields = @[];

    for (NSString *field in requiredFields) {
        NSMutableDictionary *response = [[self completeAttributeDictionary] mutableCopy];
        [response removeObjectForKey:field];

        XCTAssertNil([STPSourceCardDetails decodedObjectFromAPIResponse:response]);
    }

    XCTAssert([STPSourceCardDetails decodedObjectFromAPIResponse:[self completeAttributeDictionary]]);
}

- (void)testDecodedObjectFromAPIResponseMapping {
    NSDictionary *response = [self completeAttributeDictionary];
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
