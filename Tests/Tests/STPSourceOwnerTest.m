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

@interface STPSourceOwnerTest : XCTestCase

@end

@implementation STPSourceOwnerTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - STPAPIResponseDecodable Tests

- (NSDictionary *)completeAttributeDictionary {
    // Source: https://stripe.com/docs/api#source_object
    return @{
             @"address": @{
                     @"city": @"Pittsburgh",
                     @"country": @"US",
                     @"line1": @"123 Fake St",
                     @"line2": @"Apt 1",
                     @"postal_code": @"19219",
                     @"state": @"PA",
                     },
             @"email": @"jenny.rosen@example.com",
             @"name": @"Jenny Rosen",
             @"phone": @"555-867-5309",
             @"verified_address": @{
                     @"city": @"Pittsburgh",
                     @"country": @"US",
                     @"line1": @"123 Fake St",
                     @"line2": @"Apt 1",
                     @"postal_code": @"19219",
                     @"state": @"PA",
                     },
             @"verified_email": @"jenny.rosen@example.com",
             @"verified_name": @"Jenny Rosen",
             @"verified_phone": @"555-867-5309",
             };
}

- (void)testDecodedObjectFromAPIResponseRequiredFields {
    NSArray<NSString *> *requiredFields = @[];

    for (NSString *field in requiredFields) {
        NSMutableDictionary *response = [[self completeAttributeDictionary] mutableCopy];
        [response removeObjectForKey:field];

        XCTAssertNil([STPSourceOwner decodedObjectFromAPIResponse:response]);
    }

    XCTAssert([STPSourceOwner decodedObjectFromAPIResponse:[self completeAttributeDictionary]]);
}

- (void)testDecodedObjectFromAPIResponseMapping {
    NSDictionary *response = [self completeAttributeDictionary];
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
