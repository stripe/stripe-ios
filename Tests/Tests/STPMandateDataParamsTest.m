//
//  STPMandateDataParamsTest.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/18/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPMandateDataParams.h"

#import "STPFormEncoder.h"
#import "STPMandateCustomerAcceptanceParams.h"
#import "STPMandateOnlineParams+Private.h"

@interface STPMandateDataParamsTest : XCTestCase

@end

@implementation STPMandateDataParamsTest

- (void)testRootObjectName {
    XCTAssertEqualObjects([STPMandateDataParams rootObjectName], @"mandate_data");
}

- (void)testEncoding {
    STPMandateCustomerAcceptanceParams *customerAcceptanceParams = [[STPMandateCustomerAcceptanceParams alloc] init];
    customerAcceptanceParams.type = STPMandateCustomerAcceptanceTypeOnline;
    STPMandateOnlineParams *onlineParams = [[STPMandateOnlineParams alloc] init];
    onlineParams.inferFromClient = @YES;
    customerAcceptanceParams.onlineParams = onlineParams;

    STPMandateDataParams *params = [[STPMandateDataParams alloc] init];
    params.customerAcceptance = customerAcceptanceParams;

    NSDictionary *paramsAsDict = [STPFormEncoder dictionaryForObject:params];
    NSDictionary *expected = @{@"mandate_data": @{@"customer_acceptance": @{@"type": @"online", @"online": @{@"infer_from_client": @YES}}}};
    XCTAssertEqualObjects(paramsAsDict, expected);
}

@end
