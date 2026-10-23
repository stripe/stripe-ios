//
//  PaymentSheetStandardLPMUIOneTests.swift
//  PaymentSheet Example
//
//  Created by David Estes on 2/11/26.
//

import XCTest

class PaymentSheetStandardLPMUIOneTests: PaymentSheetStandardLPMUICase {
    func testTrueMoneyPayment() {
        testTrueMoney(setupFutureUsage: false)
    }

    func testTrueMoneyPaymentWithFutureUsage() {
        testTrueMoney(setupFutureUsage: true)
    }

    private func testTrueMoney(setupFutureUsage: Bool) {
        // Given a test account enabled for TrueMoney payments and recurring payments
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.mode = setupFutureUsage ? .paymentWithSetup : .payment
        settings.customerMode = .guest
        settings.apmsEnabled = .off
        settings.applePayEnabled = .off
        settings.currency = .thb
        settings.amount = ._10000
        settings.merchantCountryCode = .US
        settings.supportedPaymentMethods = "truemoney"
        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        let confirmButton = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Pay ")
        ).firstMatch
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 15))

        // Then future payments show the merchant mandate before confirmation
        let mandate = app.textViews.matching(NSPredicate(
            format: "label == %@",
            "By confirming your payment with TrueMoney, you allow Example, Inc. to charge your TrueMoney account for future payments in accordance with their terms."
        )).firstMatch
        if !setupFutureUsage {
            XCTAssertFalse(mandate.exists)
        } else {
            XCTAssertTrue(mandate.waitForExistence(timeout: 5))
        }

        // When the customer confirms and authorizes the payment on the hosted page
        confirmButton.waitForExistenceAndTap()
        webviewAuthorizePaymentButton.waitForExistenceAndTap(timeout: 30)

        // Then the redirect returns to PaymentSheet and the operation succeeds
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 30))
    }

    // acct_1ONGjdKULGu5EgSk is enrolled in alipay_cn_to_alipay_plus_migration_gate,
    // so its Alipay redirects use the pm-redirects.stripe.com EVO trampoline.
    func testAlipayEVO() {
        // Given PaymentSheet configured for the gated China merchant
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .guest
        settings.apmsEnabled = .off
        settings.applePayEnabled = .off
        settings.currency = .cny
        settings.merchantCountryCode = .CN
        settings.supportedPaymentMethods = "card,alipay"
        loadPlayground(app, settings)

        // When the customer authorizes an Alipay payment through the EVO redirect
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        tapPaymentMethod("Alipay")
        let payButton = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Pay ")
        ).firstMatch
        payButton.waitForExistenceAndTap()

        XCTAssertTrue(
            webviewAuthorizePaymentButton.waitForExistence(timeout: 30.0),
            "Alipay redirect webview did not present in time"
        )
        webviewAuthorizePaymentButton.waitForExistenceAndTap()

        // Then the trampoline returns to the app and PaymentSheet completes
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 30.0))
    }

    // This Cash App test is a good way to test the cancellation/success behavior
    // of the refresh endpoint E2E.
    func testRefreshEndpointUsingCashAppPay() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.apmsEnabled = .on
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()
        let payButton = app.buttons["Pay $50.99"]

        // Select Cash App
        guard let cashApp = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "Cash App Pay")
        else {
            XCTFail()
            return
        }
        cashApp.waitForExistenceAndTap()

        // Attempt payment
        payButton.waitForExistenceAndTap()

        // Wait 2x 300ms for window to animate in
        Thread.sleep(forTimeInterval: 0.60)

        // Close the webview, to simulate cancel
        _ = app.otherElements["TopBrowserBar"].waitForExistence(timeout: 5.0)
        app.otherElements["TopBrowserBar"].buttons["Close"].waitForExistenceAndTap(timeout: 15.0)

        // Tap to attempt a payment, but fail it
        payButton.waitForExistenceAndTap()
        let failPaymentText = app.firstDescendant(withLabel: "FAIL TEST PAYMENT")
        failPaymentText.waitForExistenceAndTap(timeout: 15.0)

        XCTAssertTrue(app.staticTexts["The customer declined this payment."].waitForExistence(timeout: 5.0))

        // Tap to attempt a payment
        payButton.waitForExistenceAndTap()
        let approvePaymentText = app.firstDescendant(withLabel: "AUTHORIZE TEST PAYMENT")
        approvePaymentText.waitForExistenceAndTap(timeout: 15.0)

        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 15.0))
    }
}
