//
//  UINavigationBar+StripeTest.m
//  Stripe
//
//  Created by Brian Dorfman on 12/9/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
@import Stripe;
#import "STPFixtures.h"
#import "STPMocks.h"

@interface UINavigationBar_StripeTest : XCTestCase

@end

@implementation UINavigationBar_StripeTest

- (STPPaymentOptionsViewController *)buildPaymentOptionsViewController {
    id customerContext = [STPMocks staticCustomerContext];
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    STPTheme *theme = [STPTheme defaultTheme];
    id delegate = OCMProtocolMock(@protocol(STPPaymentOptionsViewControllerDelegate));
    STPPaymentOptionsViewController *paymentOptionsVC = [[STPPaymentOptionsViewController alloc] initWithConfiguration:config
                                                                                                                 theme:theme
                                                                                                       customerContext:customerContext
                                                                                                              delegate:delegate];
    return paymentOptionsVC;
}

- (void)testVCUsesNavigationBarColor {
    STPPaymentOptionsViewController *paymentOptionsVC = [self buildPaymentOptionsViewController];
    STPTheme *navTheme = [STPTheme new];
    navTheme.accentColor = [UIColor purpleColor];

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:paymentOptionsVC];
    navController.navigationBar.stp_theme = navTheme;
    __unused UIView *view = paymentOptionsVC.view;
    XCTAssertEqualObjects(paymentOptionsVC.navigationItem.leftBarButtonItem.tintColor, [UIColor purpleColor]);
}

- (void)testVCDoesNotUseNavigationBarColor {
    STPPaymentOptionsViewController *paymentOptionsVC = [self buildPaymentOptionsViewController];
    __unused UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:paymentOptionsVC];
    __unused UIView *view = paymentOptionsVC.view;
    XCTAssertEqualObjects(paymentOptionsVC.navigationItem.leftBarButtonItem.tintColor, [STPTheme defaultTheme].accentColor);
}


@end
