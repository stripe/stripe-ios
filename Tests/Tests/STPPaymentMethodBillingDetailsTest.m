//
//  STPPaymentMethodBillingDetailsTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/6/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPPaymentMethodBillingDetails.h"
#import "STPFixtures.h"
#import "STPTestUtils.h"

@interface STPPaymentMethodBillingDetailsTest : XCTestCase

@end

@implementation STPPaymentMethodBillingDetailsTest

#pragma mark - STPAPIResponseDecodable Tests

- (void)testDecodedObjectFromAPIResponseRequiredFields {
    NSArray<NSString *> *requiredFields = @[];
    
    for (NSString *field in requiredFields) {
        NSMutableDictionary *response = [[STPTestUtils jsonNamed:STPTestJSONPaymentMethod][@"billing_details"] mutableCopy];
        [response removeObjectForKey:field];
        
        XCTAssertNil([STPPaymentMethodBillingDetails decodedObjectFromAPIResponse:response]);
    }
    
    XCTAssertNotNil([STPPaymentMethodBillingDetails decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:STPTestJSONPaymentMethod][@"billing_details"]]);
}

- (void)testDecodedObjectFromAPIResponseMapping {
    NSDictionary *response = [STPTestUtils jsonNamed:STPTestJSONPaymentMethod][@"billing_details"];
    STPPaymentMethodBillingDetails *billingDetails = [STPPaymentMethodBillingDetails decodedObjectFromAPIResponse:response];
    XCTAssertEqualObjects(billingDetails.email, @"jenny@example.com");
    XCTAssertEqualObjects(billingDetails.name, @"jenny");
    XCTAssertEqualObjects(billingDetails.phone, @"+15555555555");
    XCTAssertNotNil(billingDetails.address);
}

@end
