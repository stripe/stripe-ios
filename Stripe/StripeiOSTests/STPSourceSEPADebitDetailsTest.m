//
//  STPSourceSEPADebitDetails.m
//  Stripe
//
//  Created by Joey Dong on 6/26/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@import XCTest;

#import "STPTestUtils.h"

@interface STPSourceSEPADebitDetailsTest : XCTestCase

@end

@implementation STPSourceSEPADebitDetailsTest

#pragma mark - Description Tests

- (void)testDescription {
    STPSourceSEPADebitDetails *sepaDebitDetails = [STPSourceSEPADebitDetails decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"SEPADebitSource"][@"sepa_debit"]];
    XCTAssert(sepaDebitDetails.description);
}

#pragma mark - STPAPIResponseDecodable Tests

- (void)testDecodedObjectFromAPIResponseRequiredFields {
    NSArray<NSString *> *requiredFields = @[];

    for (NSString *field in requiredFields) {
        NSMutableDictionary *response = [[STPTestUtils jsonNamed:@"SEPADebitSource"][@"sepa_debit"] mutableCopy];
        [response removeObjectForKey:field];

        XCTAssertNil([STPSourceSEPADebitDetails decodedObjectFromAPIResponse:response]);
    }

    XCTAssert([STPSourceSEPADebitDetails decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"SEPADebitSource"][@"sepa_debit"]]);
}

- (void)testDecodedObjectFromAPIResponseMapping {
    NSDictionary *response = [STPTestUtils jsonNamed:@"SEPADebitSource"][@"sepa_debit"];
    STPSourceSEPADebitDetails *sepaDebitDetails = [STPSourceSEPADebitDetails decodedObjectFromAPIResponse:response];

    XCTAssertEqualObjects(sepaDebitDetails.bankCode, @"37040044");
    XCTAssertEqualObjects(sepaDebitDetails.country, @"DE");
    XCTAssertEqualObjects(sepaDebitDetails.fingerprint, @"NxdSyRegc9PsMkWy");
    XCTAssertEqualObjects(sepaDebitDetails.last4, @"3001");
    XCTAssertEqualObjects(sepaDebitDetails.mandateReference, @"NXDSYREGC9PSMKWY");
    XCTAssertEqualObjects(sepaDebitDetails.mandateURL, [NSURL URLWithString:@"https://hooks.stripe.com/adapter/sepa_debit/file/src_18HgGjHNCLa1Vra6Y9TIP6tU/src_client_secret_XcBmS94nTg5o0xc9MSliSlDW"]);

    XCTAssertNotEqual(sepaDebitDetails.allResponseFields, response);
    XCTAssertEqualObjects(sepaDebitDetails.allResponseFields, response);
}

@end
