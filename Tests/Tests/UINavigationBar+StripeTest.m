//
//  UINavigationBar+StripeTest.m
//  Stripe
//
//  Created by Brian Dorfman on 12/9/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <Stripe/Stripe.h>
#import "STPFixtures.h"
#import "STPMocks.h"

@interface UINavigationBar_StripeTest : XCTestCase

@end

@implementation UINavigationBar_StripeTest

- (STPPaymentOptionsViewController *)buildPaymentMethodsViewController {
    id customerContext = [STPMocks staticCustomerContext];
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.publishableKey = @"pk_test";
    STPTheme *theme = [STPTheme defaultTheme];
    id delegate = OCMProtocolMock(@protocol(STPPaymentOptionsViewControllerDelegate));
    STPPaymentOptionsViewController *paymentMethodsVC = [[STPPaymentOptionsViewController alloc] initWithConfiguration:config
                                                                                                                 theme:theme
                                                                                                       customerContext:customerContext
                                                                                                              delegate:delegate];
    return paymentMethodsVC;
}

- (void)testVCUsesNavigationBarColor {
    STPPaymentOptionsViewController *paymentMethodsVC = [self buildPaymentMethodsViewController];
    STPTheme *navTheme = [STPTheme new];
    navTheme.accentColor = [UIColor purpleColor];

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:paymentMethodsVC];
    navController.navigationBar.stp_theme = navTheme;
    __unused UIView *view = paymentMethodsVC.view;
    XCTAssertEqualObjects(paymentMethodsVC.navigationItem.leftBarButtonItem.tintColor, [UIColor purpleColor]);
}

- (void)testVCDoesNotUseNavigationBarColor {
    STPPaymentOptionsViewController *paymentMethodsVC = [self buildPaymentMethodsViewController];
    __unused UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:paymentMethodsVC];
    __unused UIView *view = paymentMethodsVC.view;
    XCTAssertEqualObjects(paymentMethodsVC.navigationItem.leftBarButtonItem.tintColor, [STPTheme defaultTheme].accentColor);
}


@end
