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
    
    XCTAssertNotNil([STPPaymentMethodCard decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:STPTestJSONPaymentMethod][@"card"]]);
}

- (void)testDecodedObjectFromAPIResponseMapping {
    NSDictionary *response = [STPTestUtils jsonNamed:STPTestJSONPaymentMethod][@"card"];
    STPPaymentMethodCard *card = [STPPaymentMethodCard decodedObjectFromAPIResponse:response];
    XCTAssertEqual(card.brand, STPCardBrandVisa);
    XCTAssertEqualObjects(card.country, @"US");
    XCTAssertNotNil(card.checks);
    XCTAssertEqual(card.expMonth, 8);
    XCTAssertEqual(card.expYear, 2020);
    XCTAssertEqualObjects(card.funding, @"credit");
    XCTAssertEqualObjects(card.last4, @"4242");
    XCTAssertEqualObjects(card.fingerprint, @"6gVyxfIhqc8Z0g0X");
    XCTAssertNotNil(card.threeDSecureUsage);
    XCTAssertEqual(card.threeDSecureUsage.supported, YES);
    XCTAssertNotNil(card.wallet);
}

@end
