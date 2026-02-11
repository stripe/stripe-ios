//
//  PaymentSheetLPMUITest.swift
//  PaymentSheetUITest
//
//  Created by Yuki Tokuhiro on 7/17/24.
//

import XCTest


// MARK: - Helpers
class PaymentSheetStandardLPMUICase: PaymentSheetUITestCase {

}

extension PaymentSheetStandardLPMUICase {
    var webviewAuthorizePaymentButton: XCUIElement { app.firstDescendant(withLabel: "AUTHORIZE TEST PAYMENT") }
    var webviewAuthorizeSetupButton: XCUIElement { app.firstDescendant(withLabel: "AUTHORIZE TEST SETUP") }
    func tapPaymentMethod(_ id: String) {
        guard let pm = scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: id) else {
            XCTFail()
            return
        }
        pm.tap()
    }

    /// This waits for the ["PaymentSheetExample" Wants to Use "stripe.com" to Sign In] modal that
    /// `ASWebAuthenticationSession` shows and taps continue to allow the web view to open:
    func waitForASWebAuthSigninModalAndTapContinue() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let sbContinueButton = springboard.buttons["Continue"]
        XCTAssertTrue(sbContinueButton.waitForExistence(timeout: 10.0))
        sbContinueButton.tap()
    }
}
