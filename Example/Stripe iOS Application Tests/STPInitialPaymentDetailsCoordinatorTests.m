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
}

- (void)tearDown {
    [super tearDown];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

- (void)testBeginShowsEmailEntryVC {
    [self.sut begin];
    XCTAssertEqual(self.sut.navigationController.viewControllers.count, 1);
    UIViewController *vc = [self.sut.navigationController.viewControllers firstObject];
    XCTAssertTrue([vc isKindOfClass:[STPEmailEntryViewController class]]);
}

- (void)testCancelEmailEntryTellsDelegate {
    XCTestExpectation *exp = [self expectationWithDescription:@"cancel"];
    self.delegate.onDidCancel = ^(){ [exp fulfill]; };

    [self.sut emailEntryViewControllerDidCancel:nil];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testCancelPaymentCardEntryTellsDelegate {
    XCTestExpectation *exp = [self expectationWithDescription:@"cancel"];
    self.delegate.onDidCancel = ^(){ [exp fulfill]; };

    [self.sut paymentCardEntryViewControllerDidCancel:nil];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

#pragma clang diagnostic pop

@end
