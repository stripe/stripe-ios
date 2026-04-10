//
//  PaymentSheetStandardLPMUIOneTests.swift
//  PaymentSheet Example
//
//  Created by David Estes on 2/11/26.
//

import XCTest

class PaymentSheetStandardLPMUIOneTests: PaymentSheetStandardLPMUICase {
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
