//
//  STPPaymentMethodFPXTest.m
//  StripeiOS Tests
//
//  Created by David Estes on 8/26/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface STPPaymentMethodFPXTest : XCTestCase

@end

@implementation STPPaymentMethodFPXTest

- (NSDictionary *)exampleJson {
    return @{
             @"bank": @"maybank2u",
             };
}

- (void)testDecodedObjectFromAPIResponseRequiredFields {
    NSArray<NSString *> *requiredFields = @[];
    
    for (NSString *field in requiredFields) {
        NSMutableDictionary *response = [[self exampleJson] mutableCopy];
        [response removeObjectForKey:field];
        
        XCTAssertNil([STPPaymentMethodFPX decodedObjectFromAPIResponse:response]);
    }
    
    XCTAssert([STPPaymentMethodFPX decodedObjectFromAPIResponse:[self exampleJson]]);
}

- (void)testDecodedObjectFromAPIResponseMapping {
    NSDictionary *response = [self exampleJson];
    STPPaymentMethodFPX *fpx = [STPPaymentMethodFPX decodedObjectFromAPIResponse:response];
    XCTAssertEqualObjects(fpx.bankIdentifierCode, @"maybank2u");
}

@end
