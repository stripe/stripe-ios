//
//  XCUIApplication+Extension.swift
//  StripeConnect Example
//
//  Created by Chris Mays on 3/11/25.
//

import Foundation
import XCTest

// General
extension XCUIApplication {
    static func sc_launch(account: String? = nil) -> XCUIApplication {
        let launchEnvironment: [String: String] = [StripeConnectExampleAppKeys.initialAccountEnvironmentKey: account ?? "acct_1N9FIXQ26HdRlxHg"]

        let app = XCUIApplication()
        app.launchEnvironment = launchEnvironment
        app.launch()
        return app
    }

    func tap_close_component() {
        let closeButton = buttons["closeButton"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 10.0), "\(#function) waiting failed")
        closeButton.tap()
    }

    func tap_submit_button() {
        let webview = webViews.firstMatch
        XCTAssertTrue(webview.waitForExistence(timeout: 20))
        webview.swipeUp(velocity: .fast)
        webview.swipeUp(velocity: .fast)
        let confirmButton = buttons["​ Confirm"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 20))
        confirmButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    func verifyToast(message: String) {
        let window = windows["ToastWindow"]
        XCTAssertTrue(window.waitForExistence(timeout: 10.0), "\(#function) waiting failed")
        let confirmText = window.staticTexts[message]
        XCTAssertTrue(confirmText.waitForExistence(timeout: 10.0), "\(#function) waiting failed")
    }
}

// Onboarding
extension XCUIApplication {
    var sc_onboarding_cell: XCUIElement {
        let playgroundCell = tables.cells[StripeConnectExampleAppKeys.onboardingCellAccessibilityID]
        XCTAssertTrue(playgroundCell.waitForExistence(timeout: 20.0), "\(#function) waiting failed")
        return playgroundCell
    }

    func verify_onboarding_loaded() {
        let confirmText = staticTexts["Review and confirm"]
        XCTAssertTrue(confirmText.waitForExistence(timeout: 20.0), "\(#function) waiting failed")
    }

    func verify_onboarding_failed() {
        let confirmText = staticTexts["Something went wrong."]
        XCTAssertTrue(confirmText.waitForExistence(timeout: 20.0), "\(#function) waiting failed")
    }
}
