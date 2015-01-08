//
//  STPAPIClientTest.m
//  Stripe
//
//  Created by Jack Flintermann on 12/19/14.
//  Copyright (c) 2014 Stripe, Inc. All rights reserved.
//

#import "STPAPIClient.h"
#import <XCTest/XCTest.h>

@interface STPAPIClientTest : XCTestCase
@end

@implementation STPAPIClientTest

- (void)testSharedClient {
    XCTAssertEqualObjects([STPAPIClient sharedClient], [STPAPIClient sharedClient]);
}

- (void)testPublishableKey {
    [Stripe setDefaultPublishableKey:@"test"];
    STPAPIClient *client = [STPAPIClient sharedClient];
    XCTAssertEqualObjects(client.publishableKey, @"test");
}

- (void)testSHA1FingerprintOfData {
    NSData *data = [@"hello" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *fingerprint = [STPAPIClient SHA1FingerprintOfData:data];
    XCTAssertEqualObjects(fingerprint, @"aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d");
}

- (void)testStringByReplacingSnakeCaseWithCamelCase {
    NSString *camelCase = [STPAPIClient stringByReplacingSnakeCaseWithCamelCase:@"test_1_2_34_test"];
    XCTAssertEqualObjects(@"test1234Test", camelCase);
}

@end
