//
//  STPPaymentMethodCardChecksTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

@import XCTest;

#import "STPPaymentMethodCardChecks.h"

@interface STPPaymentMethodCardChecksTest : XCTestCase

@end

@implementation STPPaymentMethodCardChecksTest

- (void)testDecodedObjectFromAPIResponse {
    NSDictionary *response = @{@"address_line1_check": [NSNull null],
                               @"address_postal_code_check": [NSNull null],
                               @"cvc_check": [NSNull null]};
    NSArray<NSString *> *requiredFields = @[];
    
    for (NSString *field in requiredFields) {
        NSMutableDictionary *mutableResponse = [response mutableCopy];
        [mutableResponse removeObjectForKey:field];
        XCTAssertNil([STPPaymentMethodCardChecks decodedObjectFromAPIResponse:mutableResponse]);
    }
    XCTAssertNotNil([STPPaymentMethodCardChecks decodedObjectFromAPIResponse:response]);
}


@end
