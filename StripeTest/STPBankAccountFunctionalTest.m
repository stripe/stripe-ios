//
//  STPBankAccountFunctionalTest.m
//  Stripe
//
//  Created by Charles Scalesse on 10/2/14.
//
//

#import <XCTest/XCTest.h>
#import "Stripe.h"
#import "STPBankAccount.h"

@interface STPBankAccountFunctionalTest : XCTestCase
@end

@implementation STPBankAccountFunctionalTest

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000

- (void)testCreateAndRetreiveBankAccountToken {
    [Stripe setDefaultPublishableKey:@"pk_test_5fhKkYDKKNr4Fp6q7Mq9CwJd"];

    STPBankAccount *bankAccount = [[STPBankAccount alloc] init];
    bankAccount.accountNumber = @"000123456789";
    bankAccount.routingNumber = @"110000000";
    bankAccount.country = @"US";

    XCTestExpectation *expectation = [self expectationWithDescription:@"Bank account creation"];

    [Stripe createTokenWithBankAccount:bankAccount
                        publishableKey:@"pk_test_5fhKkYDKKNr4Fp6q7Mq9CwJd"
                        operationQueue:[NSOperationQueue mainQueue]
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

    XCTestExpectation *expectation = [self expectationWithDescription:@"Bad bank account creation"];

    [Stripe createTokenWithBankAccount:bankAccount
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
