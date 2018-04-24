//
//  STPSourceOwnerTest.m
//  Stripe
//
//  Created by Joey Dong on 6/23/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@import XCTest;

#import "STPSourceOwner.h"
#import "STPAddress.h"

#import "STPFixtures.h"
#import "STPTestUtils.h"

@interface STPSourceOwnerTest : XCTestCase

@end

@implementation STPSourceOwnerTest

#pragma mark - STPAPIResponseDecodable Tests

- (void)testDecodedObjectFromAPIResponseRequiredFields {
    NSArray<NSString *> *requiredFields = @[];

    for (NSString *field in requiredFields) {
        NSMutableDictionary *response = [[STPTestUtils jsonNamed:STPTestJSONSource3DS][@"owner"] mutableCopy];
        [response removeObjectForKey:field];

        XCTAssertNil([STPSourceOwner decodedObjectFromAPIResponse:response]);
    }

    XCTAssert([STPSourceOwner decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:STPTestJSONSource3DS][@"owner"]]);
}

- (void)testDecodedObjectFromAPIResponseMapping {
    NSDictionary *response = [STPTestUtils jsonNamed:STPTestJSONSource3DS][@"owner"];
    STPSourceOwner *owner = [STPSourceOwner decodedObjectFromAPIResponse:response];

    XCTAssertEqualObjects(owner.address.city, @"Pittsburgh");
    XCTAssertEqualObjects(owner.address.country, @"US");
    XCTAssertEqualObjects(owner.address.line1, @"123 Fake St");
    XCTAssertEqualObjects(owner.address.line2, @"Apt 1");
    XCTAssertEqualObjects(owner.address.postalCode, @"19219");
    XCTAssertEqualObjects(owner.address.state, @"PA");
    XCTAssertEqualObjects(owner.email, @"jenny.rosen@example.com");
    XCTAssertEqualObjects(owner.name, @"Jenny Rosen");
    XCTAssertEqualObjects(owner.phone, @"555-867-5309");
    XCTAssertEqualObjects(owner.verifiedAddress.city, @"Pittsburgh");
    XCTAssertEqualObjects(owner.verifiedAddress.country, @"US");
    XCTAssertEqualObjects(owner.verifiedAddress.line1, @"123 Fake St");
    XCTAssertEqualObjects(owner.verifiedAddress.line2, @"Apt 1");
    XCTAssertEqualObjects(owner.verifiedAddress.postalCode, @"19219");
    XCTAssertEqualObjects(owner.verifiedAddress.state, @"PA");
    XCTAssertEqualObjects(owner.verifiedEmail, @"jenny.rosen@example.com");
    XCTAssertEqualObjects(owner.verifiedName, @"Jenny Rosen");
    XCTAssertEqualObjects(owner.verifiedPhone, @"555-867-5309");

    XCTAssertNotEqual(owner.allResponseFields, response);
    XCTAssertEqualObjects(owner.allResponseFields, response);
}

@end
