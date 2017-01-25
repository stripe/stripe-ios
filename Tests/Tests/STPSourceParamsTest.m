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
    NSDictionary *sourceAddress = source.owner[@"address"];
    XCTAssertEqual(sourceAddress[@"line1"], card.addressLine1);
    XCTAssertEqual(sourceAddress[@"line2"], card.addressLine2);
    XCTAssertEqual(sourceAddress[@"city"], card.addressCity);
    XCTAssertEqual(sourceAddress[@"state"], card.addressState);
    XCTAssertEqual(sourceAddress[@"postal_code"], card.addressZip);
    XCTAssertEqual(sourceAddress[@"country"], card.addressCountry);
}

@end
