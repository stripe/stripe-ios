//
//  STPCardFunctionalTest.m
//  Stripe
//
//  Created by Ray Morgan on 7/11/14.
//
//

@import XCTest;

#import "Stripe.h"
#import "STPNetworkStubbingTestCase.h"

@interface STPCardFunctionalTest : STPNetworkStubbingTestCase
@end

@implementation STPCardFunctionalTest

- (void)setUp {
//    self.recordingMode = YES;
    [super setUp];
}

- (void)testCreateCardToken {
    STPCardParams *card = [[STPCardParams alloc] init];

    card.number = @"4242 4242 4242 4242";
    card.expMonth = 6;
    card.expYear = 2024;
    card.currency = @"usd";
    card.address.line1 = @"123 Fake Street";
    card.address.line2 = @"Apartment 4";
    card.address.city = @"New York";
    card.address.state = @"NY";
    card.address.country = @"USA";
    card.address.postalCode = @"10002";

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_vOo1umqsYxSrP5UXfOeL3ecm"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Card creation"];

    [client createTokenWithCard:card
                     completion:^(STPToken *token, NSError *error) {
                         [expectation fulfill];

                         XCTAssertNil(error, @"error should be nil %@", error.localizedDescription);
                         XCTAssertNotNil(token, @"token should not be nil");

                         XCTAssertNotNil(token.tokenId);
                         XCTAssertEqual(token.type, STPTokenTypeCard);
                         XCTAssertEqual(6U, token.card.expMonth);
                         XCTAssertEqual(2024U, token.card.expYear);
                         XCTAssertEqualObjects(@"4242", token.card.last4);
                         XCTAssertEqualObjects(@"usd", token.card.currency);
                         XCTAssertEqualObjects(@"10002", token.card.address.postalCode);
                     }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testCardTokenCreationWithInvalidParams {
    STPCardParams *card = [[STPCardParams alloc] init];

    card.number = @"4242 4242 4242 4241";
    card.expMonth = 6;
    card.expYear = 2024;

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_vOo1umqsYxSrP5UXfOeL3ecm"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Card creation"];

    [client createTokenWithCard:card
                     completion:^(STPToken *token, NSError *error) {
                         [expectation fulfill];

                         XCTAssertNotNil(error, @"error should not be nil");
                         XCTAssertEqual(error.code, 70);
                         XCTAssertEqualObjects(error.domain, StripeDomain);
                         XCTAssertEqualObjects(error.userInfo[STPErrorParameterKey], @"number");
                         XCTAssertNil(token, @"token should be nil: %@", token.description);
                     }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testCardTokenCreationWithExpiredCard {
    STPCardParams *card = [[STPCardParams alloc] init];

    card.number = @"4242 4242 4242 4242";
    card.expMonth = 6;
    card.expYear = 2013;

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_vOo1umqsYxSrP5UXfOeL3ecm"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Card creation"];

    [client createTokenWithCard:card
                     completion:^(STPToken *token, NSError *error) {
                         [expectation fulfill];

                         XCTAssertNotNil(error, @"error should not be nil");
                         XCTAssertEqual(error.code, 70);
                         XCTAssertEqualObjects(error.domain, StripeDomain);
                         XCTAssertEqualObjects(error.userInfo[STPCardErrorCodeKey], STPInvalidExpYear);
                         XCTAssertEqualObjects(error.userInfo[STPErrorParameterKey], @"expYear");
                         XCTAssertNil(token, @"token should be nil: %@", token.description);
                     }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testInvalidKey {
    STPCardParams *card = [[STPCardParams alloc] init];

    card.number = @"4242 4242 4242 4242";
    card.expMonth = 6;
    card.expYear = 2024;

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"not_a_valid_key_asdf"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Card failure"];
    [client createTokenWithCard:card
                     completion:^(STPToken *token, NSError *error) {
                         [expectation fulfill];
                         XCTAssertNil(token, @"token should be nil");
                         XCTAssertNotNil(error, @"error should not be nil");
                         XCTAssert([error.localizedDescription rangeOfString:@"asdf"].location != NSNotFound, @"error should contain last 4 of key");
                     }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testCreateCVCUpdateToken {
    // You have to be gated in to CVC Update tokens, so we use this differing key
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_6pRNASCoBOKtIshFeQd4XMUh"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"CVC Update Token Creation"];

    [client createTokenForCVCUpdate:@"1234"
                         completion:^(STPToken *token, NSError *error) {
                             [expectation fulfill];

                             XCTAssertNil(error, @"error should be nil %@", error.localizedDescription);
                             XCTAssertNotNil(token, @"token should not be nil");

                             XCTAssertNotNil(token.tokenId);
                             XCTAssertEqual(token.type, STPTokenTypeCVCUpdate, @"token should be type CVC Update");
                         }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testInvalidCVC {
    // You have to be gated in to CVC Update tokens, so we use this differing key
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_6pRNASCoBOKtIshFeQd4XMUh"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Invalid CVC"];

    [client createTokenForCVCUpdate:@"1"
                         completion:^(STPToken *token, NSError *error) {
                             [expectation fulfill];

                             XCTAssertNil(token, @"token should be nil");
                             XCTAssertNotNil(error, @"error should not be nil");
                         }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

@end
