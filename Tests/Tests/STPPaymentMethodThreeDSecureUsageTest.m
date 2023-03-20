//
//  STPPaymentMethodThreeDSecureUsageTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

@import XCTest;


@interface STPPaymentMethodThreeDSecureUsageTest : XCTestCase

@end

@implementation STPPaymentMethodThreeDSecureUsageTest

- (void)testDecodedObjectFromAPIResponse {
    NSDictionary *response = @{@"supported": @YES};
    NSArray<NSString *> *requiredFields = @[@"supported"];
    
    for (NSString *field in requiredFields) {
        NSMutableDictionary *mutableResponse = [response mutableCopy];
        [mutableResponse removeObjectForKey:field];
        
        XCTAssertNil([STPPaymentMethodThreeDSecureUsage decodedObjectFromAPIResponse:mutableResponse]);
    }
    XCTAssertNotNil([STPPaymentMethodThreeDSecureUsage decodedObjectFromAPIResponse:response]);
}

@end
