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
    NSDictionary *fields = source.allResponseFields;
    XCTAssertEqualObjects(source.stripeID, fields[@"id"]);
    XCTAssertEqual(source.livemode, [fields[@"livemode"] boolValue]);
    XCTAssertEqualObjects(source.amount, fields[@"amount"]);
    XCTAssertEqualObjects(source.currency, fields[@"currency"]);
    XCTAssertEqualObjects(source.clientSecret, fields[@"client_secret"]);
    XCTAssertEqualObjects(source.owner.name, fields[@"owner"][@"name"]);
    XCTAssertEqualObjects(source.owner.verifiedName, fields[@"owner"][@"verified_name"]);
    XCTAssertEqualObjects(source.redirect.returnURL.absoluteString, fields[@"redirect"][@"return_url"]);
    XCTAssertEqualObjects(source.redirect.url.absoluteString, fields[@"redirect"][@"url"]);
    XCTAssertEqualObjects(source.details[@"bank"], fields[@"ideal"][@"bank"]);
    XCTAssertEqual(source.flow, STPSourceFlowRedirect);
    XCTAssertEqual(source.status, STPSourceStatusPending);
    XCTAssertEqual(source.redirect.status, STPSourceRedirectStatusPending);
    XCTAssertEqual(source.type, STPSourceTypeIDEAL);
    XCTAssertEqual(source.usage, STPSourceUsageSingleUse);
}

- (void)testDecodingSource_sepa_debit {
    STPSource *source = [STPFixtures sepaDebitSource];
    NSDictionary *fields = source.allResponseFields;
    XCTAssertEqualObjects(source.stripeID, fields[@"id"]);
    XCTAssertEqual(source.livemode, [fields[@"livemode"] boolValue]);
    XCTAssertEqualObjects(source.amount, fields[@"amount"]);
    XCTAssertEqualObjects(source.currency, fields[@"currency"]);
    XCTAssertEqualObjects(source.clientSecret, fields[@"client_secret"]);
    XCTAssertEqualObjects(source.owner.name, fields[@"owner"][@"name"]);
    XCTAssertEqualObjects(source.owner.address.city, fields[@"owner"][@"address"][@"city"]);
    XCTAssertEqualObjects(source.owner.address.country, fields[@"owner"][@"address"][@"country"]);
    XCTAssertEqualObjects(source.owner.address.line1, fields[@"owner"][@"address"][@"line1"]);
    XCTAssertEqualObjects(source.owner.address.postalCode, fields[@"owner"][@"address"][@"postal_code"]);
    XCTAssertEqualObjects(source.sepaDebitDetails.bankCode, fields[@"sepa_debit"][@"bank_code"]);
    XCTAssertEqualObjects(source.sepaDebitDetails.country, fields[@"sepa_debit"][@"country"]);
    XCTAssertEqualObjects(source.sepaDebitDetails.fingerprint, fields[@"sepa_debit"][@"fingerprint"]);
    XCTAssertEqualObjects(source.sepaDebitDetails.last4, fields[@"sepa_debit"][@"last4"]);
    XCTAssertEqualObjects(source.sepaDebitDetails.mandateReference, fields[@"sepa_debit"][@"mandate_reference"]);
    XCTAssertEqualObjects(source.sepaDebitDetails.mandateURL.absoluteString, fields[@"sepa_debit"][@"mandate_url"]);
    XCTAssertEqual(source.status, STPSourceStatusChargeable);
    XCTAssertEqual(source.type, STPSourceTypeSEPADebit);
    XCTAssertEqual(source.usage, STPSourceUsageReusable);

}

@end
