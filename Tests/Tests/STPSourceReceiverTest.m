//
//  STPSourceReceiverTest.m
//  Stripe
//
//  Created by Joey Dong on 6/26/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@import XCTest;

#import "STPSourceReceiver.h"

@interface STPSourceReceiverTest : XCTestCase

@end

@implementation STPSourceReceiverTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - Description Tests

- (void)testDescription {
    STPSourceReceiver *receiver = [STPSourceReceiver decodedObjectFromAPIResponse:[self completeAttributeDictionary]];
    XCTAssert(receiver.description);
}

#pragma mark - STPAPIResponseDecodable Tests

- (NSDictionary *)completeAttributeDictionary {
    // Source: https://stripe.com/docs/api#source_object
    return @{
             @"address": @"test_1MBhWS3uv4ynCfQXF3xQjJkzFPukr4K56N",
             @"amount_charged": @(300),
             @"amount_received": @(200),
             @"amount_returned": @(100),
             @"refund_attributes_method": @"email",
             @"refund_attributes_status": @"missing",
             };
}

- (void)testDecodedObjectFromAPIResponseRequiredFields {
    NSArray<NSString *> *requiredFields = @[
                                            @"address",
                                            ];

    for (NSString *field in requiredFields) {
        NSMutableDictionary *response = [[self completeAttributeDictionary] mutableCopy];
        [response removeObjectForKey:field];

        XCTAssertNil([STPSourceReceiver decodedObjectFromAPIResponse:response]);
    }

    XCTAssert([STPSourceReceiver decodedObjectFromAPIResponse:[self completeAttributeDictionary]]);
}

- (void)testDecodedObjectFromAPIResponseMapping {
    NSDictionary *response = [self completeAttributeDictionary];
    STPSourceReceiver *receiver = [STPSourceReceiver decodedObjectFromAPIResponse:response];

    XCTAssertEqualObjects(receiver.address, @"test_1MBhWS3uv4ynCfQXF3xQjJkzFPukr4K56N");
    XCTAssertEqualObjects(receiver.amountCharged, @(300));
    XCTAssertEqualObjects(receiver.amountReceived, @(200));
    XCTAssertEqualObjects(receiver.amountReturned, @(100));

    XCTAssertNotEqual(receiver.allResponseFields, response);
    XCTAssertEqualObjects(receiver.allResponseFields, response);
}

@end
