//
//  STPPaymentMethodCardTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/6/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPPaymentMethodCard.h"
#import "STPFixtures.h"
#import "STPTestUtils.h"

@interface STPPaymentMethodCardTest : XCTestCase

@end

@implementation STPPaymentMethodCardTest

- (void)testDecodedObjectFromAPIResponseRequiredFields {
    NSArray<NSString *> *requiredFields = @[];
    
    for (NSString *field in requiredFields) {
        NSMutableDictionary *response = [[STPTestUtils jsonNamed:STPTestJSONPaymentMethod][@"card"] mutableCopy];
        [response removeObjectForKey:field];
        
        XCTAssertNil([STPPaymentMethodCard decodedObjectFromAPIResponse:response]);
    }
    
    XCTAssert([STPPaymentMethodCard decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:STPTestJSONPaymentMethod][@"card"]]);
}

- (void)testDecodedObjectFromAPIResponseMapping {
    NSDictionary *response = [STPTestUtils jsonNamed:STPTestJSONPaymentMethod][@"card"];
    STPPaymentMethodCard *card = [STPPaymentMethodCard decodedObjectFromAPIResponse:response];
    XCTAssertEqualObjects(card.brand, @"visa");
    XCTAssertEqualObjects(card.country, @"US");
    XCTAssertNotNil(card.checks);
    XCTAssertEqual(card.expMonth, 8);
    XCTAssertEqual(card.expYear, 2020);
    XCTAssertEqualObjects(card.funding, @"credit");
    XCTAssertEqualObjects(card.last4, @"4242");
    XCTAssertNotNil(card.threeDSecureUsage);
    XCTAssertEqual(card.threeDSecureUsage.supported, YES);
}

@end
