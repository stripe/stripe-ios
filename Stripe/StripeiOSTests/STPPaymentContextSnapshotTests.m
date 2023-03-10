//
//  STPPaymentContextSnapshotTests.m
//  StripeiOS Tests
//
//  Created by Ben Guo on 12/13/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <OCMock/OCMock.h>
#import "StripeiOS_Tests-Swift.h"

#import "STPFixtures.h"
#import "STPMocks.h"
#import "STPTestUtils.h"

@import iOSSnapshotTestCaseCore;

@interface STPPaymentContextSnapshotTests : FBSnapshotTestCase

@property (nonatomic, strong) STPCustomerContext *customerContext;
@property (nonatomic, strong) STPPaymentConfiguration *config;
@property (nonatomic, strong) UINavigationController *hostViewController;
@property (nonatomic, strong) STPPaymentContext *paymentContext;

@end

@implementation STPPaymentContextSnapshotTests

- (void)setUp {
    [super setUp];
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.companyName = @"Test Company";
    config.requiredBillingAddressFields = STPBillingAddressFieldsFull;
    config.shippingType = STPShippingTypeShipping;
    self.config = config;
    STPCustomerContext *customerContext = nil;
    if (@available(iOS 13.0, *)) {
        customerContext = [[Testing_StaticCustomerContext_Objc alloc] initWithCustomer:[STPFixtures customerWithCardTokenAndSourceSources] paymentMethods:@[[STPFixtures paymentMethod], [STPFixtures paymentMethod]]];
    } else {
        customerContext = [STPMocks staticCustomerContextWithCustomer:[STPFixtures customerWithCardTokenAndSourceSources] paymentMethods:@[[STPFixtures paymentMethod], [STPFixtures paymentMethod]]];
    }
    self.customerContext = customerContext;

    UIViewController *viewController = [UIViewController new];
    self.hostViewController = [self stp_navigationControllerForSnapshotTestWithRootVC:viewController];

//    self.recordMode = YES;
}

- (void)buildPaymentContext {
    STPPaymentContext *context = [[STPPaymentContext alloc] initWithCustomerContext:self.customerContext];
    context.hostViewController = self.hostViewController;
    context.configuration.requiredShippingAddressFields = [NSSet setWithArray:@[STPContactField.emailAddress]];
    self.paymentContext = context;
}

- (void)testPushPaymentOptionsSmallTitle {
    if (@available(iOS 12.0, *)) {
        [self buildPaymentContext];

        self.hostViewController.navigationBar.prefersLargeTitles = NO;
        self.paymentContext.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
        [self.paymentContext pushPaymentOptionsViewController];
        UIView *view = [self stp_preparedAndSizedViewForSnapshotTestFromNavigationController:self.hostViewController];
        STPSnapshotVerifyView(view, nil);
    }
}

// This test renders at a slightly larger size half the time.
// We're deprecating Basic Integration soon, and we've spent enough time on this,
// so these tests are being disabled for now.
//- (void)testPushPaymentOptionsLargeTitle {
//    if (@available(iOS 12.0, *)) {
//        [self buildPaymentContext];
//
//        self.hostViewController.navigationBar.prefersLargeTitles = YES;
//        self.paymentContext.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
//        [self.paymentContext pushPaymentOptionsViewController];
//        UIView *view = [self stp_preparedAndSizedViewForSnapshotTestFromNavigationController:self.hostViewController];
//        STPSnapshotVerifyView(view, nil);
//    }
//}

- (void)testPushShippingAddressSmallTitle {
    if (@available(iOS 12.0, *)) {
        [self buildPaymentContext];

        self.hostViewController.navigationBar.prefersLargeTitles = NO;
        self.paymentContext.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
        [self.paymentContext pushShippingViewController];
        UIView *view = [self stp_preparedAndSizedViewForSnapshotTestFromNavigationController:self.hostViewController];
        STPSnapshotVerifyView(view, nil);
    }
}

// This test renders at a slightly larger size half the time.
// We're deprecating Basic Integration soon, and we've spent enough time on this,
// so these tests are being disabled for now.
//- (void)testPushShippingAddressLargeTitle {
//    if (@available(iOS 12.0, *)) {
//        [self buildPaymentContext];
//
//        self.hostViewController.navigationBar.prefersLargeTitles = YES;
//        self.paymentContext.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
//        [self.paymentContext pushShippingViewController];
//        UIView *view = [self stp_preparedAndSizedViewForSnapshotTestFromNavigationController:self.hostViewController];
//        STPSnapshotVerifyView(view, nil);
//    }
//}

@end
