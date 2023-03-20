//
//  STPSourceRedirectTest.m
//  Stripe
//
//  Created by Joey Dong on 6/21/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@import XCTest;


#import "STPTestUtils.h"

@interface STPSourceRedirect ()

+ (STPSourceRedirectStatus)statusFromString:(NSString *)string;
+ (NSString *)stringFromStatus:(STPSourceRedirectStatus)status;

@end

@interface STPSourceRedirectTest : XCTestCase

@end

@implementation STPSourceRedirectTest

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

    XCTAssertEqual([STPSourceRedirect statusFromString:@"not_required"], STPSourceRedirectStatusNotRequired);
    XCTAssertEqual([STPSourceRedirect statusFromString:@"NOT_REQUIRED"], STPSourceRedirectStatusNotRequired);
    
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
            case STPSourceRedirectStatusNotRequired:
                XCTAssertEqualObjects(string, @"not_required");
                break;
            case STPSourceRedirectStatusUnknown:
                XCTAssertNil(string);
                break;
        }
    }
}

#pragma mark - Description Tests

- (void)testDescription {
    STPSourceRedirect *redirect = [STPSourceRedirect decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"3DSSource"][@"redirect"]];
    XCTAssert(redirect.description);
}

#pragma mark - STPAPIResponseDecodable Tests

- (void)testDecodedObjectFromAPIResponseRequiredFields {
    NSArray<NSString *> *requiredFields = @[
                                            @"return_url",
                                            @"status",
                                            @"url",
                                            ];

    for (NSString *field in requiredFields) {
        NSMutableDictionary *response = [[STPTestUtils jsonNamed:@"3DSSource"][@"redirect"] mutableCopy];
        [response removeObjectForKey:field];

        XCTAssertNil([STPSourceRedirect decodedObjectFromAPIResponse:response]);
    }

    XCTAssert([STPSourceRedirect decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"3DSSource"][@"redirect"]]);
}

- (void)testDecodedObjectFromAPIResponseMapping {
    NSDictionary *response = [STPTestUtils jsonNamed:@"3DSSource"][@"redirect"];
    STPSourceRedirect *redirect = [STPSourceRedirect decodedObjectFromAPIResponse:response];

    XCTAssertEqualObjects(redirect.returnURL, [NSURL URLWithString:@"exampleappschema://stripe_callback"]);
    XCTAssertEqual(redirect.status, STPSourceRedirectStatusPending);
    XCTAssertEqualObjects(redirect.url, [NSURL URLWithString:@"https://hooks.stripe.com/redirect/authenticate/src_19YlvWAHEMiOZZp1QQlOD79v?client_secret=src_client_secret_kBwCSm6Xz5MQETiJ43hUH8qv"]);

    XCTAssertNotEqual(redirect.allResponseFields, response);
    XCTAssertEqualObjects(redirect.allResponseFields, response);
}

@end
