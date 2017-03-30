//
//  STPFixturesTest.m
//  Stripe
//
//  Created by Ben Guo on 3/30/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSDictionary+Stripe.h"
#import "STPFixtures.h"
#import "STPTestUtils.h"

@interface STPFixturesTest : XCTestCase

@end

@implementation STPFixturesTest

/**
 Since our source decoding tests verify properties against `allResponseFields`,
 this test verifies that `allResponseFields` matches the original JSON.
 @see STPSourceTest
 */
- (void)testSourceFixtures {
    STPSource *cardSource = [STPFixtures cardSource];
    NSDictionary *cardJSON = [[STPTestUtils jsonNamed:@"CardSource"] stp_dictionaryByRemovingNullsValidatingRequiredFields:@[]];
    XCTAssertEqualObjects(cardSource.allResponseFields, cardJSON);

    STPSource *sepaSource = [STPFixtures sepaDebitSource];
    NSDictionary *sepaJSON = [[STPTestUtils jsonNamed:@"SEPADebitSource"] stp_dictionaryByRemovingNullsValidatingRequiredFields:@[]];
    XCTAssertEqualObjects(sepaSource.allResponseFields, sepaJSON);

    STPSource *idealSource = [STPFixtures iDEALSource];
    NSDictionary *idealJSON = [[STPTestUtils jsonNamed:@"iDEALSource"] stp_dictionaryByRemovingNullsValidatingRequiredFields:@[]];
    XCTAssertEqualObjects(idealSource.allResponseFields, idealJSON);
}

@end
