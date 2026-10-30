// Copyright © 2026 Stripe, Inc. All rights reserved.

import XCTest

class PaymentSheetPaytoUITests: PaymentSheetStandardLPMUICase {
    func testPayment() {
        testPayto(mode: .payment)
    }

    func testPaymentWithSetupFutureUsage() {
        testPayto(mode: .paymentWithSetup)
    }

    func testSetup() {
        testPayto(mode: .setup)
    }

    private func testPayto(mode: PaymentSheetTestPlaygroundSettings.Mode) {
        // Given PaymentSheet with the Australian PayTo test merchant
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.mode = mode
        settings.customerMode = .guest
        settings.apmsEnabled = .off
        settings.applePayEnabled = .off
        settings.currency = .aud
        settings.merchantCountryCode = .AU
        settings.supportedPaymentMethods = "payto"
        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        // When the customer enters their bank details and confirms
        let name = app.textFields["Full name"]
        XCTAssertTrue(name.waitForExistence(timeout: 20))
        name.tap()
        name.typeText("Jane Smith")
        let bsb = app.textFields["BSB number"]
        bsb.tap()
        bsb.typeText("000000")
        let account = app.textFields["Account number"]
        account.tap()
        account.typeText("000123456")
        app.staticTexts["Add your payment information"].tap()
        let confirmation = mode == .setup ? app.buttons["Set up"] : app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Pay ")).firstMatch
        confirmation.waitForExistenceAndTap()

        // Then PaymentSheet waits for authorization and completes the intent
        // PayTo's success test account authorizes the agreement automatically.
        XCTAssertTrue(app.staticTexts["Authorise payment with your banking app"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 120))
    }
}
