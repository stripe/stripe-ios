//
//  STPAddCardViewControllerTest.m
//  Stripe
//
//  Created by Ben Guo on 7/5/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MockSTPAPIClient.h"
#import "MockSTPCheckoutAPIClient.h"
#import "STPRememberMePaymentCell.h"
#import "STPCard.h"
#import "MockSTPAddCardViewControllerDelegate.h"
#import "STPCheckoutAccount.h"

@interface STPCheckoutAccount (Testing)
@property(nonatomic, nonnull)STPCard *card;
@end

@interface STPAddCardViewController (Testing)
@property(nonatomic)STPRememberMePaymentCell *paymentCell;
@property(nonatomic)STPAPIClient *apiClient;
@property(nonatomic)STPCheckoutAPIClient *checkoutAPIClient;
@property(nonatomic)STPCheckoutAccount *checkoutAccount;
@property(nonatomic)STPCard *checkoutAccountCard;
@property(nonatomic)BOOL loading;
@end

@interface STPToken (Testing)
@property (nonatomic, nonnull) NSString *tokenId;
@end

@interface STPAddCardViewControllerTest : XCTestCase
@end

@implementation STPAddCardViewControllerTest

- (STPCardParams *)cardParams {
    STPCardParams *cardParams = [STPCardParams new];
    cardParams.number = @"4000000000000002";
    cardParams.expMonth = 10;
    cardParams.expYear = 99;
    cardParams.cvc = @"123";
    return cardParams;
}

