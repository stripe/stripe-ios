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

    func testWebInstantDebitsOnlyLinkPaymentController() {
        app.launchEnvironment["FinancialConnectionsSDKAvailable"] = "false"
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

        // "Consent" pane
        app.buttons["Agree and continue"].waitForExistenceAndTap(timeout: timeout)

        // "Sign Up" pane
        app.textFields
            .matching(NSPredicate(format: "label CONTAINS 'Email address'"))
            .firstMatch
            .waitForExistenceAndTap(timeout: 10)
        let email = "linkpaymentcontrolleruitest-\(UUID().uuidString)@example.com"
        app.typeText(email + XCUIKeyboardKey.return.rawValue)
        app.textFields["Phone number"].tap()
        // the `XCUIKeyboardKey.return.rawValue` will automatically
        // press the "Continue with Link" button to proceed to next
        // screen
        app.typeText("4015006000" + XCUIKeyboardKey.return.rawValue)

        // "Institution Picker" pane
        let searchTextField = app.textFields
            .matching(NSPredicate(format: "label CONTAINS 'Search'"))
            .firstMatch
        searchTextField.waitForExistenceAndTap(timeout: 10)
        app.typeText("Test Institution" + XCUIKeyboardKey.return.rawValue)
        searchTextField
            .coordinate(
                withNormalizedOffset: CGVector(
                    dx: 0.5,
                    // bottom of search text field
                    dy: 1.0
                )
            )
        // at this point, we searched "Test Institution"
        // and the only search result is "Test Institution,"
        // so here we guess that 80 pixels below search bar
        // there will be a "Test Institution"
        //
        // we do this "guess" because every other method of
        // selecting the institution did not work on iOS 17
            .withOffset(CGVector(dx: 0, dy: 80))
            .tap()

        // "Account Picker" pane
        _ = app.staticTexts["Select account"].waitForExistence(timeout: 10)
        app.buttons["Connect account"].tap()

        // "Success" pane
        XCTAssert(app.staticTexts["Your account was connected."].waitForExistence(timeout: 10))
        // XCUITest had problems tapping the Done button in success pane,
        // so here we tap the Done button by estimating coordinates
        app.coordinate(
            // this locates the middle of the bottom of the app
            withNormalizedOffset: CGVector(dx: 0.5, dy: 1.0)
        )
        // we then navigate from the bottom to the "Done" button
        .withOffset(CGVector(dx: 0, dy: -130))
        .tap()

        sleep(3) // wait for modal to disappear before pressing Buy

        // Back to "LinkPaymentController"
        app.buttons["Buy"].waitForExistenceAndTap(timeout: timeout)
        XCTAssert(app.alerts.staticTexts["Your order is confirmed!"].waitForExistence(timeout: timeout))
    }

    func testNativeInstantDebitsOnlyLinkPaymentController() {
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
