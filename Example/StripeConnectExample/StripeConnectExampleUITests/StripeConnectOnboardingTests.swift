//
//  StripeConnectOnboardingTests.swift
//  StripeConnectExampleUITests
//
//  Created by Chris Mays on 8/21/24.
//

import XCTest

final class StripeConnectOnboardingTests: XCTestCase {
    func testOpenAndClose() throws {
        let app = XCUIApplication.sc_launch()
        app.sc_onboarding_cell.tap()
        app.verify_onboarding_loaded()
        app.verify_close_component()

        // Verify we land back on main page
        _ = app.sc_onboarding_cell
    }
}
