//
//  STPBankAccountFunctionalTest.m
//  Stripe
//
//  Created by Charles Scalesse on 10/2/14.
//
//

@import XCTest;

#import "STPAPIClient.h"
#import "Stripe.h"
#import "STPBankAccount.h"
#import "STPToken.h"
#import "STPNetworkStubbingTestCase.h"

@interface STPBankAccountFunctionalTest : STPNetworkStubbingTestCase
@end

@implementation STPBankAccountFunctionalTest

- (void)setUp {
//    self.recordingMode = YES;
    [super setUp];
}

- (void)testCreateAndRetreiveBankAccountToken {
    STPBankAccountParams *bankAccount = [[STPBankAccountParams alloc] init];
    bankAccount.accountNumber = @"000123456789";
    bankAccount.routingNumber = @"110000000";
    bankAccount.country = @"US";
    bankAccount.accountHolderName = @"Jimmy bob";
    bankAccount.accountHolderType = STPBankAccountHolderTypeCompany;

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_vOo1umqsYxSrP5UXfOeL3ecm"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Bank account creation"];
    [client createTokenWithBankAccount:bankAccount
                            completion:^(STPToken *token, NSError *error) {
                                [expectation fulfill];
                                XCTAssertNil(error, @"error should be nil %@", error.localizedDescription);
                                XCTAssertNotNil(token, @"token should not be nil");

                                XCTAssertNotNil(token.tokenId);
                                XCTAssertEqual(token.type, STPTokenTypeBankAccount);
                                XCTAssertNotNil(token.bankAccount.stripeID);
                                XCTAssertEqualObjects(@"STRIPE TEST BANK", token.bankAccount.bankName);
                                XCTAssertEqualObjects(@"6789", token.bankAccount.last4);
                                XCTAssertEqualObjects(@"Jimmy bob", token.bankAccount.accountHolderName);
                                XCTAssertEqual(token.bankAccount.accountHolderType, STPBankAccountHolderTypeCompany);
                            }];

    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testInvalidKey {
    STPBankAccountParams *bankAccount = [[STPBankAccountParams alloc] init];
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
