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

        // Wait for the Cash App Pay redirect webview to actually present before interacting,
        // instead of a fixed animation sleep that a loaded runner can outpace. Waiting on the
        // Close button (not a timer) is a positive readiness signal. (RUN_MOBILESDK-5431)
        let closeButton = app.otherElements["TopBrowserBar"].buttons["Close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 30.0), "Cash App Pay redirect webview did not present in time")
        // Close the webview, to simulate cancel
        closeButton.waitForExistenceAndTap(timeout: 15.0)

        // Tap to attempt a payment, but fail it
        payButton.waitForExistenceAndTap(timeout: 15.0)
        let failPaymentText = app.firstDescendant(withLabel: "FAIL TEST PAYMENT")
        failPaymentText.waitForExistenceAndTap(timeout: 15.0)

        XCTAssertTrue(app.staticTexts["The customer declined this payment."].waitForExistence(timeout: 15.0))

        // Tap to attempt a payment
        payButton.waitForExistenceAndTap(timeout: 15.0)
        let approvePaymentText = app.firstDescendant(withLabel: "AUTHORIZE TEST PAYMENT")
        approvePaymentText.waitForExistenceAndTap(timeout: 15.0)

        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 15.0))
    }
}
