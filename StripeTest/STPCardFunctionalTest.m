//
//  STPCardFunctionalTest.m
//  Stripe
//
//  Created by Ray Morgan on 7/11/14.
//
//

#import <XCTest/XCTest.h>
#import "Stripe.h"
#import "STPCard.h"

@interface STPCardFunctionalTest : XCTestCase
@end

@implementation STPCardFunctionalTest

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000

- (void)testCreateCardToken {
    [Stripe setDefaultPublishableKey:@"pk_test_5fhKkYDKKNr4Fp6q7Mq9CwJd"];
    STPCard *card = [[STPCard alloc] init];

    card.number = @"4242 4242 4242 4242";
    card.expMonth = 6;
    card.expYear = 2018;

    XCTestExpectation *expectation = [self expectationWithDescription:@"Card creation"];

    [Stripe createTokenWithCard:card
                     completion:^(STPToken *token, NSError *error) {
                         [expectation fulfill];

                         XCTAssertNil(error, @"error should be nil %@", error.localizedDescription);
                         XCTAssertNotNil(token, @"token should not be nil");

                         XCTAssertNotNil(token.tokenId);
                         XCTAssertEqual(6U, token.card.expMonth);
                         XCTAssertEqual(2018U, token.card.expYear);
                         XCTAssertEqualObjects(@"4242", token.card.last4);
                     }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testInvalidKey {
    STPCard *card = [[STPCard alloc] init];

    card.number = @"4242 4242 4242 4242";
    card.expMonth = 6;
    card.expYear = 2018;

    XCTestExpectation *expectation = [self expectationWithDescription:@"Card failure"];
    [Stripe createTokenWithCard:card
                 publishableKey:@"not_a_valid_key_asdf"
                 operationQueue:[NSOperationQueue mainQueue]
                     completion:^(STPToken *token, NSError *error) {
                         [expectation fulfill];
                         XCTAssertNil(token, @"token should be nil");
                         XCTAssertNotNil(error, @"error should not be nil");
                         XCTAssert([error.localizedDescription rangeOfString:@"asdf"].location != NSNotFound, @"error should contain last 4 of key");
                     }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

#endif

@end
