//
//  STPPaymentAuthorizationCoordinatorTests.m
//  Stripe
//
//  Created by Ben Guo on 4/11/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPPaymentRequest.h"
#import "MockSTPAPIClient.h"
#import "MockSTPSourceProvider.h"
#import "MockSTPCoordinatorDelegate.h"
#import "MockUINavigationController.h"
#import "STPEmailEntryViewController.h"
#import "STPSourceListViewController.h"
#import "STPPaymentSummaryViewController.h"
#import "STPPaymentAuthorizationCoordinator.h"
#import "STPInitialPaymentDetailsCoordinator.h"

@interface STPBaseCoordinator()
@property(nonatomic) NSMutableArray<STPBaseCoordinator *> *childCoordinators;
@end

@interface STPPaymentSummaryViewController()
@property(nonatomic, nonnull) STPPaymentRequest *paymentRequest;
@property(nonatomic, nonnull, readonly) id<STPSourceProvider> sourceProvider;
@end

@interface STPSourceListViewController()
@property(nonatomic) id<STPSourceProvider> sourceProvider;
@end

@interface STPPaymentAuthorizationCoordinator()<STPCoordinatorDelegate, STPPaymentSummaryViewControllerDelegate>
@end

@interface STPPaymentAuthorizationCoordinatorTests : XCTestCase

@property (nonatomic, strong) STPPaymentAuthorizationCoordinator *sut;
@property (nonatomic, strong) MockUINavigationController *navigationController;
@property (nonatomic, strong) MockSTPAPIClient *apiClient;
@property (nonatomic, strong) MockSTPSourceProvider *sourceProvider;
@property (nonatomic, strong) MockSTPCoordinatorDelegate *delegate;
@property (nonatomic, strong) STPPaymentRequest *paymentRequest;

@end

@implementation STPPaymentAuthorizationCoordinatorTests

- (void)setUp {
    [super setUp];
    self.navigationController = [MockUINavigationController new];
    self.apiClient = [[MockSTPAPIClient alloc] initWithPublishableKey:@"foo"];
    self.sourceProvider = [MockSTPSourceProvider new];
    self.delegate = [MockSTPCoordinatorDelegate new];
    self.paymentRequest = [[STPPaymentRequest alloc] init];
    self.paymentRequest.appleMerchantId = @"foo";
    self.sut = [[STPPaymentAuthorizationCoordinator alloc] initWithNavigationController:self.navigationController
                                                               paymentRequest:self.paymentRequest
                                                                    apiClient:self.apiClient
                                                               sourceProvider:self.sourceProvider
                                                                     delegate:self.delegate];
}

- (void)tearDown {
    [super tearDown];
    self.navigationController = nil;
    self.apiClient = nil;
    self.sourceProvider = nil;
    self.delegate = nil;
    self.sut = nil;
    self.paymentRequest = nil;
}

- (void)testBeginShowsEmailEntryVC {
    [self.sut begin];
    UIViewController *topVC = self.sut.navigationController.topViewController;
    XCTAssertTrue([topVC isKindOfClass:[STPEmailEntryViewController class]]);
    STPBaseCoordinator *initialCoordinator = [self.sut.childCoordinators firstObject];
    XCTAssertTrue([initialCoordinator isKindOfClass:[STPInitialPaymentDetailsCoordinator class]]);
}

