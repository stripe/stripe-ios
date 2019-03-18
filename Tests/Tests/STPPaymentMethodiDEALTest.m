//
//  STPPaymentMethodiDEALTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPPaymentMethodIdeal.h"

@interface STPPaymentMethodiDEALTest : XCTestCase

@end

@implementation STPPaymentMethodiDEALTest

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
        
        XCTAssertNil([STPPaymentMethodiDEAL decodedObjectFromAPIResponse:response]);
    }
    
    XCTAssert([STPPaymentMethodiDEAL decodedObjectFromAPIResponse:[self exampleJson]]);
}

- (void)testDecodedObjectFromAPIResponseMapping {
    NSDictionary *response = [self exampleJson];
    STPPaymentMethodiDEAL *ideal = [STPPaymentMethodiDEAL decodedObjectFromAPIResponse:response];
    XCTAssertEqualObjects(ideal.bankName, @"Rabobank");
    XCTAssertEqualObjects(ideal.bankIdentifierCode, @"RABONL2U");
}

@end
