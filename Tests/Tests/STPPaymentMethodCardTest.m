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

@interface STPPaymentMethodCard (Testing)
+ (STPCardBrand)brandFromString:(NSString *)string;
@end

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

- (void)testBrandFromString {
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"visa"], STPCardBrandVisa);
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"VISA"], STPCardBrandVisa);
    
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"amex"], STPCardBrandAmex);
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"AMEX"], STPCardBrandAmex);
    
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"mastercard"], STPCardBrandMasterCard);
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"MASTERCARD"], STPCardBrandMasterCard);
    
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"discover"], STPCardBrandDiscover);
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"DISCOVER"], STPCardBrandDiscover);
    
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"jcb"], STPCardBrandJCB);
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"JCB"], STPCardBrandJCB);
    
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"diners"], STPCardBrandDinersClub);
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"DINERS"], STPCardBrandDinersClub);
    
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"unionpay"], STPCardBrandUnionPay);
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"UNIONPAY"], STPCardBrandUnionPay);
    
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"unknown"], STPCardBrandUnknown);
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"UNKNOWN"], STPCardBrandUnknown);
    
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"garbage"], STPCardBrandUnknown);
    XCTAssertEqual([STPPaymentMethodCard brandFromString:@"GARBAGE"], STPCardBrandUnknown);
}

@end
