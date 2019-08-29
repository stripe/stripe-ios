//
//  STPConnectAccountFunctionalTest.m
//  StripeiOS Tests
//
//  Created by Daniel Jackson on 1/8/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPAPIClient.h"
#import "STPConnectAccountIndividualParams.h"
#import "STPConnectAccountCompanyParams.h"
#import "STPConnectAccountParams.h"
#import "STPFixtures.h"
#import "STPNetworkStubbingTestCase.h"

@interface STPConnectAccountFunctionalTest : STPNetworkStubbingTestCase

/// Client with test publishable key
@property (nonatomic, strong, nonnull) STPAPIClient *client;
@property (nonatomic, strong, nonnull) STPConnectAccountIndividualParams *individual;
@property (nonatomic, strong, nonnull) STPConnectAccountCompanyParams *company;

@end

@implementation STPConnectAccountFunctionalTest

- (void)setUp {
//    self.recordingMode = YES;
    [super setUp];

    self.client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_vOo1umqsYxSrP5UXfOeL3ecm"];
    self.individual = [STPConnectAccountIndividualParams new];
    self.individual.firstName = @"Test";
    self.company = [STPConnectAccountCompanyParams new];
    self.company.name = @"Test";
}

- (void)testTokenCreation_terms_throws {
    XCTAssertThrows([[STPConnectAccountParams alloc] initWithTosShownAndAccepted:NO
                                                                      individual:self.individual],
                    @"NSParameterAssert to prevent trying to call this with `NO`");
    XCTAssertThrows([[STPConnectAccountParams alloc] initWithTosShownAndAccepted:NO
                                                                         company:self.company],
                    @"NSParameterAssert to prevent trying to call this with `NO`");
}

- (void)testTokenCreation_customer {
    [self createToken:[[STPConnectAccountParams alloc] initWithCompany:self.company]
        shouldSucceed:YES];
}

- (void)testTokenCreation_company {
    [self createToken:[[STPConnectAccountParams alloc] initWithIndividual:self.individual]
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