- (void)testCancelInitialCoordinator {
    XCTestExpectation *exp = [self expectationWithDescription:@"cancel"];
    self.delegate.onDidCancel = ^(){ [exp fulfill]; };

    [self.sut begin];
    STPBaseCoordinator *initialCoordinator = [self.sut.childCoordinators firstObject];
    [self.sut coordinatorDidCancel:initialCoordinator];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testFinishInitialCoordinator {
    XCTestExpectation *pushExp = [self expectationWithDescription:@"push"];
    XCTestExpectation *completionExp = [self expectationWithDescription:@"completion"];
    __weak typeof(self) weakSelf = self;
    self.navigationController.onPushViewController = ^(UIViewController *vc, BOOL animated) {
        _XCTPrimitiveAssertTrue(weakSelf, [vc isKindOfClass:[STPPaymentSummaryViewController class]], @"");
        STPPaymentSummaryViewController *summaryVC = (STPPaymentSummaryViewController *)vc;
        _XCTPrimitiveAssertEqualObjects(weakSelf, summaryVC.paymentRequest, @"", weakSelf.paymentRequest, @"");
        _XCTPrimitiveAssertEqualObjects(weakSelf, summaryVC.sourceProvider, @"", weakSelf.sourceProvider, @"");
        _XCTPrimitiveAssertTrue(weakSelf, animated, @"");
        [pushExp fulfill];
    };

    [self.sut begin];
    STPBaseCoordinator *initialCoordinator = [self.sut.childCoordinators firstObject];
    [self.sut coordinator:initialCoordinator willFinishWithCompletion:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [completionExp fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testEditPresentsSourceListVC {
    XCTestExpectation *pushExp = [self expectationWithDescription:@"push"];
    XCTestExpectation *completionExp = [self expectationWithDescription:@"completion"];
    __weak typeof(self) weakSelf = self;
    __block BOOL isSecondCall = false;
    self.navigationController.onPushViewController = ^(UIViewController *vc, BOOL animated) {
        if (!isSecondCall) {
            _XCTPrimitiveAssertTrue(weakSelf, [vc isKindOfClass:[STPPaymentSummaryViewController class]], @"");
            STPPaymentSummaryViewController *summaryVC = (STPPaymentSummaryViewController *)vc;
            [weakSelf.sut paymentSummaryViewControllerDidEditPaymentMethod:summaryVC];
            isSecondCall = true;
            return;
        }
        _XCTPrimitiveAssertTrue(weakSelf, [vc isKindOfClass:[STPSourceListViewController class]], @"");
        STPSourceListViewController *sourceListVC = (STPSourceListViewController *)vc;
        _XCTPrimitiveAssertEqualObjects(weakSelf, sourceListVC.sourceProvider, @"", weakSelf.sourceProvider, @"");
        _XCTPrimitiveAssertTrue(weakSelf, animated, @"");
        [pushExp fulfill];
    };

    [self.sut begin];
    STPBaseCoordinator *initialCoordinator = [self.sut.childCoordinators firstObject];
    [self.sut coordinator:initialCoordinator willFinishWithCompletion:^(__unused NSError * _Nullable error) {
        [completionExp fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testCancelSummaryVC {
    XCTestExpectation *pushExp = [self expectationWithDescription:@"push"];
    XCTestExpectation *cancelExp = [self expectationWithDescription:@"cancel"];
    XCTestExpectation *completionExp = [self expectationWithDescription:@"completion"];
    self.delegate.onDidCancel = ^(){ [cancelExp fulfill]; };
    __weak typeof(self) weakSelf = self;
    self.navigationController.onPushViewController = ^(UIViewController *vc, __unused BOOL animated) {
        _XCTPrimitiveAssertTrue(weakSelf, [vc isKindOfClass:[STPPaymentSummaryViewController class]], @"");
        STPPaymentSummaryViewController *summaryVC = (STPPaymentSummaryViewController *)vc;
        [weakSelf.sut paymentSummaryViewControllerDidCancel:summaryVC];
        [pushExp fulfill];
    };

    [self.sut begin];
    STPBaseCoordinator *initialCoordinator = [self.sut.childCoordinators firstObject];
    [self.sut coordinator:initialCoordinator willFinishWithCompletion:^(__unused NSError * _Nullable error) {
        [completionExp fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testBuy_success {
    XCTestExpectation *pushExp = [self expectationWithDescription:@"push"];
    XCTestExpectation *willFinishExp = [self expectationWithDescription:@"willFinish"];
    XCTestExpectation *initialCompletionExp = [self expectationWithDescription:@"initial completion"];
    XCTestExpectation *completionExp = [self expectationWithDescription:@"completion"];
    self.delegate.onWillFinishWithCompletion = ^(STPErrorBlock completion){
        [willFinishExp fulfill];
        completion(nil);
    };
    __weak typeof(self) weakSelf = self;
    self.navigationController.onPushViewController = ^(UIViewController *vc, __unused BOOL animated) {
        _XCTPrimitiveAssertTrue(weakSelf, [vc isKindOfClass:[STPPaymentSummaryViewController class]], @"");
        STPPaymentSummaryViewController *summaryVC = (STPPaymentSummaryViewController *)vc;
        [weakSelf.sut paymentSummaryViewController:summaryVC didPressBuyCompletion:^(NSError * _Nullable error) {
            _XCTPrimitiveAssertNil(weakSelf, error, @"");
            [completionExp fulfill];
        }];
        [pushExp fulfill];
    };

    [self.sut begin];
    STPBaseCoordinator *initialCoordinator = [self.sut.childCoordinators firstObject];
    [self.sut coordinator:initialCoordinator willFinishWithCompletion:^(__unused NSError * _Nullable error) {
        [initialCompletionExp fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testBuy_error {
    XCTestExpectation *pushExp = [self expectationWithDescription:@"push"];
    XCTestExpectation *willFinishExp = [self expectationWithDescription:@"willFinish"];
    XCTestExpectation *initialCompletionExp = [self expectationWithDescription:@"initial completion"];
    XCTestExpectation *completionExp = [self expectationWithDescription:@"completion"];
    NSError *expectedError = [[NSError alloc] initWithDomain:@"foo" code:123 userInfo:@{}];
    self.delegate.onWillFinishWithCompletion = ^(STPErrorBlock completion){
        [willFinishExp fulfill];
        completion(expectedError);
    };
    __weak typeof(self) weakSelf = self;
    self.navigationController.onPushViewController = ^(UIViewController *vc, __unused BOOL animated) {
        _XCTPrimitiveAssertTrue(weakSelf, [vc isKindOfClass:[STPPaymentSummaryViewController class]], @"");
        STPPaymentSummaryViewController *summaryVC = (STPPaymentSummaryViewController *)vc;
        [weakSelf.sut paymentSummaryViewController:summaryVC didPressBuyCompletion:^(NSError * _Nullable error) {
            _XCTPrimitiveAssertEqualObjects(weakSelf, error, @"", expectedError, @"");
            [completionExp fulfill];
        }];
        [pushExp fulfill];
    };

    [self.sut begin];
    STPBaseCoordinator *initialCoordinator = [self.sut.childCoordinators firstObject];
    [self.sut coordinator:initialCoordinator willFinishWithCompletion:^(__unused NSError * _Nullable error) {
        [initialCompletionExp fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
