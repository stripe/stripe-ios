//
//  STPPaymentMethodSEPADebitTest.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/7/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPTestUtils.h"

@interface STPPaymentMethodSEPADebitTest : XCTestCase

@end

@implementation STPPaymentMethodSEPADebitTest

#pragma mark - STPAPIResponseDecodable Tests

- (void)testDecodedObjectFromAPIResponseRequiredFields {
    NSArray<NSString *> *requiredFields = @[];

    for (NSString *field in requiredFields) {
        NSMutableDictionary *response = [[STPTestUtils jsonNamed:@"SEPADebitSource"][@"sepa_debit"] mutableCopy];
        [response removeObjectForKey:field];

        XCTAssertNil([STPPaymentMethodSEPADebit decodedObjectFromAPIResponse:response]);
    }

    XCTAssert([STPPaymentMethodSEPADebit decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"SEPADebitSource"][@"sepa_debit"]]);
}

- (void)testDecodedObjectFromAPIResponseMapping {
    NSDictionary *response = [STPTestUtils jsonNamed:@"SEPADebitSource"][@"sepa_debit"];
    STPPaymentMethodSEPADebit *sepaDebit = [STPPaymentMethodSEPADebit decodedObjectFromAPIResponse:response];

    XCTAssertEqualObjects(sepaDebit.bankCode, @"37040044");
    XCTAssertEqualObjects(sepaDebit.branchCode, @"a_branch");
    XCTAssertEqualObjects(sepaDebit.country, @"DE");
    XCTAssertEqualObjects(sepaDebit.fingerprint, @"NxdSyRegc9PsMkWy");
    XCTAssertEqualObjects(sepaDebit.last4, @"3001");
    XCTAssertEqualObjects(sepaDebit.mandate, @"NXDSYREGC9PSMKWY");

    XCTAssertNotEqual(sepaDebit.allResponseFields, response);
    XCTAssertEqualObjects(sepaDebit.allResponseFields, response);
}


@end
