//
//  STPSourceSEPADebitDetails.m
//  Stripe
//
//  Created by Joey Dong on 6/26/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@import XCTest;

#import "STPSourceSEPADebitDetails.h"

@interface STPSourceSEPADebitDetailsTest : XCTestCase

@end

@implementation STPSourceSEPADebitDetailsTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - Description Tests

- (void)testDescription {
    STPSourceSEPADebitDetails *sepaDebitDetails = [STPSourceSEPADebitDetails decodedObjectFromAPIResponse:[self completeAttributeDictionary]];
    XCTAssert(sepaDebitDetails.description);
}

#pragma mark - STPAPIResponseDecodable Tests

- (NSDictionary *)completeAttributeDictionary {
    // Source: https://stripe.com/docs/sources/sepa-debit
    return @{
             @"bank_code": @"37040044",
             @"country": @"DE",
             @"fingerprint": @"NxdSyRegc9PsMkWy",
             @"last4": @"3001",
             @"mandate_reference": @"NXDSYREGC9PSMKWY",
             @"mandate_url": @"https://hooks.stripe.com/adapter/sepa_debit/file/src_18HgGjHNCLa1Vra6Y9TIP6tU/src_client_secret_XcBmS94nTg5o0xc9MSliSlDW",
             };
}

- (void)testDecodedObjectFromAPIResponseRequiredFields {
    NSArray<NSString *> *requiredFields = @[];

    for (NSString *field in requiredFields) {
        NSMutableDictionary *response = [[self completeAttributeDictionary] mutableCopy];
        [response removeObjectForKey:field];

        XCTAssertNil([STPSourceSEPADebitDetails decodedObjectFromAPIResponse:response]);
    }

    XCTAssert([STPSourceSEPADebitDetails decodedObjectFromAPIResponse:[self completeAttributeDictionary]]);
}

- (void)testDecodedObjectFromAPIResponseMapping {
    NSDictionary *response = [self completeAttributeDictionary];
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
