//
//  STPInitialPaymentDetailsCoordinatorTests.m
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 3/29/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Stripe/Stripe.h>
#import "MockSTPAPIClient.h"
#import "MockSTPSourceProvider.h"
#import "MockSTPCoordinatorDelegate.h"

@interface STPInitialPaymentDetailsCoordinator()<STPEmailEntryViewControllerDelegate, STPPaymentCardEntryViewControllerDelegate>
@end

@interface STPInitialPaymentDetailsCoordinatorTests : XCTestCase

@property (nonatomic, strong) STPInitialPaymentDetailsCoordinator *sut;
@property (nonatomic, strong) UINavigationController *navigationController;
@property (nonatomic, strong) MockSTPAPIClient *apiClient;
@property (nonatomic, strong) MockSTPSourceProvider *sourceProvider;
@property (nonatomic, strong) MockSTPCoordinatorDelegate *delegate;
@property (nonatomic, strong) STPCardParams *card;

@end

@implementation STPInitialPaymentDetailsCoordinatorTests

- (void)setUp {
    [super setUp];
    self.navigationController = [UINavigationController new];
    self.apiClient = [[MockSTPAPIClient alloc] initWithPublishableKey:@"foo"];
    self.sourceProvider = [MockSTPSourceProvider new];
    self.delegate = [MockSTPCoordinatorDelegate new];
    self.sut = [[STPInitialPaymentDetailsCoordinator alloc] initWithNavigationController:self.navigationController
                                                                               apiClient:self.apiClient
                                                                          sourceProvider:self.sourceProvider
                                                                                delegate:self.delegate];
    STPCardParams *card = [[STPCardParams alloc] init];
    card.number = @"4242 4242 4242 4242";
    card.expMonth = 6;
    card.expYear = 2018;
    card.currency = @"usd";
    self.card = card;
}

- (void)tearDown {
    [super tearDown];
    self.navigationController = nil;
    self.apiClient = nil;
    self.sourceProvider = nil;
    self.delegate = nil;
    self.sut = nil;
    self.card = nil;
}

- (void)testBeginShowsEmailEntryVC {
    [self.sut begin];
    UIViewController *topVC = self.sut.navigationController.topViewController;
    XCTAssertTrue([topVC isKindOfClass:[STPEmailEntryViewController class]]);
}

- (void)testCancelEmailEntryTellsDelegate {
    XCTestExpectation *exp = [self expectationWithDescription:@"cancel"];
    self.delegate.onDidCancel = ^(){ [exp fulfill]; };

    [self.sut emailEntryViewControllerDidCancel:nil];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testEnterEmailPushesPaymentCardVC {
    XCTestExpectation *exp = [self expectationWithDescription:@"completion"];
    [self.sut emailEntryViewController:nil didEnterEmailAddress:@"bg@stripe.com" completion:^(NSError * _Nullable error) {
        UIViewController *topVC = self.sut.navigationController.topViewController;
        XCTAssertTrue([topVC isKindOfClass:[STPPaymentCardEntryViewController class]]);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testCancelPaymentCardEntryTellsDelegate {
    XCTestExpectation *exp = [self expectationWithDescription:@"cancel"];
    self.delegate.onDidCancel = ^(){ [exp fulfill]; };

    [self.sut paymentCardEntryViewControllerDidCancel:nil];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testEnteringCardParams_success {
    self.apiClient.createTokenWithCardBlock = ^(STPCardParams *card, STPTokenCompletionBlock completion) {
        STPToken *token = [STPToken new];
        completion(token, nil);
    };
    XCTestExpectation *willFinishExp = [self expectationWithDescription:@"finish"];
    XCTestExpectation *completionExp = [self expectationWithDescription:@"completion"];
    __weak id weakSelf = self;
    self.delegate.onWillFinishWithCompletion = ^(STPErrorBlock completion) {
        id self = weakSelf;
        XCTAssertNil(completion);
        [willFinishExp fulfill];
    };

    [self.sut emailEntryViewController:nil didEnterEmailAddress:@"bg@stripe.com" completion:^(NSError * _Nullable error) {
        [self.sut paymentCardEntryViewController:nil didEnterCardParams:self.card completion:^(NSError * _Nullable error) {
            [completionExp fulfill];
        }];
     }];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testEnteringCardParams_apiClientError {
    NSError *expectedError = [[NSError alloc] initWithDomain:@"foo" code:123 userInfo:@{}];
    self.apiClient.createTokenWithCardBlock = ^(STPCardParams *card, STPTokenCompletionBlock completion) {
        completion(nil, expectedError);
    };
    __weak id weakSelf = self;
    self.delegate.onWillFinishWithCompletion = ^(STPErrorBlock completion) {
        id self = weakSelf;
        XCTFail("should not be called");
    };

    XCTestExpectation *exp = [self expectationWithDescription:@"completion"];
    [self.sut emailEntryViewController:nil didEnterEmailAddress:@"bg@stripe.com" completion:^(NSError * _Nullable error) {
        [self.sut paymentCardEntryViewController:nil didEnterCardParams:self.card completion:^(NSError * _Nullable error) {
            XCTAssertEqualObjects(error, expectedError);
            [exp fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testEnteringCardParams_sourceProviderError {
    NSError *expectedError = [[NSError alloc] initWithDomain:@"foo" code:123 userInfo:@{}];
    self.sourceProvider.addSourceError = expectedError;
    __weak id weakSelf = self;
    self.apiClient.createTokenWithCardBlock = ^(STPCardParams *card, STPTokenCompletionBlock completion) {
        STPToken *token = [STPToken new];
        completion(token, nil);
    };
    self.delegate.onWillFinishWithCompletion = ^(STPErrorBlock completion) {
        id self = weakSelf;
        XCTFail("should not be called");
    };

    XCTestExpectation *exp = [self expectationWithDescription:@"completion"];
    [self.sut emailEntryViewController:nil didEnterEmailAddress:@"bg@stripe.com" completion:^(NSError * _Nullable error) {
        [self.sut paymentCardEntryViewController:nil didEnterCardParams:self.card completion:^(NSError * _Nullable error) {
            XCTAssertEqualObjects(error, expectedError);
            [exp fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
