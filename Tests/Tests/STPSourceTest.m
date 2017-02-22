//
//  STPSourceTest.m
//  Stripe
//
//  Created by Ben Guo on 1/24/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@import XCTest;

#import "Stripe.h"

@interface STPSourceTest : XCTestCase

@end

@implementation STPSourceTest

- (NSDictionary *)buildTestResponse_ideal {
    NSDictionary *dict = @{
                           @"id": @"src_123",
                           @"object": @"source",
                           @"amount": @1099,
                           @"client_secret": @"src_client_secret_123",
                           @"created": @1445277809,
                           @"currency": @"eur",
                           @"flow": @"redirect",
                           @"livemode": @YES,
                           @"owner": @{
                                   @"address": [NSNull null],
                                   @"email": [NSNull null],
                                   @"name": @"Jenny Rosen",
                                   @"phone": [NSNull null],
                                   @"verified_address": [NSNull null],
                                   @"verified_email": [NSNull null],
                                   @"verified_name": @"Jenny Rosen",
                                   @"verified_phone": [NSNull null],
                                   },
                           @"redirect": @{
                                   @"return_url": @"https://shop.foo.com/crtABC",
                                   @"status": @"pending",
                                   @"url": @"https://pay.stripe.com/redirect/src_123?client_secret=src_client_secret_123"
                                   },
                           @"status": @"pending",
                           @"type": @"ideal",
                           @"usage": @"single_use",
                           @"ideal": @{
                                   @"bank": @"ing"
                                   }
                           };
    return dict;
}

- (NSDictionary *)buildTestResponse_sepa_debit {
    NSDictionary *dict = @{
                           @"id": @"src_123",
                           @"object": @"source",
                           @"amount": [NSNull null],
                           @"client_secret": @"src_client_secret_123",
                           @"created": @1445277809,
                           @"currency": @"eur",
                           @"flow": @"none",
                           @"livemode": @NO,
                           @"owner": @{
                                   @"address": @{
                                           @"city": @"Berlin",
                                           @"country": @"DE",
                                           @"line1": @"Nollendorfstraße 27",
                                           @"line2": [NSNull null],
                                           @"postal_code": @"10777",
                                           @"state": [NSNull null]
                                           },
                                   @"email": [NSNull null],
                                   @"name": @"Jenny Rosen",
                                   @"phone": [NSNull null],
                                   @"verified_address": [NSNull null],
                                   @"verified_email": [NSNull null],
                                   @"verified_name": [NSNull null],
                                   @"verified_phone": [NSNull null],
                                   },
                           @"status": @"chargeable",
                           @"type": @"sepa_debit",
                           @"usage": @"reusable",
                           @"sepa_debit": @{
                                   @"bank_code": @37040044,
                                   @"country": @"DE",
                                   @"fingerprint": @"NxdSyRegc9PsMkWy",
                                   @"last4": @3001,
                                   @"mandate_reference": @"NXDSYREGC9PSMKWY",
                                   @"mandate_url": @"https://hooks.stripe.com/adapter/sepa_debit/file/src_123/src_client_secret_123"
                                   }
                           };
    return dict;
}

- (void)testDecodingSource_ideal {
    NSDictionary *response = [self buildTestResponse_ideal];
    STPSource *source = [STPSource decodedObjectFromAPIResponse:response];
    XCTAssertEqualObjects(source.stripeID, @"src_123");
    XCTAssertEqualObjects(source.amount, @1099);
    XCTAssertEqualObjects(source.clientSecret, @"src_client_secret_123");
    XCTAssertEqualWithAccuracy([source.created timeIntervalSince1970], 1445277809.0, 1.0);
    XCTAssertEqualObjects(source.currency, @"eur");
    XCTAssertEqual(source.flow, STPSourceFlowRedirect);
    XCTAssertEqual(source.livemode, YES);
    XCTAssertEqualObjects(source.owner.name, @"Jenny Rosen");
    XCTAssertEqualObjects(source.owner.verifiedName, @"Jenny Rosen");
    XCTAssertEqual(source.redirect.status, STPSourceRedirectStatusPending);
    XCTAssertEqualObjects(source.redirect.returnURL, [NSURL URLWithString:@"https://shop.foo.com/crtABC"]);
    XCTAssertEqualObjects(source.redirect.url, [NSURL URLWithString:@"https://pay.stripe.com/redirect/src_123?client_secret=src_client_secret_123"]);
    XCTAssertEqual(source.status, STPSourceStatusPending);
    XCTAssertEqual(source.type, STPSourceTypeIDEAL);
    XCTAssertEqual(source.usage, STPSourceUsageSingleUse);
    XCTAssertEqualObjects(source.details, response[@"ideal"]);
}

- (void)testDecodingSource_sepa_debit {
    NSDictionary *response = [self buildTestResponse_sepa_debit];
    STPSource *source = [STPSource decodedObjectFromAPIResponse:response];
    XCTAssertEqualObjects(source.stripeID, @"src_123");
    XCTAssertNil(source.amount);
    XCTAssertEqualObjects(source.clientSecret, @"src_client_secret_123");
    XCTAssertEqualWithAccuracy([source.created timeIntervalSince1970], 1445277809.0, 1.0);
    XCTAssertEqualObjects(source.currency, @"eur");
    XCTAssertEqual(source.flow, STPSourceFlowNone);
    XCTAssertEqual(source.livemode, NO);
    XCTAssertEqualObjects(source.owner.name, @"Jenny Rosen");
    XCTAssertEqualObjects(source.owner.address.city, @"Berlin");
    XCTAssertEqualObjects(source.owner.address.country, @"DE");
    XCTAssertEqualObjects(source.owner.address.line1, @"Nollendorfstraße 27");
    XCTAssertEqualObjects(source.owner.address.postalCode, @"10777");
    XCTAssertEqual(source.status, STPSourceStatusChargeable);
    XCTAssertEqual(source.type, STPSourceTypeSEPADebit);
    XCTAssertEqual(source.usage, STPSourceUsageReusable);
    XCTAssertEqualObjects(source.details, response[@"sepa_debit"]);
}

@end
