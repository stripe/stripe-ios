//
//  STPConnectAccountFunctionalTest.m
//  StripeiOS Tests
//
//  Created by Daniel Jackson on 1/8/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPAPIClient.h"
#import "STPConnectAccountParams.h"

#import "STPFixtures.h"

@interface STPConnectAccountFunctionalTest : XCTestCase

/// Client with test publishable key
@property (nonatomic, strong, nonnull) STPAPIClient *client;

@end

@implementation STPConnectAccountFunctionalTest

- (void)setUp {
    [super setUp];

    self.client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_vOo1umqsYxSrP5UXfOeL3ecm"];
}

- (void)testTokenCreation_terms_throws {
    XCTAssertThrows([[STPConnectAccountParams alloc] initWithTosShownAndAccepted:NO
                                                                     legalEntity:[STPFixtures legalEntityParams]],
                    @"NSParameterAssert to prevent trying to call this with `NO`");
}

- (void)testTokenCreation_fullySpecified {
    [self createToken:[STPFixtures accountParams]
        shouldSucceed:YES];
}

- (void)testTokenCreation_legalEntityOnly {
    STPLegalEntityParams *entity = [[STPLegalEntityParams alloc] init];
    entity.firstName = @"Legal";
    entity.lastName = @"Eagle";

    [self createToken:[[STPConnectAccountParams alloc] initWithLegalEntity:entity]
        shouldSucceed:YES];
}

- (void)testTokenCreation_legalEntity_emptyFails {
    [self createToken:[[STPConnectAccountParams alloc] initWithLegalEntity:[STPLegalEntityParams new]]
        shouldSucceed:NO];
}

#pragma mark -

- (void)createToken:(STPConnectAccountParams *)params shouldSucceed:(BOOL)shouldSucceed {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Connect Account Token"];

    [self.client createTokenWithConnectAccount:params completion:^(STPToken * _Nullable token, NSError * _Nullable error) {
        [expectation fulfill];

        if (shouldSucceed) {
            XCTAssertNil(error);
            XCTAssertNotNil(token);
            XCTAssertNotNil(token.tokenId);
        }
        else {
            XCTAssertNil(token);
            XCTAssertNotNil(error);
        }
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end
