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

    func testNativeInstantDebitsOnlyLinkPaymentController() {
        app.launchArguments += ["-FINANCIAL_CONNECTIONS_EXAMPLE_APP_ENABLE_NATIVE", "YES"]
        app.launchEnvironment["FinancialConnectionsSDKAvailable"] = "true"
        app.launch()

        // PaymentSheet Example
        app.staticTexts["LinkPaymentController"].tap()

        // LinkPaymentController
        let paymentMethodButton = app.buttons["SelectPaymentMethodButton"]
        let paymentMethodButtonEnabledExpectation = expectation(
            for: NSPredicate(format: "enabled == true"),
            evaluatedWith: paymentMethodButton
        )
        wait(for: [paymentMethodButtonEnabledExpectation], timeout: 60, enforceOrder: true)
        paymentMethodButton.tap()

        PaymentSheetUITestCase.stepThroughNativeInstantDebitsFlow(app: app, emailPrefilled: false)

        sleep(3) // wait for modal to disappear before pressing Buy

        // Back to "LinkPaymentController"
        app.buttons["Buy"].waitForExistenceAndTap(timeout: timeout)
        XCTAssert(app.alerts.staticTexts["Your order is confirmed!"].waitForExistence(timeout: timeout))
    }
}
