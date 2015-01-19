//
//  STPBankAccountFunctionalTest.m
//  Stripe
//
//  Created by Charles Scalesse on 10/2/14.
//
//

#import "STPAPIClient.h"
#import <XCTest/XCTest.h>
#import "Stripe.h"
#import "STPBankAccount.h"
#import "STPToken.h"

@interface STPBankAccountFunctionalTest : XCTestCase
@end

@implementation STPBankAccountFunctionalTest

- (void)testCreateAndRetreiveBankAccountToken {
    STPBankAccount *bankAccount = [[STPBankAccount alloc] init];
    bankAccount.accountNumber = @"000123456789";
    bankAccount.routingNumber = @"110000000";
    bankAccount.country = @"US";

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_5fhKkYDKKNr4Fp6q7Mq9CwJd"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Bank account creation"];
    [client createTokenWithBankAccount:bankAccount
                            completion:^(STPToken *token, NSError *error) {
                                [expectation fulfill];
                                XCTAssertNil(error, @"error should be nil %@", error.localizedDescription);
                                XCTAssertNotNil(token, @"token should not be nil");

                                XCTAssertNotNil(token.tokenId);
                                XCTAssertNotNil(token.bankAccount.bankAccountId);
                                XCTAssertEqualObjects(@"STRIPE TEST BANK", token.bankAccount.bankName);
                                XCTAssertEqualObjects(@"6789", token.bankAccount.last4);
                            }];

    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testInvalidKey {
    STPBankAccount *bankAccount = [[STPBankAccount alloc] init];
    bankAccount.accountNumber = @"000123456789";
    bankAccount.routingNumber = @"110000000";
    bankAccount.country = @"US";

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"not_a_valid_key_asdf"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Bad bank account creation"];

    [client createTokenWithBankAccount:bankAccount
                            completion:^(STPToken *token, NSError *error) {
                                [expectation fulfill];
                                XCTAssertNil(token, @"token should be nil");
                                XCTAssertNotNil(error, @"error should not be nil");
                                XCTAssert([error.localizedDescription rangeOfString:@"asdf"].location != NSNotFound, @"error should contain last 4 of key");
                            }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

@end
