//
//  STPPaymentAuthorizationCoordinatorTests.m
//  Stripe
//
//  Created by Ben Guo on 4/11/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <PassKit/PassKit.h>
#import "MockSTPAPIClient.h"
#import "MockSTPBackendAPIAdapter.h"
#import "MockSTPCoordinatorDelegate.h"
#import "MockUINavigationController.h"
#import "STPSourceListViewController.h"
#import "STPPaymentSummaryViewController.h"
#import "STPPaymentCardEntryViewController.h"
#import "STPShippingEntryViewController.h"
#import "STPPaymentAuthorizationCoordinator.h"
#import "STPInitialPaymentDetailsCoordinator.h"

@interface STPBaseCoordinator()
@property(nonatomic) NSMutableArray<STPBaseCoordinator *> *childCoordinators;
@end

@interface STPPaymentSummaryViewController()
@property(nonatomic, nonnull) PKPaymentRequest *paymentRequest;
@property(nonatomic, nonnull, readonly) id<STPBackendAPIAdapter> apiAdapter;
@end

@interface STPSourceListViewController()
@property(nonatomic) id<STPBackendAPIAdapter> apiAdapter;
@end

@interface STPPaymentAuthorizationCoordinator()<STPCoordinatorDelegate, STPPaymentSummaryViewControllerDelegate, STPShippingEntryViewControllerDelegate>
@property(nonatomic, readonly)UINavigationController *navigationController;
@property(nonatomic, readonly)id<STPBackendAPIAdapter> apiAdapter;
@end

@interface STPPaymentAuthorizationCoordinatorTests : XCTestCase

@property (nonatomic, strong) STPPaymentAuthorizationCoordinator *sut;
@property (nonatomic, strong) MockUINavigationController *navigationController;
@property (nonatomic, strong) MockSTPAPIClient *apiClient;
@property (nonatomic, strong) MockSTPBackendAPIAdapter *apiAdapter;
@property (nonatomic, strong) MockSTPCoordinatorDelegate *delegate;
@property (nonatomic, strong) PKPaymentRequest *paymentRequest;

@end

@implementation STPPaymentAuthorizationCoordinatorTests

- (void)setUp {
    [super setUp];
    self.navigationController = [MockUINavigationController new];
    self.apiClient = [[MockSTPAPIClient alloc] initWithPublishableKey:@"foo"];
    self.apiAdapter = [MockSTPBackendAPIAdapter new];
    self.delegate = [MockSTPCoordinatorDelegate new];
    self.paymentRequest = [[PKPaymentRequest alloc] init];
    self.paymentRequest.merchantIdentifier = @"foo";
    self.sut = [[STPPaymentAuthorizationCoordinator alloc] initWithNavigationController:self.navigationController
                                                               paymentRequest:self.paymentRequest
                                                                    apiClient:self.apiClient
                                                               apiAdapter:self.apiAdapter
                                                                     delegate:self.delegate];
}

- (void)tearDown {
    [super tearDown];
    self.navigationController = nil;
    self.apiClient = nil;
    self.apiAdapter = nil;
    self.delegate = nil;
    self.sut = nil;
    self.paymentRequest = nil;
}