- (STPCheckoutAccount *)checkoutAccount {
    STPCheckoutAccount *account = [STPCheckoutAccount new];
    STPCard *card = [[STPCard alloc] initWithID:@"cc_123"
                                          brand:STPCardBrandVisa
                                          last4:@"1234"
                                       expMonth:10
                                        expYear:18
                                        funding:STPCardFundingTypeCredit];
    account.card = card;
    return account;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

- (void)testNextWithCreateTokenError {
    STPAddCardViewController *sut = [STPAddCardViewController new];
    XCTAssertNotNil(sut.view);
    MockSTPAPIClient *mockAPIClient = [MockSTPAPIClient new];
    sut.apiClient = mockAPIClient;
    STPCardParams *expectedCardParams = [self cardParams];
    sut.paymentCell.paymentField.cardParams = expectedCardParams;
    XCTestExpectation *exp = [self expectationWithDescription:@"createTokenWithCard"];
    mockAPIClient.onCreateTokenWithCard = ^(STPCardParams *cardParams, STPTokenCompletionBlock completion) {
        XCTAssertEqualObjects(cardParams.number, expectedCardParams.number);
        XCTAssertTrue(sut.loading);
        NSError *error = [NSError stp_genericFailedToParseResponseError];
        completion(nil, error);
        XCTAssertFalse(sut.loading);
        [exp fulfill];
    };

    // tap next button
    UIBarButtonItem *nextButton = sut.navigationItem.rightBarButtonItem;
    [nextButton.target performSelector:nextButton.action withObject:nextButton];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testNextWithCreateTokenSuccessAndDidCreateTokenError {
    STPAddCardViewController *sut = [STPAddCardViewController new];
    XCTAssertNotNil(sut.view);
    MockSTPAPIClient *mockAPIClient = [MockSTPAPIClient new];
    sut.apiClient = mockAPIClient;
    MockSTPAddCardViewControllerDelegate *mockDelegate = [MockSTPAddCardViewControllerDelegate new];
    sut.delegate = mockDelegate;
    STPCardParams *expectedCardParams = [self cardParams];
    sut.paymentCell.paymentField.cardParams = expectedCardParams;
    XCTestExpectation *createTokenExp = [self expectationWithDescription:@"createTokenWithCard"];
    STPToken *expectedToken = [STPToken new];
    expectedToken.tokenId = @"tok_123";
    mockAPIClient.onCreateTokenWithCard = ^(STPCardParams *cardParams, STPTokenCompletionBlock completion) {
        XCTAssertEqualObjects(cardParams.number, expectedCardParams.number);
        XCTAssertTrue(sut.loading);
        completion(expectedToken, nil);
        [createTokenExp fulfill];
    };
    XCTestExpectation *didCreateTokenExp = [self expectationWithDescription:@"didCreateToken"];
    mockDelegate.onDidCreateToken = ^(STPToken *token, STPErrorBlock completion) {
        XCTAssertTrue(sut.loading);
        NSError *error = [NSError stp_genericFailedToParseResponseError];
        XCTAssertEqualObjects(token.tokenId, expectedToken.tokenId);
        completion(error);
        XCTAssertFalse(sut.loading);
        [didCreateTokenExp fulfill];
    };

    // tap next button
    UIBarButtonItem *nextButton = sut.navigationItem.rightBarButtonItem;
    [nextButton.target performSelector:nextButton.action withObject:nextButton];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testNextWithCreateTokenSuccessAndDidCreateTokenSuccess {
    STPAddCardViewController *sut = [STPAddCardViewController new];
    XCTAssertNotNil(sut.view);
    MockSTPAPIClient *mockAPIClient = [MockSTPAPIClient new];
    sut.apiClient = mockAPIClient;
    MockSTPAddCardViewControllerDelegate *mockDelegate = [MockSTPAddCardViewControllerDelegate new];
    sut.delegate = mockDelegate;
    STPCardParams *expectedCardParams = [self cardParams];
    sut.paymentCell.paymentField.cardParams = expectedCardParams;
    XCTestExpectation *createTokenExp = [self expectationWithDescription:@"createTokenWithCard"];
    STPToken *expectedToken = [STPToken new];
    expectedToken.tokenId = @"tok_123";
    mockAPIClient.onCreateTokenWithCard = ^(STPCardParams *cardParams, STPTokenCompletionBlock completion) {
        XCTAssertEqualObjects(cardParams.number, expectedCardParams.number);
        XCTAssertTrue(sut.loading);
        completion(expectedToken, nil);
        [createTokenExp fulfill];
    };
    XCTestExpectation *didCreateTokenExp = [self expectationWithDescription:@"didCreateToken"];
    mockDelegate.onDidCreateToken = ^(STPToken *token, STPErrorBlock completion) {
        XCTAssertTrue(sut.loading);
        XCTAssertEqualObjects(token.tokenId, expectedToken.tokenId);
        completion(nil);
        XCTAssertFalse(sut.loading);
        [didCreateTokenExp fulfill];
    };

    // tap next button
    UIBarButtonItem *nextButton = sut.navigationItem.rightBarButtonItem;
    [nextButton.target performSelector:nextButton.action withObject:nextButton];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testNextWithCheckoutCreateTokenError {
    STPAddCardViewController *sut = [STPAddCardViewController new];
    XCTAssertNotNil(sut.view);
    MockSTPCheckoutAPIClient *mockCheckoutAPIClient = [MockSTPCheckoutAPIClient new];
    sut.checkoutAPIClient = mockCheckoutAPIClient;
    STPPromise *promise = [STPPromise new];
    STPCheckoutAccount *checkoutAccount = [self checkoutAccount];
    sut.checkoutAccount = checkoutAccount;
    sut.checkoutAccountCard = checkoutAccount.card;
    XCTestExpectation *createTokenExp = [self expectationWithDescription:@"createTokenWithCard"];
    mockCheckoutAPIClient.createTokenWithAccount = ^STPPromise *(STPCheckoutAccount *account) {
        XCTAssertEqualObjects(account.card, checkoutAccount.card);
        XCTAssertTrue(sut.loading);
        [createTokenExp fulfill];
        return promise;
    };
    XCTestExpectation *promiseExp = [self expectationWithDescription:@"onFailure"];
    [promise fail:[NSError stp_genericFailedToParseResponseError]];
    [promise onFailure:^(__unused NSError * error) {
        XCTAssertFalse(sut.loading);
        [promiseExp fulfill];
    }];

    // tap next button
    UIBarButtonItem *nextButton = sut.navigationItem.rightBarButtonItem;
    [nextButton.target performSelector:nextButton.action withObject:nextButton];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testNextWithCheckoutCreateTokenSuccessAndDidCreateTokenError {
    STPAddCardViewController *sut = [STPAddCardViewController new];
    XCTAssertNotNil(sut.view);
    MockSTPCheckoutAPIClient *mockCheckoutAPIClient = [MockSTPCheckoutAPIClient new];
    sut.checkoutAPIClient = mockCheckoutAPIClient;
    MockSTPAddCardViewControllerDelegate *mockDelegate = [MockSTPAddCardViewControllerDelegate new];
    sut.delegate = mockDelegate;
    STPToken *expectedToken = [STPToken new];
    expectedToken.tokenId = @"tok_123";
    STPCheckoutAccount *checkoutAccount = [self checkoutAccount];
    sut.checkoutAccount = checkoutAccount;
    sut.checkoutAccountCard = checkoutAccount.card;
    XCTestExpectation *createTokenExp = [self expectationWithDescription:@"createTokenWithCard"];
    mockCheckoutAPIClient.createTokenWithAccount = ^STPPromise *(STPCheckoutAccount *account) {
        XCTAssertEqualObjects(account.card, checkoutAccount.card);
        XCTAssertTrue(sut.loading);
        STPPromise *promise = [STPPromise new];
        [promise succeed:expectedToken];
        [createTokenExp fulfill];
        return promise;
    };
    XCTestExpectation *didCreateTokenExp = [self expectationWithDescription:@"didCreateToken"];
    mockDelegate.onDidCreateToken = ^(STPToken *token, STPErrorBlock completion) {
        XCTAssertTrue(sut.loading);
        NSError *error = [NSError stp_genericFailedToParseResponseError];
        XCTAssertEqualObjects(token.tokenId, expectedToken.tokenId);
        completion(error);
        XCTAssertFalse(sut.loading);
        [didCreateTokenExp fulfill];
    };

    // tap next button
    UIBarButtonItem *nextButton = sut.navigationItem.rightBarButtonItem;
    [nextButton.target performSelector:nextButton.action withObject:nextButton];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testNextWithCheckoutCreateTokenSuccessAndDidCreateTokenSuccess {
    STPAddCardViewController *sut = [STPAddCardViewController new];
    XCTAssertNotNil(sut.view);
    MockSTPCheckoutAPIClient *mockCheckoutAPIClient = [MockSTPCheckoutAPIClient new];
    sut.checkoutAPIClient = mockCheckoutAPIClient;
    MockSTPAddCardViewControllerDelegate *mockDelegate = [MockSTPAddCardViewControllerDelegate new];
    sut.delegate = mockDelegate;
    STPToken *expectedToken = [STPToken new];
    expectedToken.tokenId = @"tok_123";
    STPCheckoutAccount *checkoutAccount = [self checkoutAccount];
    sut.checkoutAccount = checkoutAccount;
    sut.checkoutAccountCard = checkoutAccount.card;
    XCTestExpectation *createTokenExp = [self expectationWithDescription:@"createTokenWithCard"];
    mockCheckoutAPIClient.createTokenWithAccount = ^STPPromise *(STPCheckoutAccount *account) {
        XCTAssertEqualObjects(account.card, checkoutAccount.card);
        XCTAssertTrue(sut.loading);
        STPPromise *promise = [STPPromise new];
        [promise succeed:expectedToken];
        [createTokenExp fulfill];
        return promise;
    };
    XCTestExpectation *didCreateTokenExp = [self expectationWithDescription:@"didCreateToken"];
    mockDelegate.onDidCreateToken = ^(STPToken *token, STPErrorBlock completion) {
        XCTAssertTrue(sut.loading);
        XCTAssertEqualObjects(token.tokenId, expectedToken.tokenId);
        completion(nil);
        XCTAssertFalse(sut.loading);
        [didCreateTokenExp fulfill];
    };

    // tap next button
    UIBarButtonItem *nextButton = sut.navigationItem.rightBarButtonItem;
    [nextButton.target performSelector:nextButton.action withObject:nextButton];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

#pragma clang diagnostic pop

@end
