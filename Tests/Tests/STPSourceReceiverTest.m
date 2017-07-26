//
//  STPSourceReceiverTest.m
//  Stripe
//
//  Created by Joey Dong on 6/26/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@import XCTest;

#import "STPSourceReceiver.h"

#import "STPTestUtils.h"

@interface STPSourceReceiverTest : XCTestCase

@end

@implementation STPSourceReceiverTest

#pragma mark - Description Tests

- (void)testDescription {
    STPSourceReceiver *receiver = [STPSourceReceiver decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"BitcoinSource"][@"receiver"]];
    XCTAssert(receiver.description);
}

#pragma mark - STPAPIResponseDecodable Tests

- (void)testDecodedObjectFromAPIResponseRequiredFields {
    NSArray<NSString *> *requiredFields = @[
                                            @"address",
                                            ];

    for (NSString *field in requiredFields) {
        NSMutableDictionary *response = [[STPTestUtils jsonNamed:@"BitcoinSource"][@"receiver"] mutableCopy];
        [response removeObjectForKey:field];

        XCTAssertNil([STPSourceReceiver decodedObjectFromAPIResponse:response]);
    }

    XCTAssert([STPSourceReceiver decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"BitcoinSource"][@"receiver"]]);
}

- (void)testDecodedObjectFromAPIResponseMapping {
    NSDictionary *response = [STPTestUtils jsonNamed:@"BitcoinSource"][@"receiver"];
    STPSourceReceiver *receiver = [STPSourceReceiver decodedObjectFromAPIResponse:response];

    XCTAssertEqualObjects(receiver.address, @"test_1MBhWS3uv4ynCfQXF3xQjJkzFPukr4K56N");
    XCTAssertEqualObjects(receiver.amountCharged, @(300));
    XCTAssertEqualObjects(receiver.amountReceived, @(200));
    XCTAssertEqualObjects(receiver.amountReturned, @(100));

    XCTAssertNotEqual(receiver.allResponseFields, response);
    XCTAssertEqualObjects(receiver.allResponseFields, response);
}

@end
