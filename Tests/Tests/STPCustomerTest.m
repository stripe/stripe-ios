//
//  STPCustomerTest.m
//  Stripe
//
//  Created by Ben Guo on 7/14/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>



#import "STPTestUtils.h"

@interface STPCustomerTest : XCTestCase
@end

@implementation STPCustomerTest

- (void)testDecoding_invalidJSON {
    STPCustomer *sut = [STPCustomer decodedObjectFromAPIResponse:@{}];
    XCTAssertNil(sut);
}

- (void)testDecoding_validJSON {
    NSMutableDictionary *card1 = [[STPTestUtils jsonNamed:@"Card"] mutableCopy];
    card1[@"id"] = @"card_123";

    NSMutableDictionary *card2 = [[STPTestUtils jsonNamed:@"Card"] mutableCopy];
    card2[@"id"] = @"card_456";

    NSMutableDictionary *applePayCard1 = [[STPTestUtils jsonNamed:@"Card"] mutableCopy];
    applePayCard1[@"id"] = @"card_apple_pay1";
    applePayCard1[@"tokenization_method"] = @"apple_pay";

    NSMutableDictionary *applePayCard2 = [applePayCard1 mutableCopy];
    applePayCard2[@"id"] = @"card_apple_pay2";

    NSDictionary *cardSource = [STPTestUtils jsonNamed:@"CardSource"];
    NSDictionary *threeDSSource = [STPTestUtils jsonNamed:@"3DSSource"];

    NSMutableDictionary *customer = [[STPTestUtils jsonNamed:@"Customer"] mutableCopy];
    NSMutableDictionary *sources = [customer[@"sources"] mutableCopy];
    sources[@"data"] = @[applePayCard1, card1, applePayCard2, card2, cardSource, threeDSSource];
    customer[@"default_source"] = card1[@"id"];
    customer[@"sources"] = sources;

    STPCustomer *sut = [STPCustomer decodedObjectFromAPIResponse:customer];
    XCTAssertNotNil(sut);
    XCTAssertEqualObjects(sut.stripeID, customer[@"id"]);
    XCTAssertTrue(sut.sources.count == 4);
    XCTAssertEqualObjects(sut.sources[0].stripeID, card1[@"id"]);
    XCTAssertEqualObjects(sut.sources[1].stripeID, card2[@"id"]);
    XCTAssertEqualObjects(sut.defaultSource.stripeID, card1[@"id"]);
    XCTAssertEqualObjects(sut.sources[2].stripeID, cardSource[@"id"]);
    XCTAssertEqualObjects(sut.sources[3].stripeID, threeDSSource[@"id"]);

    XCTAssertEqualObjects(sut.shippingAddress.name, customer[@"shipping"][@"name"]);
    XCTAssertEqualObjects(sut.shippingAddress.phone, customer[@"shipping"][@"phone"]);
    XCTAssertEqualObjects(sut.shippingAddress.city, customer[@"shipping"][@"address"][@"city"]);
    XCTAssertEqualObjects(sut.shippingAddress.country, customer[@"shipping"][@"address"][@"country"]);
    XCTAssertEqualObjects(sut.shippingAddress.line1, customer[@"shipping"][@"address"][@"line1"]);
    XCTAssertEqualObjects(sut.shippingAddress.line2, customer[@"shipping"][@"address"][@"line2"]);
    XCTAssertEqualObjects(sut.shippingAddress.postalCode, customer[@"shipping"][@"address"][@"postal_code"]);
    XCTAssertEqualObjects(sut.shippingAddress.state, customer[@"shipping"][@"address"][@"state"]);
}

@end
