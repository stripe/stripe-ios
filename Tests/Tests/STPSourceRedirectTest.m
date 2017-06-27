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

#pragma mark - Description Tests

- (void)testDescription {
    STPSourceRedirect *redirect = [STPSourceRedirect decodedObjectFromAPIResponse:[self completeAttributeDictionary]];
    XCTAssert(redirect.description);
}

#pragma mark - STPAPIResponseDecodable Tests

- (NSDictionary *)completeAttributeDictionary {
    // Source: https://stripe.com/docs/sources/three-d-secure
    return @{
             @"return_url": @"https://shop.example.com/crtA6B28E1",
             @"status": @"pending",
             @"url": @"https://hooks.stripe.com/redirect/authenticate/src_19YlvWAHEMiOZZp1QQlOD79v?client_secret=src_client_secret_kBwCSm6Xz5MQETiJ43hUH8qv",
             };
}

- (void)testDecodedObjectFromAPIResponseRequiredFields {
    NSArray<NSString *> *requiredFields = @[
                                            @"return_url",
                                            @"status",
                                            @"url",
                                            ];

    for (NSString *field in requiredFields) {
        NSMutableDictionary *response = [[self completeAttributeDictionary] mutableCopy];
        [response removeObjectForKey:field];

        XCTAssertNil([STPSourceRedirect decodedObjectFromAPIResponse:response]);
    }

    XCTAssert([STPSourceRedirect decodedObjectFromAPIResponse:[self completeAttributeDictionary]]);
}

- (void)testDecodedObjectFromAPIResponseMapping {
    NSDictionary *response = [self completeAttributeDictionary];
    STPSourceRedirect *redirect = [STPSourceRedirect decodedObjectFromAPIResponse:response];

    XCTAssertEqualObjects(redirect.returnURL, [NSURL URLWithString:@"https://shop.example.com/crtA6B28E1"]);
    XCTAssertEqual(redirect.status, STPSourceRedirectStatusPending);
    XCTAssertEqualObjects(redirect.url, [NSURL URLWithString:@"https://hooks.stripe.com/redirect/authenticate/src_19YlvWAHEMiOZZp1QQlOD79v?client_secret=src_client_secret_kBwCSm6Xz5MQETiJ43hUH8qv"]);

    XCTAssertNotEqual(redirect.allResponseFields, response);
    XCTAssertEqualObjects(redirect.allResponseFields, response);
}

@end
