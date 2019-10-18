//
//  STPMandateOnlineParamsTest.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/18/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPMandateOnlineParams+Private.h"

#import "STPFormEncoder.h"

@interface STPMandateOnlineParamsTest : XCTestCase

@end

@implementation STPMandateOnlineParamsTest

- (void)testRootObjectName {
    XCTAssertEqualObjects([STPMandateOnlineParams rootObjectName], @"online");
}

- (void)testEncoding {
    STPMandateOnlineParams *params = [[STPMandateOnlineParams alloc] init];
    params.ipAddress = @"test_ip_address";
    params.userAgent = @"a_user_agent";
    NSDictionary *paramsAsDict = [STPFormEncoder dictionaryForObject:params];
    NSDictionary *expected = @{@"online": @{@"ip_address": @"test_ip_address", @"user_agent": @"a_user_agent"}};
    XCTAssertEqualObjects(paramsAsDict, expected);

    params = [[STPMandateOnlineParams alloc] init];
    params.inferFromClient = @YES;
    paramsAsDict = [STPFormEncoder dictionaryForObject:params];
    expected = @{@"online": @{@"infer_from_client": @YES}};
    XCTAssertEqualObjects(paramsAsDict, expected);
}

@end
