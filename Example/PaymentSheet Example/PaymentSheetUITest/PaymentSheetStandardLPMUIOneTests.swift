//
//  PaymentSheetStandardLPMUIOneTests.swift
//  PaymentSheet Example
//
//  Created by David Estes on 2/11/26.
//


import XCTest

class PaymentSheetStandardLPMUIOneTests: PaymentSheetStandardLPMUICase {
    // UPI is a little custom and isn't well-tested by PaymentSheet_LPM_ConfirmFlowTests
    func testUPIPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.merchantCountryCode = .IN
        settings.currency = .inr
        settings.apmsEnabled = .off
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Pay ₹50.99"].waitForExistence(timeout: 5))

        let payButton = app.buttons["Pay ₹50.99"]
        tapPaymentMethod("UPI")

        XCTAssertFalse(payButton.isEnabled)
        // Test invalid VPA
        let upi_id = app.textFields["UPI ID"]
        upi_id.tap()
        upi_id.typeText("payment.success" + XCUIKeyboardKey.return.rawValue)
        XCTAssertFalse(payButton.isEnabled)

        // Test valid VPA
        upi_id.tap()
        upi_id.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "payment.success".count))
        upi_id.typeText("payment.success@stripeupi" + XCUIKeyboardKey.return.rawValue)
        payButton.tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
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