- (void)testBeginShowsPaymentCardEntryVC {
    [self.sut begin];
    UIViewController *topVC = self.sut.navigationController.topViewController;
    XCTAssertTrue([topVC isKindOfClass:[STPPaymentCardEntryViewController class]]);
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
        _XCTPrimitiveAssertEqualObjects(weakSelf, summaryVC.apiAdapter, @"", weakSelf.apiAdapter, @"");
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

- (void)testEditPaymentMethodPresentsSourceListVC {
    XCTestExpectation *pushExp = [self expectationWithDescription:@"push"];
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
        _XCTPrimitiveAssertEqualObjects(weakSelf, sourceListVC.apiAdapter, @"", weakSelf.apiAdapter, @"");
        _XCTPrimitiveAssertTrue(weakSelf, animated, @"");
        [pushExp fulfill];
    };

    [self.sut begin];
    STPBaseCoordinator *initialCoordinator = [self.sut.childCoordinators firstObject];
    [self.sut coordinator:initialCoordinator willFinishWithCompletion:nil];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testEditShippingPresentsShippingVC {
    self.paymentRequest.requiredShippingAddressFields = PKAddressFieldPhone;
    XCTestExpectation *pushExp = [self expectationWithDescription:@"push"];
    __weak typeof(self) weakSelf = self;
    __block BOOL isSecondCall = false;
    self.navigationController.onPushViewController = ^(UIViewController *vc, BOOL animated) {
        if (!isSecondCall) {
            _XCTPrimitiveAssertTrue(weakSelf, [vc isKindOfClass:[STPPaymentSummaryViewController class]], @"");
            STPPaymentSummaryViewController *summaryVC = (STPPaymentSummaryViewController *)vc;
            [weakSelf.sut paymentSummaryViewControllerDidEditShipping:summaryVC];
            isSecondCall = true;
            return;
        }
        _XCTPrimitiveAssertTrue(weakSelf, [vc isKindOfClass:[STPShippingEntryViewController class]], @"");
        _XCTPrimitiveAssertTrue(weakSelf, animated, @"");
        [pushExp fulfill];
    };

    [self.sut begin];
    STPBaseCoordinator *initialCoordinator = [self.sut.childCoordinators firstObject];
    [self.sut coordinator:initialCoordinator willFinishWithCompletion:nil];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testCancelShippingPopsShippingVC {
    STPAddress *originalShipping = [STPAddress new];
    originalShipping.name = @"foo";
    self.apiAdapter.shippingAddress = originalShipping;
    self.paymentRequest.requiredShippingAddressFields = PKAddressFieldPhone;
    XCTestExpectation *pushExp = [self expectationWithDescription:@"push"];
    XCTestExpectation *popExp = [self expectationWithDescription:@"pop"];
    __weak typeof(self) weakSelf = self;
    __block BOOL isSecondCall = false;
    self.navigationController.onPushViewController = ^(UIViewController *vc, BOOL animated) {
        if (!isSecondCall) {
            _XCTPrimitiveAssertTrue(weakSelf, [vc isKindOfClass:[STPPaymentSummaryViewController class]], @"");
            STPPaymentSummaryViewController *summaryVC = (STPPaymentSummaryViewController *)vc;
            [weakSelf.sut paymentSummaryViewControllerDidEditShipping:summaryVC];
            isSecondCall = true;
            return;
        }
        _XCTPrimitiveAssertTrue(weakSelf, [vc isKindOfClass:[STPShippingEntryViewController class]], @"");
        _XCTPrimitiveAssertTrue(weakSelf, animated, @"");
        [weakSelf.sut shippingEntryViewControllerDidCancel:(STPShippingEntryViewController *)vc];
        [pushExp fulfill];
    };
    self.navigationController.onPopViewController = ^(BOOL animated) {
        _XCTPrimitiveAssertTrue(weakSelf, animated, @"");
        _XCTPrimitiveAssertEqual(weakSelf, weakSelf.sut.apiAdapter.shippingAddress.name, @"", @"foo", @"");
        [popExp fulfill];
    };

    [self.sut begin];
    STPBaseCoordinator *initialCoordinator = [self.sut.childCoordinators firstObject];
    [self.sut coordinator:initialCoordinator willFinishWithCompletion:nil];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testEnterShipping_success {
    STPAddress *originalShipping = [STPAddress new];
    originalShipping.name = @"foo";
    self.apiAdapter.shippingAddress = originalShipping;
    self.paymentRequest.requiredShippingAddressFields = PKAddressFieldPhone;
    XCTestExpectation *pushExp = [self expectationWithDescription:@"push"];
    XCTestExpectation *completionExp = [self expectationWithDescription:@"completion"];
    XCTestExpectation *popExp = [self expectationWithDescription:@"pop"];
    __weak typeof(self) weakSelf = self;
    __block BOOL isSecondCall = false;
    self.navigationController.onPushViewController = ^(UIViewController *vc, BOOL animated) {
        if (!isSecondCall) {
            _XCTPrimitiveAssertTrue(weakSelf, [vc isKindOfClass:[STPPaymentSummaryViewController class]], @"");
            STPPaymentSummaryViewController *summaryVC = (STPPaymentSummaryViewController *)vc;
            [weakSelf.sut paymentSummaryViewControllerDidEditShipping:summaryVC];
            isSecondCall = true;
            return;
        }
        _XCTPrimitiveAssertTrue(weakSelf, [vc isKindOfClass:[STPShippingEntryViewController class]], @"");
        _XCTPrimitiveAssertTrue(weakSelf, animated, @"");
        STPAddress *newShipping = [STPAddress new];
        newShipping.name = @"bar";
        [weakSelf.sut shippingEntryViewController:(STPShippingEntryViewController *)vc didEnterShippingAddress:newShipping completion:^(NSError * error) {
            _XCTPrimitiveAssertNil(weakSelf, error, @"");
            [completionExp fulfill];
        }];
        [pushExp fulfill];
    };
    self.navigationController.onPopViewController = ^(BOOL animated) {
        _XCTPrimitiveAssertTrue(weakSelf, animated, @"");
        _XCTPrimitiveAssertEqual(weakSelf, weakSelf.sut.apiAdapter.shippingAddress.name, @"", @"bar", @"");
        [popExp fulfill];
    };

    [self.sut begin];
    STPBaseCoordinator *initialCoordinator = [self.sut.childCoordinators firstObject];
    [self.sut coordinator:initialCoordinator willFinishWithCompletion:nil];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testEnterShipping_error {
    STPAddress *originalShipping = [STPAddress new];
    originalShipping.name = @"foo";
    self.apiAdapter.shippingAddress = originalShipping;
    NSError *expectedError = [NSError errorWithDomain:@"foo" code:0 userInfo:nil];
    self.apiAdapter.updateCustomerShippingError = expectedError;
    self.paymentRequest.requiredShippingAddressFields = PKAddressFieldPhone;
    XCTestExpectation *pushExp = [self expectationWithDescription:@"push"];
    XCTestExpectation *completionExp = [self expectationWithDescription:@"completion"];
    __weak typeof(self) weakSelf = self;
    __block BOOL isSecondCall = false;
    self.navigationController.onPushViewController = ^(UIViewController *vc, BOOL animated) {
        if (!isSecondCall) {
            _XCTPrimitiveAssertTrue(weakSelf, [vc isKindOfClass:[STPPaymentSummaryViewController class]], @"");
            STPPaymentSummaryViewController *summaryVC = (STPPaymentSummaryViewController *)vc;
            [weakSelf.sut paymentSummaryViewControllerDidEditShipping:summaryVC];
            isSecondCall = true;
            return;
        }
        _XCTPrimitiveAssertTrue(weakSelf, [vc isKindOfClass:[STPShippingEntryViewController class]], @"");
        _XCTPrimitiveAssertTrue(weakSelf, animated, @"");
        STPAddress *newShipping = [STPAddress new];
        newShipping.name = @"bar";
        [weakSelf.sut shippingEntryViewController:(STPShippingEntryViewController *)vc didEnterShippingAddress:newShipping completion:^(NSError * error) {
            _XCTPrimitiveAssertEqualObjects(weakSelf, error, @"", expectedError, @"");
            _XCTPrimitiveAssertEqual(weakSelf, weakSelf.sut.apiAdapter.shippingAddress.name, @"", @"foo", @"");
            [completionExp fulfill];
        }];
        [pushExp fulfill];
    };
    self.navigationController.onPopViewController = ^(__unused BOOL animated) {
        _XCTPrimitiveFail(weakSelf, @"should not be called");
    };

    [self.sut begin];
    STPBaseCoordinator *initialCoordinator = [self.sut.childCoordinators firstObject];
    [self.sut coordinator:initialCoordinator willFinishWithCompletion:nil];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testCancelSummaryVC {
    XCTestExpectation *pushExp = [self expectationWithDescription:@"push"];
    XCTestExpectation *cancelExp = [self expectationWithDescription:@"cancel"];
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
    [self.sut coordinator:initialCoordinator willFinishWithCompletion:nil];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testBuy_success {
    XCTestExpectation *pushExp = [self expectationWithDescription:@"push"];
    XCTestExpectation *willFinishExp = [self expectationWithDescription:@"willFinish"];
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
    [self.sut coordinator:initialCoordinator willFinishWithCompletion:nil];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testBuy_error {
    XCTestExpectation *pushExp = [self expectationWithDescription:@"push"];
    XCTestExpectation *willFinishExp = [self expectationWithDescription:@"willFinish"];
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
    [self.sut coordinator:initialCoordinator willFinishWithCompletion:nil];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
