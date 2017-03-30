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
#import "STPCard.h"
#import "STPCheckoutAccount.h"
#import "STPFixtures.h"
#import "STPRememberMePaymentCell.h"

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

- (STPAddCardViewController *)buildAddCardViewController {
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.requiredBillingAddressFields = STPBillingAddressFieldsFull;
    STPTheme *theme = [STPTheme defaultTheme];
    STPAddCardViewController *vc = [[STPAddCardViewController alloc] initWithConfiguration:config
                                                                                     theme:theme];
    XCTAssertNotNil(vc.view);
    return vc;
}

- (BOOL)cardParams:(STPCardParams *)params matchCardParams:(STPCardParams *)otherParams {
    return ([params.number isEqualToString:otherParams.number] &&
            [params.cvc isEqualToString:otherParams.cvc] &&
            (params.expMonth == otherParams.expMonth) &&
            (params.expYear == otherParams.expYear) &&
            [params.addressLine1 isEqualToString:otherParams.addressLine1] &&
            [params.addressLine2 isEqualToString:otherParams.addressLine2] &&
            [params.addressCity isEqualToString:otherParams.addressCity] &&
            [params.addressState isEqualToString:otherParams.addressState] &&
            [params.addressCountry isEqualToString:otherParams.addressCountry] &&
            [params.addressZip isEqualToString:otherParams.addressZip]);
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

- (void)testNextWithCreateTokenError {
    STPAddCardViewController *sut = [self buildAddCardViewController];
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    sut.apiClient = mockAPIClient;
    STPCardParams *expectedCardParams = [STPFixtures cardParams];
    sut.paymentCell.paymentField.cardParams = expectedCardParams;

    XCTestExpectation *exp = [self expectationWithDescription:@"createTokenWithCard"];
    OCMStub([mockAPIClient createTokenWithCard:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPCardParams *cardParams;
        STPTokenCompletionBlock completion;
        [invocation getArgument:&cardParams atIndex:2];
        [invocation getArgument:&completion atIndex:3];
        XCTAssertTrue([self cardParams:cardParams matchCardParams:expectedCardParams]);
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

    STPToken *expectedToken = [STPFixtures cardToken];
    XCTestExpectation *createTokenExp = [self expectationWithDescription:@"createTokenWithCard"];
    OCMStub([mockAPIClient createTokenWithCard:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPCardParams *cardParams;
        STPTokenCompletionBlock completion;
        [invocation getArgument:&cardParams atIndex:2];
        [invocation getArgument:&completion atIndex:3];
        XCTAssertTrue([self cardParams:cardParams matchCardParams:expectedCardParams]);
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

    STPToken *expectedToken = [STPFixtures cardToken];
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
