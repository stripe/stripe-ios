//
//  LinkPaymentControllerUITest.swift
//  PaymentSheetUITest
//
//  Created by Krisjanis Gaidis on 6/3/24.
//

import XCTest

class LinkPaymentControllerUITest: XCTestCase {
    fileprivate var app: XCUIApplication!
    fileprivate let timeout: TimeInterval = 10

    override func setUpWithError() throws {
        try super.setUpWithError()
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchEnvironment = ["UITesting": "true"]
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        app.launchEnvironment = [:]
    }

    // REMOVED: testWebInstantDebitsOnlyLinkPaymentController() - Migrated to LinkPaymentFlowTests.swift unit tests
    // Web instant debits flow logic is now tested at the unit level without UI automation

    // REMOVED: testNativeInstantDebitsOnlyLinkPaymentController() - Migrated to LinkPaymentFlowTests.swift unit tests
    // Native instant debits flow logic is now tested at the unit level without UI automation
}
