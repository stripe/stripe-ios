//
//  STPPIIFunctionalTest.m
//  Stripe
//
//  Created by Charles Scalesse on 1/8/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@import XCTest;


#import "STPTestingAPIClient.h"

@interface STPPIIFunctionalTest : XCTestCase
@end

@implementation STPPIIFunctionalTest

- (void)testCreatePersonallyIdentifiableInformationToken {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"PII creation"];
    
    [client createTokenWithPersonalIDNumber:@"0123456789" completion:^(STPToken * _Nullable token, NSError * _Nullable error) {
        [expectation fulfill];
        XCTAssertNil(error, @"error should be nil %@", error.localizedDescription);
        XCTAssertNotNil(token, @"token should not be nil");
        XCTAssertNotNil(token.tokenId);
        XCTAssertEqual(token.type, STPTokenTypePII);
    }];
    
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

- (void)testSSNLast4Token {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"PII creation"];
    
    [client createTokenWithSSNLast4:@"1234" completion:^(STPToken * _Nullable token, NSError * _Nullable error) {
        [expectation fulfill];
        XCTAssertNil(error, @"error should be nil %@", error.localizedDescription);
        XCTAssertNotNil(token, @"token should not be nil");
        XCTAssertNotNil(token.tokenId);
        XCTAssertEqual(token.type, STPTokenTypePII);
    }];
    
    [self waitForExpectationsWithTimeout:STPTestingNetworkRequestTimeout handler:nil];
}

@end
