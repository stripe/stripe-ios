//
//  STPPaymentMethodBacsDebitTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 1/28/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPTestUtils.h"
#import "STPFixtures.h"

@interface STPPaymentMethodBacsDebitTest : XCTestCase

@end

@implementation STPPaymentMethodBacsDebitTest

#pragma mark - STPAPIResponseDecodable Tests

- (void)testDecodedObjectFromAPIResponseRequiredFields {
    NSDictionary *paymentMethodJSON = [STPTestUtils jsonNamed:STPTestJSONPaymentMethodBacsDebit];
    NSArray<NSString *> *requiredFields = @[];

    for (NSString *field in requiredFields) {
        NSMutableDictionary *response = [paymentMethodJSON[@"bacs_debit"] mutableCopy];
        [response removeObjectForKey:field];

        XCTAssertNil([STPPaymentMethodBacsDebit decodedObjectFromAPIResponse:response]);
    }

    STPPaymentMethod *paymentMethod = [STPPaymentMethod decodedObjectFromAPIResponse:paymentMethodJSON];
    XCTAssertNotNil(paymentMethod);
    XCTAssertNotNil(paymentMethod.bacsDebit);
}

- (void)testDecodedObjectFromAPIResponseMapping {
    NSDictionary *response = [STPTestUtils jsonNamed:STPTestJSONPaymentMethodBacsDebit][@"bacs_debit"];
    STPPaymentMethodBacsDebit *bacs = [STPPaymentMethodBacsDebit decodedObjectFromAPIResponse:response];
    XCTAssertEqualObjects(bacs.fingerprint, @"9eMbmctOrd8i7DYa");
    XCTAssertEqualObjects(bacs.last4, @"2345");
    XCTAssertEqualObjects(bacs.sortCode, @"108800");
}

@end
