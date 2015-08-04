//
//  STPAPIClientTest.m
//  Stripe
//
//  Created by Jack Flintermann on 12/19/14.
//  Copyright (c) 2014 Stripe, Inc. All rights reserved.
//

@import XCTest;

#import "STPAPIClient.h"

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

@end
