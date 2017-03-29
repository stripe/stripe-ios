//
//  STPSourceTest.m
//  Stripe
//
//  Created by Ben Guo on 1/24/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@import XCTest;
#import <Stripe/Stripe.h>
#import "STPFixtures.h"

@interface STPSourceTest : XCTestCase

@end

@implementation STPSourceTest

- (void)testDecodingSource_ideal {
    STPSource *source = [STPFixtures iDEALSource];
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
    XCTAssertEqualObjects(source.details[@"bank"], @"ing");
}

- (void)testDecodingSource_sepa_debit {
    STPSource *source = [STPFixtures sepaDebitSource];
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
    XCTAssertEqualObjects(source.sepaDebitDetails.bankCode, @"37040044");
    XCTAssertEqualObjects(source.sepaDebitDetails.country, @"DE");
    XCTAssertEqualObjects(source.sepaDebitDetails.fingerprint, @"NxdSyRegc9PsMkWy");
    XCTAssertEqualObjects(source.sepaDebitDetails.last4, @"3001");
    XCTAssertEqualObjects(source.sepaDebitDetails.mandateReference, @"NXDSYREGC9PSMKWY");
    XCTAssertEqualObjects(source.sepaDebitDetails.mandateURL.absoluteString, @"https://hooks.stripe.com/adapter/sepa_debit/file/src_123/src_client_secret_123");
}

@end
