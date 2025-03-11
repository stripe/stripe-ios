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

    func verify_close_component() {
        let confirmText = buttons["closeButton"]
        XCTAssertTrue(confirmText.waitForExistence(timeout: 10.0), "\(#function) waiting failed")
        confirmText.tap()
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
}
