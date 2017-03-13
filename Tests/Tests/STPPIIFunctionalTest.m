//
//  STPPIIFunctionalTest.m
//  Stripe
//
//  Created by Charles Scalesse on 1/8/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@import XCTest;

#import "STPAPIClient.h"
#import "STPToken.h"

@interface STPPIIFunctionalTest : XCTestCase
@end

@implementation STPPIIFunctionalTest

- (void)testCreatePersonallyIdentifiableInformationToken {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_vOo1umqsYxSrP5UXfOeL3ecm"];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"PII creation"];
    
    [client createTokenWithPersonalIDNumber:@"0123456789" completion:^(STPToken * _Nullable token, NSError * _Nullable error) {
        [expectation fulfill];
        XCTAssertNil(error, @"error should be nil %@", error.localizedDescription);
        XCTAssertNotNil(token, @"token should not be nil");
        XCTAssertNotNil(token.tokenId);
    }];
    
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

@end
