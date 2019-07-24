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
#import "STPNetworkStubbingTestCase.h"

@interface STPConnectAccountFunctionalTest : STPNetworkStubbingTestCase

/// Client with test publishable key
@property (nonatomic, strong, nonnull) STPAPIClient *client;

@end

@implementation STPConnectAccountFunctionalTest

- (void)setUp {
//    self.recordingMode = YES;
    [super setUp];

    self.client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_vOo1umqsYxSrP5UXfOeL3ecm"];
}

- (void)testTokenCreation_terms_throws {
    XCTAssertThrows([[STPConnectAccountParams alloc] initWithTosShownAndAccepted:NO
                                                                      individual:@{}],
                    @"NSParameterAssert to prevent trying to call this with `NO`");
    XCTAssertThrows([[STPConnectAccountParams alloc] initWithTosShownAndAccepted:NO
                                                                      company:@{}],
                    @"NSParameterAssert to prevent trying to call this with `NO`");
}

- (void)testTokenCreation_customer {
    [self createToken:[[STPConnectAccountParams alloc] initWithCompany:@{}]
        shouldSucceed:YES];
}

- (void)testTokenCreation_company {
    [self createToken:[[STPConnectAccountParams alloc] initWithIndividual:@{}]
        shouldSucceed:YES];
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
            XCTAssertEqual(token.type, STPTokenTypeAccount);
        }
        else {
            XCTAssertNil(token);
            XCTAssertNotNil(error);
        }
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end
