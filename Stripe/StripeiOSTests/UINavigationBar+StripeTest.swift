//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  UINavigationBar+StripeTest.swift
//  Stripe
//
//  Created by Brian Dorfman on 12/9/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import OCMock
import Stripe

class UINavigationBar_StripeTest: XCTestCase {
    func buildPaymentOptionsViewController() -> STPPaymentOptionsViewController? {
        let customerContext = STPMocks.staticCustomerContext()
        let config = STPFixtures.paymentConfiguration()
        let theme = STPTheme.default()
        let delegate = OCMProtocolMock(STPPaymentOptionsViewControllerDelegate)
        let paymentOptionsVC = STPPaymentOptionsViewController(
            configuration: config,
            theme: theme,
            customerContext: customerContext,
            delegate: delegate)
        return paymentOptionsVC
    }

    func testVCUsesNavigationBarColor() {
        let paymentOptionsVC = buildPaymentOptionsViewController()
        let navTheme = STPTheme()
        navTheme.accentColor = UIColor.purple

        var navController: UINavigationController?
        if let paymentOptionsVC {
            navController = UINavigationController(rootViewController: paymentOptionsVC)
        }
        navController?.navigationBar.stp_theme = navTheme
        let view = paymentOptionsVC?.view
        XCTAssertEqual(paymentOptionsVC?.navigationItem.leftBarButtonItem?.tintColor, UIColor.purple)
    }

    func testVCDoesNotUseNavigationBarColor() {
        let paymentOptionsVC = buildPaymentOptionsViewController()
        var navController: UINavigationController?
        if let paymentOptionsVC {
            navController = UINavigationController(rootViewController: paymentOptionsVC)
        }
        let view = paymentOptionsVC?.view
        XCTAssertEqual(paymentOptionsVC?.navigationItem.leftBarButtonItem?.tintColor, STPTheme.default().accentColor)
    }
}