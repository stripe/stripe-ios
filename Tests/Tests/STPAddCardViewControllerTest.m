//
//  STPAddCardViewControllerTest.m
//  Stripe
//
//  Created by Ben Guo on 7/5/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <Stripe/Stripe.h>
#import "NSError+Stripe.h"
#import "STPCard.h"
#import "STPFixtures.h"
#import "STPPaymentCardTextFieldCell.h"

@interface STPAddCardViewController (Testing)
@property (nonatomic) STPPaymentCardTextFieldCell *paymentCell;
@property (nonatomic) STPAPIClient *apiClient;
@property (nonatomic) BOOL loading;
@end

@interface STPToken (Testing)
@property (nonatomic, nonnull) NSString *tokenId;
@end

@interface STPAddCardViewControllerTest : XCTestCase
@end

@implementation STPAddCardViewControllerTest

- (STPAddCardViewController *)buildAddCardViewController {
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    STPTheme *theme = [STPTheme defaultTheme];
    STPAddCardViewController *vc = [[STPAddCardViewController alloc] initWithConfiguration:config
                                                                                     theme:theme];
    XCTAssertNotNil(vc.view);
    return vc;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

- (void)testNextWithCreateTokenError {
    STPAddCardViewController *sut = [self buildAddCardViewController];
    STPCardParams *expectedCardParams = [STPFixtures cardParams];
    sut.paymentCell.paymentField.cardParams = expectedCardParams;

    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    sut.apiClient = mockAPIClient;
    XCTestExpectation *exp = [self expectationWithDescription:@"createTokenWithCard"];
    OCMStub([mockAPIClient createTokenWithCard:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPCardParams *cardParams;
        STPTokenCompletionBlock completion;
        [invocation getArgument:&cardParams atIndex:2];
        [invocation getArgument:&completion atIndex:3];
        XCTAssertEqualObjects(cardParams.number, expectedCardParams.number);
        XCTAssertTrue(sut.loading);
        NSError *error = [NSError stp_genericFailedToParseResponseError];
        completion(nil, error);
        XCTAssertFalse(sut.loading);
        [exp fulfill];
    });

    // tap next button
    UIBarButtonItem *nextButton = sut.navigationItem.rightBarButtonItem;
    [nextButton.target performSelector:nextButton.action withObject:nextButton];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testNextWithCreateTokenSuccessAndDidCreateTokenError {
    STPAddCardViewController *sut = [self buildAddCardViewController];

    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    id mockDelegate = OCMProtocolMock(@protocol(STPAddCardViewControllerDelegate));
    sut.apiClient = mockAPIClient;
    sut.delegate = mockDelegate;
    STPCardParams *expectedCardParams = [STPFixtures cardParams];
    sut.paymentCell.paymentField.cardParams = expectedCardParams;

    STPToken *expectedToken = [STPToken new];
    expectedToken.tokenId = @"tok_123";
    XCTestExpectation *createTokenExp = [self expectationWithDescription:@"createTokenWithCard"];
    OCMStub([mockAPIClient createTokenWithCard:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPCardParams *cardParams;
        STPTokenCompletionBlock completion;
        [invocation getArgument:&cardParams atIndex:2];
        [invocation getArgument:&completion atIndex:3];
        XCTAssertEqualObjects(cardParams.number, expectedCardParams.number);
        XCTAssertTrue(sut.loading);
        completion(expectedToken, nil);
        [createTokenExp fulfill];
    });
    
    XCTestExpectation *didCreateTokenExp = [self expectationWithDescription:@"didCreateToken"];
    OCMStub([mockDelegate addCardViewController:[OCMArg any] didCreateToken:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPToken *token;
        STPErrorBlock completion;
        [invocation getArgument:&token atIndex:3];
        [invocation getArgument:&completion atIndex:4];
        XCTAssertTrue(sut.loading);
        NSError *error = [NSError stp_genericFailedToParseResponseError];
        XCTAssertEqualObjects(token.tokenId, expectedToken.tokenId);
        completion(error);
        XCTAssertFalse(sut.loading);
        [didCreateTokenExp fulfill];
    });

    // tap next button
    UIBarButtonItem *nextButton = sut.navigationItem.rightBarButtonItem;
    [nextButton.target performSelector:nextButton.action withObject:nextButton];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testNextWithCreateTokenSuccessAndDidCreateTokenSuccess {
    STPAddCardViewController *sut = [self buildAddCardViewController];

    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    id mockDelegate = OCMProtocolMock(@protocol(STPAddCardViewControllerDelegate));
    sut.apiClient = mockAPIClient;
    sut.delegate = mockDelegate;
    STPCardParams *expectedCardParams = [STPFixtures cardParams];
    sut.paymentCell.paymentField.cardParams = expectedCardParams;

    STPToken *expectedToken = [STPToken new];
    expectedToken.tokenId = @"tok_123";
    XCTestExpectation *createTokenExp = [self expectationWithDescription:@"createTokenWithCard"];
    OCMStub([mockAPIClient createTokenWithCard:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPCardParams *cardParams;
        STPTokenCompletionBlock completion;
        [invocation getArgument:&cardParams atIndex:2];
        [invocation getArgument:&completion atIndex:3];
        XCTAssertEqualObjects(cardParams.number, expectedCardParams.number);
        XCTAssertTrue(sut.loading);
        completion(expectedToken, nil);
        [createTokenExp fulfill];
    });

    XCTestExpectation *didCreateTokenExp = [self expectationWithDescription:@"didCreateToken"];
    OCMStub([mockDelegate addCardViewController:[OCMArg any] didCreateToken:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPToken *token;
        STPErrorBlock completion;
        [invocation getArgument:&token atIndex:3];
        [invocation getArgument:&completion atIndex:4];
        XCTAssertTrue(sut.loading);
        XCTAssertEqualObjects(token.tokenId, expectedToken.tokenId);
        completion(nil);
        XCTAssertFalse(sut.loading);
        [didCreateTokenExp fulfill];
    });

    // tap next button
    UIBarButtonItem *nextButton = sut.navigationItem.rightBarButtonItem;
    [nextButton.target performSelector:nextButton.action withObject:nextButton];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

#pragma clang diagnostic pop

@end
