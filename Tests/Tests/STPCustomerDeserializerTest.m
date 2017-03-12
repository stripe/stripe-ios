//
//  STPCustomerDeserializerTest.m
//  Stripe
//
//  Created by Ben Guo on 7/14/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPCustomer.h"
#import "StripeError.h"
#import "STPTestUtils.h"
#import "STPSourceProtocol.h"

@interface STPCustomerDeserializerTest : XCTestCase
@end

@implementation STPCustomerDeserializerTest

- (void)testInitWithData_error {
    NSError *error = [NSError stp_genericFailedToParseResponseError];
    STPCustomerDeserializer *sut = [[STPCustomerDeserializer alloc] initWithData:nil
                                                                     urlResponse:nil
                                                                           error:error];
    XCTAssertNil(sut.customer);
    XCTAssertEqualObjects(sut.error, error);
}

- (void)testInitWithData_invalidData {
    STPCustomerDeserializer *sut = [[STPCustomerDeserializer alloc] initWithData:[NSData new]
                                                                     urlResponse:nil
                                                                           error:nil];
    XCTAssertNil(sut.customer);
    XCTAssertNotNil(sut.error);
}

- (void)testInitWithData_validData {
    NSDictionary *customer = [STPTestUtils jsonNamed:@"Customer"];
    NSData *data = [NSJSONSerialization dataWithJSONObject:customer options:(NSJSONWritingOptions)kNilOptions error:nil];
    STPCustomerDeserializer *sut = [[STPCustomerDeserializer alloc] initWithData:data
                                                                     urlResponse:nil
                                                                           error:nil];
    XCTAssertNotNil(sut.customer);
    XCTAssertNil(sut.error);
    XCTAssertEqualObjects(sut.customer.stripeID, customer[@"id"]);
}

- (void)testInitWithJSONResponse_invalidJSON {
    id json = [NSObject new];
    STPCustomerDeserializer *sut = [[STPCustomerDeserializer alloc] initWithJSONResponse:json];

    XCTAssertNil(sut.customer);
    XCTAssertEqualObjects(sut.error, [NSError stp_genericFailedToParseResponseError]);
}

- (void)testInitWithJSONResponse_validJSON {
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

    STPCustomerDeserializer *sut = [[STPCustomerDeserializer alloc] initWithJSONResponse:customer];
    XCTAssertNotNil(sut.customer);
    XCTAssertNil(sut.error);
    XCTAssertEqualObjects(sut.customer.stripeID, customer[@"id"]);
    XCTAssertTrue(sut.customer.sources.count == 4);
    XCTAssertEqualObjects(sut.customer.sources[0].stripeID, card1[@"id"]);
    XCTAssertEqualObjects(sut.customer.sources[1].stripeID, card2[@"id"]);
    XCTAssertEqualObjects(sut.customer.defaultSource.stripeID, card1[@"id"]);
    XCTAssertEqualObjects(sut.customer.sources[2].stripeID, cardSource[@"id"]);
    XCTAssertEqualObjects(sut.customer.sources[3].stripeID, threeDSSource[@"id"]);
}

@end
