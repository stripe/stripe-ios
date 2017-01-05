//
//  UINavigationBar+StripeTest.m
//  Stripe
//
//  Created by Brian Dorfman on 12/9/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <Stripe/Stripe.h>
#import "TestSTPBackendAPIAdapter.h"

@interface UINavigationBar_StripeTest : XCTestCase <STPPaymentMethodsViewControllerDelegate>

@end

@implementation UINavigationBar_StripeTest

- (void)setUp {
    [super setUp];
    [STPPaymentConfiguration sharedConfiguration].publishableKey = @"pk_test";
}

- (void)paymentMethodsViewController:(__unused STPPaymentMethodsViewController *)paymentMethodsViewController didSelectPaymentMethod:(__unused id<STPPaymentMethod>)paymentMethod {

}

- (void)paymentMethodsViewControllerDidFinish:(__unused STPPaymentMethodsViewController *)paymentMethodsViewController {

}

- (void)paymentMethodsViewController:(__unused STPPaymentMethodsViewController *)paymentMethodsViewController didFailToLoadWithError:(__unused NSError *)error {

}

- (void)testVCUsesNavigationBarColor {
    STPPaymentMethodsViewController *paymentMethodsVC = [[STPPaymentMethodsViewController alloc] initWithConfiguration:[STPPaymentConfiguration sharedConfiguration]
                                                                                                                 theme:[STPTheme defaultTheme]
                                                                                                            apiAdapter:[TestSTPBackendAPIAdapter new]
                                                                                                              delegate:self];
    STPTheme *navTheme = [STPTheme new];
    navTheme.accentColor = [UIColor purpleColor];

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:paymentMethodsVC];
    navController.navigationBar.stp_theme = navTheme;
    __unused UIView *view = paymentMethodsVC.view;
    XCTAssertEqualObjects(paymentMethodsVC.navigationItem.leftBarButtonItem.tintColor, [UIColor purpleColor]);
}

- (void)testVCDoesNotUseNavigationBarColor {

    STPPaymentMethodsViewController *paymentMethodsVC = [[STPPaymentMethodsViewController alloc] initWithConfiguration:[STPPaymentConfiguration sharedConfiguration]
                                                                                                                 theme:[STPTheme defaultTheme]
                                                                                                            apiAdapter:[TestSTPBackendAPIAdapter new]
                                                                                                              delegate:self];

    __unused UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:paymentMethodsVC];
    __unused UIView *view = paymentMethodsVC.view;
    XCTAssertEqualObjects(paymentMethodsVC.navigationItem.leftBarButtonItem.tintColor, [STPTheme defaultTheme].accentColor);
}


@end
