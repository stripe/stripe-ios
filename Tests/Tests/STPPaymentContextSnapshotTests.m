//
//  STPPaymentContextSnapshotTests.m
//  StripeiOS Tests
//
//  Created by Ben Guo on 12/13/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import <OCMock/OCMock.h>
#import <Stripe/Stripe.h>

#import "FBSnapshotTestCase+STPViewControllerLoading.h"
#import "STPFixtures.h"
#import "STPMocks.h"

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
    config.additionalPaymentMethods = STPPaymentMethodTypeAll;
    config.shippingType = STPShippingTypeShipping;
    self.config = config;
    STPCustomerContext *customerContext = [STPMocks staticCustomerContextWithCustomer:[STPFixtures customerWithCardTokenAndSourceSources]];
    self.customerContext = customerContext;

    UIViewController *viewController = [UIViewController new];
    self.hostViewController = [self stp_navigationControllerForSnapshotTestWithRootVC:viewController];

//    self.recordMode = YES;
}

- (void)buildPaymentContext {
    STPPaymentContext *context = [[STPPaymentContext alloc] initWithCustomerContext:self.customerContext];
    context.hostViewController = self.hostViewController;
    self.paymentContext = context;
}

- (void)testPushPaymentMethodsSmallTitle {
    if (@available(iOS 11.0, *)) {
        [self buildPaymentContext];

        self.hostViewController.navigationBar.prefersLargeTitles = NO;
        self.paymentContext.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
        [self.paymentContext pushPaymentMethodsViewController];
        UIView *view = [self stp_preparedAndSizedViewForSnapshotTestFromNavigationController:self.hostViewController];
        FBSnapshotVerifyView(view, nil);
    }
}

- (void)testPushPaymentMethodsLargeTitle {
    if (@available(iOS 11.0, *)) {
        [self buildPaymentContext];

        self.hostViewController.navigationBar.prefersLargeTitles = YES;
        self.paymentContext.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
        [self.paymentContext pushPaymentMethodsViewController];
        UIView *view = [self stp_preparedAndSizedViewForSnapshotTestFromNavigationController:self.hostViewController];
        FBSnapshotVerifyView(view, nil);
    }
}

- (void)testPushShippingAddressSmallTitle {
    if (@available(iOS 11.0, *)) {
        [self buildPaymentContext];

        self.hostViewController.navigationBar.prefersLargeTitles = NO;
        self.paymentContext.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
        [self.paymentContext pushShippingViewController];
        UIView *view = [self stp_preparedAndSizedViewForSnapshotTestFromNavigationController:self.hostViewController];
        FBSnapshotVerifyView(view, nil);
    }
}

- (void)testPushShippingAddressLargeTitle {
    if (@available(iOS 11.0, *)) {
        [self buildPaymentContext];

        self.hostViewController.navigationBar.prefersLargeTitles = YES;
        self.paymentContext.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
        [self.paymentContext pushShippingViewController];
        UIView *view = [self stp_preparedAndSizedViewForSnapshotTestFromNavigationController:self.hostViewController];
        FBSnapshotVerifyView(view, nil);
    }
}

@end
