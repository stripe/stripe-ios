//
//  STPPaymentMethodAddressTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/6/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPTestUtils.h"
#import "STPFixtures.h"

@interface STPPaymentMethodAddressTest : XCTestCase

@end

@implementation STPPaymentMethodAddressTest

- (void)testDecodedObjectFromAPIResponseRequiredFields {
    NSArray<NSString *> *requiredFields = @[];

    for (NSString *field in requiredFields) {
        NSMutableDictionary *response = [[STPTestUtils jsonNamed:STPTestJSONPaymentMethodCard][@"billing_details"][@"address"] mutableCopy];
        [response removeObjectForKey:field];
        
        XCTAssertNil([STPPaymentMethodAddress decodedObjectFromAPIResponse:response]);
    }

    XCTAssertNotNil([STPPaymentMethodAddress decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:STPTestJSONPaymentMethodCard][@"billing_details"][@"address"]]);
}

- (void)testDecodedObjectFromAPIResponseMapping {
    NSDictionary *response = [STPTestUtils jsonNamed:STPTestJSONPaymentMethodCard][@"billing_details"][@"address"];
    STPPaymentMethodAddress *address = [STPPaymentMethodAddress decodedObjectFromAPIResponse:response];
    XCTAssertEqualObjects(address.city, @"München");
    XCTAssertEqualObjects(address.country, @"DE");
    XCTAssertEqualObjects(address.postalCode, @"80337");
    XCTAssertEqualObjects(address.line1, @"Marienplatz");
    XCTAssertEqualObjects(address.line2, @"8");
    XCTAssertEqualObjects(address.state, @"Bayern");
}

@end
