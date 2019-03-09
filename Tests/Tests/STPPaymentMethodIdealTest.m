//
//  STPPaymentMethodIdealTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPPaymentMethodIdeal.h"

@interface STPPaymentMethodIdealTest : XCTestCase

@end

@implementation STPPaymentMethodIdealTest

- (NSDictionary *)exampleJson {
    return @{
             @"bank": @"Rabobank",
             @"bic": @"RABONL2U",
             };
}

- (void)testDecodedObjectFromAPIResponseRequiredFields {
    NSArray<NSString *> *requiredFields = @[];
    
    for (NSString *field in requiredFields) {
        NSMutableDictionary *response = [[self exampleJson] mutableCopy];
        [response removeObjectForKey:field];
        
        XCTAssertNil([STPPaymentMethodIdeal decodedObjectFromAPIResponse:response]);
    }
    
    XCTAssert([STPPaymentMethodIdeal decodedObjectFromAPIResponse:[self exampleJson]]);
}

- (void)testDecodedObjectFromAPIResponseMapping {
    NSDictionary *response = [self exampleJson];
    STPPaymentMethodIdeal *ideal = [STPPaymentMethodIdeal decodedObjectFromAPIResponse:response];
    XCTAssertEqualObjects(ideal.bank, @"Rabobank");
    XCTAssertEqualObjects(ideal.bic, @"RABONL2U");
}

@end
