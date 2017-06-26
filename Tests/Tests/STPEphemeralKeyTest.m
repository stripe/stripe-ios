//
//  STPEphemeralKeyTest.m
//  Stripe
//
//  Created by Ben Guo on 5/17/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPEphemeralKey.h"
#import "STPTestUtils.h"

@interface STPEphemeralKeyTest : XCTestCase

@end

@implementation STPEphemeralKeyTest

- (void)testDecoding {
    NSDictionary *json = [STPTestUtils jsonNamed:@"EphemeralKey"];
    STPEphemeralKey *key = [STPEphemeralKey decodedObjectFromAPIResponse:json];
    XCTAssertNotNil(key);
    XCTAssertEqualObjects(key.stripeID, json[@"id"]);
    XCTAssertEqualObjects(key.secret, json[@"secret"]);
    XCTAssertEqualObjects(key.created, [NSDate dateWithTimeIntervalSince1970:[json[@"created"] doubleValue]]);
    XCTAssertEqualObjects(key.expires, [NSDate dateWithTimeIntervalSince1970:[json[@"expires"] doubleValue]]);
    XCTAssertEqual(key.livemode, [json[@"livemode"] boolValue]);
    XCTAssertEqualObjects(key.customerID, @"cus_123");
}

@end
