//
//  STPCardParamsTest.m
//  Stripe
//
//  Created by Joey Dong on 6/19/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@import XCTest;

#import "STPCardParams.h"

@interface STPCardParamsTest : XCTestCase

@end

@implementation STPCardParamsTest

#pragma mark -

- (void)testLast4ReturnsCardNumberLast4 {
    STPCardParams *cardParams = [[STPCardParams alloc] init];
    cardParams.number = @"4242424242424242";
    XCTAssertEqualObjects(cardParams.last4, @"4242");
}

- (void)testLast4ReturnsNilWhenNoCardNumberSet {
    STPCardParams *cardParams = [[STPCardParams alloc] init];
    XCTAssertNil(cardParams.last4);
}

- (void)testLast4ReturnsNilWhenCardNumberIsLessThanLength4 {
    STPCardParams *cardParams = [[STPCardParams alloc] init];
    cardParams.number = @"123";
    XCTAssertNil(cardParams.last4);
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"

- (void)testAddress {
    STPCardParams *cardParams = [[STPCardParams alloc] init];
    cardParams.name = @"John Smith";
    cardParams.addressLine1 = @"55 John St";
    cardParams.addressLine2 = @"#3B";
    cardParams.addressCity = @"New York";
    cardParams.addressState = @"NY";
    cardParams.addressZip = @"10002";
    cardParams.addressCountry = @"US";

    STPAddress *address = cardParams.address;

    XCTAssertEqualObjects(address.name, @"John Smith");
    XCTAssertEqualObjects(address.line1, @"55 John St");
    XCTAssertEqualObjects(address.line2, @"#3B");
    XCTAssertEqualObjects(address.city, @"New York");
    XCTAssertEqualObjects(address.state, @"NY");
    XCTAssertEqualObjects(address.postalCode, @"10002");
    XCTAssertEqualObjects(address.country, @"US");
}

- (void)testSetAddress {
    STPAddress *address = [[STPAddress alloc] init];
    address.name = @"John Smith";
    address.line1 = @"55 John St";
    address.line2 = @"#3B";
    address.city = @"New York";
    address.state = @"NY";
    address.postalCode = @"10002";
    address.country = @"US";

    STPCardParams *cardParams = [[STPCardParams alloc] init];
    cardParams.address = address;

    XCTAssertEqualObjects(cardParams.name, @"John Smith");
    XCTAssertEqualObjects(cardParams.addressLine1, @"55 John St");
    XCTAssertEqualObjects(cardParams.addressLine2, @"#3B");
    XCTAssertEqualObjects(cardParams.addressCity, @"New York");
    XCTAssertEqualObjects(cardParams.addressState, @"NY");
    XCTAssertEqualObjects(cardParams.addressZip, @"10002");
    XCTAssertEqualObjects(cardParams.addressCountry, @"US");
}

#pragma clang diagnostic pop

#pragma mark - Description Tests

- (void)testDescription {
    STPCardParams *cardParams = [[STPCardParams alloc] init];
    XCTAssert(cardParams.description);
}

#pragma mark - STPFormEncodable Tests

- (void)testRootObjectName {
    XCTAssertEqualObjects([STPCardParams rootObjectName], @"card");
}

- (void)testPropertyNamesToFormFieldNamesMapping {
    STPCardParams *cardParams = [[STPCardParams alloc] init];

    NSDictionary *mapping = [STPCardParams propertyNamesToFormFieldNamesMapping];

    for (NSString *propertyName in [mapping allKeys]) {
        XCTAssertFalse([propertyName containsString:@":"]);
        XCTAssert([cardParams respondsToSelector:NSSelectorFromString(propertyName)]);
    }

    for (NSString *formFieldName in [mapping allValues]) {
        XCTAssert([formFieldName isKindOfClass:[NSString class]]);
        XCTAssert([formFieldName length] > 0);
    }

    XCTAssertEqual([[mapping allValues] count], [[NSSet setWithArray:[mapping allValues]] count]);
}

@end
