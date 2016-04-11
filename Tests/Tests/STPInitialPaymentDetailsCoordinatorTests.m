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
#import "MockUINavigationController.h"
#import "STPEmailEntryViewController.h"
#import "STPPaymentCardEntryViewController.h"
#import "STPInitialPaymentDetailsCoordinator.h"

@interface STPInitialPaymentDetailsCoordinator()<STPEmailEntryViewControllerDelegate, STPPaymentCardEntryViewControllerDelegate>
@end

@interface STPInitialPaymentDetailsCoordinatorTests : XCTestCase

@property (nonatomic, strong) STPInitialPaymentDetailsCoordinator *sut;
@property (nonatomic, strong) MockUINavigationController *navigationController;
@property (nonatomic, strong) MockSTPAPIClient *apiClient;
@property (nonatomic, strong) MockSTPSourceProvider *sourceProvider;
@property (nonatomic, strong) MockSTPCoordinatorDelegate *delegate;
@property (nonatomic, strong) STPCardParams *card;

@end

@implementation STPInitialPaymentDetailsCoordinatorTests

- (void)setUp {
    [super setUp];
    self.navigationController = [MockUINavigationController new];
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

- (void)testCancelEmailEntry {
    XCTestExpectation *exp = [self expectationWithDescription:@"cancel"];
    self.delegate.onDidCancel = ^(){ [exp fulfill]; };

    [self.sut emailEntryViewControllerDidCancel:nil];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testEnterEmailPushesPaymentCardVC {
    XCTestExpectation *exp = [self expectationWithDescription:@"completion"];
    [self.sut emailEntryViewController:nil didEnterEmailAddress:@"bg@stripe.com" completion:^(__unused NSError * _Nullable error) {
        UIViewController *topVC = self.sut.navigationController.topViewController;
        XCTAssertTrue([topVC isKindOfClass:[STPPaymentCardEntryViewController class]]);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testCancelCardEntry {
    XCTestExpectation *exp = [self expectationWithDescription:@"cancel"];
    self.delegate.onDidCancel = ^(){ [exp fulfill]; };

    [self.sut paymentCardEntryViewControllerDidCancel:nil];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testEnterCard_success {
    self.apiClient.createTokenWithCardBlock = ^(__unused STPCardParams *card, STPTokenCompletionBlock completion) {
        STPToken *token = [STPToken new];
        completion(token, nil);
    };
    XCTestExpectation *willFinishExp = [self expectationWithDescription:@"finish"];
    XCTestExpectation *completionExp = [self expectationWithDescription:@"completion"];
    __weak id weakSelf = self;
    self.delegate.onWillFinishWithCompletion = ^(STPErrorBlock completion) {
        _XCTPrimitiveAssertNil(weakSelf, completion, @"completion should be nil");
        [willFinishExp fulfill];
    };

    [self.sut emailEntryViewController:nil didEnterEmailAddress:@"bg@stripe.com" completion:^(__unused NSError * _Nullable error) {
        [self.sut paymentCardEntryViewController:nil didEnterCardParams:self.card completion:^(__unused NSError * _Nullable paramsError) {
            [completionExp fulfill];
        }];
     }];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testEnterCard_apiClientError {
    NSError *expectedError = [[NSError alloc] initWithDomain:@"foo" code:123 userInfo:@{}];
    self.apiClient.createTokenWithCardBlock = ^(__unused STPCardParams *card, STPTokenCompletionBlock completion) {
        completion(nil, expectedError);
    };
    __weak id weakSelf = self;
    self.delegate.onWillFinishWithCompletion = ^(__unused STPErrorBlock completion) {
        _XCTPrimitiveFail(weakSelf, "should not be called");
    };

    XCTestExpectation *exp = [self expectationWithDescription:@"completion"];
    [self.sut emailEntryViewController:nil didEnterEmailAddress:@"bg@stripe.com" completion:^(__unused NSError * _Nullable emailError) {
        [self.sut paymentCardEntryViewController:nil didEnterCardParams:self.card completion:^(NSError * _Nullable error) {
            XCTAssertEqualObjects(error, expectedError);
            [exp fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testEnterCard_sourceProviderError {
    NSError *expectedError = [[NSError alloc] initWithDomain:@"foo" code:123 userInfo:@{}];
    self.sourceProvider.addSourceError = expectedError;
    __weak id weakSelf = self;
    self.apiClient.createTokenWithCardBlock = ^(__unused STPCardParams *card, STPTokenCompletionBlock completion) {
        STPToken *token = [STPToken new];
        completion(token, nil);
    };
    self.delegate.onWillFinishWithCompletion = ^(__unused STPErrorBlock completion) {
        _XCTPrimitiveFail(weakSelf, "should not be called");
    };

    XCTestExpectation *exp = [self expectationWithDescription:@"completion"];
    [self.sut emailEntryViewController:nil didEnterEmailAddress:@"bg@stripe.com" completion:^(__unused NSError * _Nullable emailError) {
        [self.sut paymentCardEntryViewController:nil didEnterCardParams:self.card completion:^(NSError * _Nullable error) {
            XCTAssertEqualObjects(error, expectedError);
            [exp fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
