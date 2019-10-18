//
//  STPMandateCustomerAcceptanceParamsTest.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/18/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPMandateCustomerAcceptanceParams.h"

#import "STPFormEncoder.h"
#import "STPMandateOnlineParams+Private.h"

@interface STPMandateCustomerAcceptanceParamsTest : XCTestCase

@end

@implementation STPMandateCustomerAcceptanceParamsTest

- (void)testRootObjectName {
    XCTAssertEqualObjects([STPMandateCustomerAcceptanceParams rootObjectName], @"customer_acceptance");
}

- (void)testEncoding {
    STPMandateCustomerAcceptanceParams *params = [[STPMandateCustomerAcceptanceParams alloc] init];
    params.type = STPMandateCustomerAcceptanceTypeOnline;
    STPMandateOnlineParams *onlineParams = [[STPMandateOnlineParams alloc] init];
    onlineParams.inferFromClient = @YES;
    params.onlineParams = onlineParams;

    NSDictionary *paramsAsDict = [STPFormEncoder dictionaryForObject:params];
    NSDictionary *expected = @{@"customer_acceptance": @{@"type": @"online", @"online": @{@"infer_from_client": @YES}}};
    XCTAssertEqualObjects(paramsAsDict, expected);

    params.type = STPMandateCustomerAcceptanceTypeOffline;
    params.onlineParams = nil;
    paramsAsDict = [STPFormEncoder dictionaryForObject:params];
    expected = @{@"customer_acceptance": @{@"type": @"offline"}};
    XCTAssertEqualObjects(paramsAsDict, expected);
}

@end
