//
//  STPAddCardViewControllerTest.m
//  Stripe
//
//  Created by Ben Guo on 7/5/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MockSTPAPIClient.h"
#import "STPRememberMePaymentCell.h"
#import "STPCard.h"
#import "MockSTPAddCardViewControllerDelegate.h"

@interface STPAddCardViewController (Testing)
@property(nonatomic)STPRememberMePaymentCell *paymentCell;
@property(nonatomic)STPAPIClient *apiClient;
@property(nonatomic)BOOL loading;
@end

@interface STPToken (Testing)
@property (nonatomic, nonnull) NSString *tokenId;
@end

@interface STPAddCardViewControllerTest : XCTestCase
@end

@implementation STPAddCardViewControllerTest

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

- (void)testNextWithCreateTokenError {
    STPAddCardViewController *sut = [STPAddCardViewController new];
    XCTAssertNotNil(sut.view);
    MockSTPAPIClient *mockAPIClient = [MockSTPAPIClient new];
    sut.apiClient = mockAPIClient;
    STPCardParams *expectedCardParams = [STPCardParams new];
    expectedCardParams.number = @"4000000000000002";
    expectedCardParams.expMonth = 10;
    expectedCardParams.expYear = 99;
    expectedCardParams.cvc = @"123";
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
    STPCardParams *expectedCardParams = [STPCardParams new];
    expectedCardParams.number = @"4000000000000002";
    expectedCardParams.expMonth = 10;
    expectedCardParams.expYear = 99;
    expectedCardParams.cvc = @"123";
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

#pragma clang diagnostic pop

@end
