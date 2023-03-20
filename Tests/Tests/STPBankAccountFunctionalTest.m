//
//  STPBankAccountFunctionalTest.m
//  Stripe
//
//  Created by Charles Scalesse on 10/2/14.
//
//

@import XCTest;
@import StripeCoreTestUtils;


#import "STPTestingAPIClient.h"


@interface STPBankAccountFunctionalTest : XCTestCase
@end

@implementation STPBankAccountFunctionalTest

- (void)testCreateAndRetreiveBankAccountToken {
    STPBankAccountParams *bankAccount = [[STPBankAccountParams alloc] init];
    bankAccount.accountNumber = @"000123456789";
    bankAccount.routingNumber = @"110000000";
    bankAccount.country = @"US";
    bankAccount.accountHolderName = @"Jimmy bob";
    bankAccount.accountHolderType = STPBankAccountHolderTypeCompany;

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:STPTestingDefaultPublishableKey];

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

    [self waitForExpectationsWithTimeout:TestConstants.STPTestingNetworkRequestTimeout handler:nil];
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
                            }];
    [self waitForExpectationsWithTimeout:TestConstants.STPTestingNetworkRequestTimeout handler:nil];
}

@end
