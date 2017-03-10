//
//  STPSourceParamsTest.m
//  Stripe
//
//  Created by Ben Guo on 1/25/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Stripe.h"

@interface STPSourceParamsTest : XCTestCase

@end

@implementation STPSourceParamsTest

- (void)testCardParamsWithCard {
    STPCardParams *card = [STPCardParams new];
    card.number = @"4242 4242 4242 4242";
    card.cvc = @"123";
    card.expMonth = 6;
    card.expYear = 2018;
    card.currency = @"usd";
    card.name = @"Jenny Rosen";
    card.addressLine1 = @"123 Fake Street";
    card.addressLine2 = @"Apartment 4";
    card.addressCity = @"New York";
    card.addressState = @"NY";
    card.addressCountry = @"USA";
    card.addressZip = @"10002";

    STPSourceParams *source = [STPSourceParams cardParamsWithCard:card];
    NSDictionary *sourceCard = source.additionalAPIParameters[@"card"];
    XCTAssertEqual(sourceCard[@"number"], card.number);
    XCTAssertEqual(sourceCard[@"cvc"], card.cvc);
    XCTAssertEqual(sourceCard[@"exp_month"], @(card.expMonth));
    XCTAssertEqual(sourceCard[@"exp_year"], @(card.expYear));
    XCTAssertEqualObjects(source.owner[@"name"], card.name);
    NSDictionary *sourceAddress = source.owner[@"address"];
    XCTAssertEqualObjects(sourceAddress[@"line1"], card.addressLine1);
    XCTAssertEqualObjects(sourceAddress[@"line2"], card.addressLine2);
    XCTAssertEqualObjects(sourceAddress[@"city"], card.addressCity);
    XCTAssertEqualObjects(sourceAddress[@"state"], card.addressState);
    XCTAssertEqualObjects(sourceAddress[@"postal_code"], card.addressZip);
    XCTAssertEqualObjects(sourceAddress[@"country"], card.addressCountry);
}

@end
