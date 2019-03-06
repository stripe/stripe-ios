//
//  STPPaymentMethodBillingDetailsAddressTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/6/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPPaymentMethodBillingDetailsAddress.h"
#import "STPTestUtils.h"
#import "STPFixtures.h"

@interface STPPaymentMethodBillingDetailsAddressTest : XCTestCase

@end

@implementation STPPaymentMethodBillingDetailsAddressTest

- (void)testDecodedObjectFromAPIResponseRequiredFields {
    NSArray<NSString *> *requiredFields = @[];

    for (NSString *field in requiredFields) {
        NSMutableDictionary *response = [[STPTestUtils jsonNamed:STPTestJSONPaymentMethod][@"billing_details"][@"address"] mutableCopy];
        [response removeObjectForKey:field];
        
        XCTAssertNil([STPPaymentMethodBillingDetailsAddress decodedObjectFromAPIResponse:response]);
    }

    XCTAssertNotNil([STPPaymentMethodBillingDetailsAddress decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:STPTestJSONPaymentMethod][@"billing_details"][@"address"]]);
}

- (void)testDecodedObjectFromAPIResponseMapping {
    NSDictionary *response = [STPTestUtils jsonNamed:STPTestJSONPaymentMethod][@"billing_details"][@"address"];
    STPPaymentMethodBillingDetailsAddress *address = [STPPaymentMethodBillingDetailsAddress decodedObjectFromAPIResponse:response];
    XCTAssertEqualObjects(address.city, @"München");
    XCTAssertEqualObjects(address.country, @"DE");
    XCTAssertEqualObjects(address.postalCode, @"80337");
    XCTAssertEqualObjects(address.line1, @"Marienplatz");
    XCTAssertEqualObjects(address.line2, @"8");
    XCTAssertEqualObjects(address.state, @"Bayern");
}

@end
