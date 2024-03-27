//
//  FinancialConnectionsNetworkingUITests.swift
//  FinancialConnections Example
//
//  Created by Krisjanis Gaidis on 4/24/23.
//  Copyright © 2023 Stripe, Inc. All rights reserved.
//

import XCTest

final class FinancialConnectionsNetworkingUITests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    func testNativeNetworkingTestMode() throws {
        let emailAddresss = "\(UUID().uuidString)@UITestForIOS.com"
        executeNativeNetworkingTestModeSignUpFlowTest(emailAddress: emailAddresss)
        executeNativeNetworkingTestModeSignInFlowTest(emailAddress: emailAddresss)
    }

    private func executeNativeNetworkingTestModeSignUpFlowTest(emailAddress: String) {
        let app = XCUIApplication.fc_launch()

        app.fc_playgroundCell.tap()

        let dataSegmentPickerButton = app.segmentedControls.buttons["Networking"]
        XCTAssertTrue(dataSegmentPickerButton.waitForExistence(timeout: 60.0))
        dataSegmentPickerButton.tap()

        app.fc_playgroundNativeButton.tap()

        let enableTestModeSwitch = app.fc_playgroundEnableTestModeSwitch
        enableTestModeSwitch.turnSwitch(on: true)

        let playgroundEmailTextField = app.textFields["playground-email"]
        XCTAssertTrue(playgroundEmailTextField.waitForExistence(timeout: 60.0))
        playgroundEmailTextField.tap()
        clear(textField: playgroundEmailTextField)
        app.dismissKeyboard() // dismiss keyboard (warning: ensure keyboard is visible if manually testing)

        let playgroundTransactionsPermissionsSwitch = app.switches["playground-transactions-permission"]
        XCTAssertTrue(playgroundTransactionsPermissionsSwitch.waitForExistence(timeout: 60.0))
        playgroundTransactionsPermissionsSwitch.turnSwitch(on: true)

        app.fc_playgroundShowAuthFlowButton.tap()
        app.fc_nativeConsentAgreeButton.tap()

        let featuredLegacyTestInstitution = app.tables.cells.staticTexts["Test OAuth Institution"]
        XCTAssertTrue(featuredLegacyTestInstitution.waitForExistence(timeout: 60.0))
        featuredLegacyTestInstitution.tap()

        app.fc_nativePrepaneContinueButton.tap()

        let successInstitution = app.scrollViews.staticTexts["Success"]
        XCTAssertTrue(successInstitution.waitForExistence(timeout: 60.0))
        successInstitution.tap()

        app.fc_nativeAccountPickerLinkAccountsButton.tap()

        let emailTextField = app.textFields["email_text_field"]
        XCTAssertTrue(emailTextField.waitForExistence(timeout: 120.0))  // wait for synchronize to complete
        emailTextField.tap()
        emailTextField.typeText(emailAddress)

        let phoneTextField = app.textFields["phone_text_field"]
        XCTAssertTrue(phoneTextField.waitForExistence(timeout: 120.0))  // wait for lookup to complete
        phoneTextField.tap()
        phoneTextField.typeText("4015006000")

        let phoneTextFieldToolbarDoneButton = app.toolbars["Toolbar"].buttons["Done"]
        XCTAssertTrue(phoneTextFieldToolbarDoneButton.waitForExistence(timeout: 60.0))
        phoneTextFieldToolbarDoneButton.tap()

        let saveToLinkButon = app.buttons["Save to Link"]
        XCTAssertTrue(saveToLinkButon.waitForExistence(timeout: 120.0))  // glitch app can take time to lload
        saveToLinkButon.tap()

        let successPaneDoneButton = app.fc_nativeSuccessDoneButton
        // this ensures that save to Link was successful...
        // ...we want to check AFTER success screen has rendered with the "Done" button
        XCTAssert(!app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'could not be saved to Link'")).firstMatch
            .exists)
        successPaneDoneButton.tap()

        // ensure alert body contains "Stripe Bank" (AKA one bank is linked)
        XCTAssert(
            app.fc_playgroundSuccessAlertView.staticTexts.containing(NSPredicate(format: "label CONTAINS 'StripeBank'")).firstMatch
                .exists
        )
    }

    private func executeNativeNetworkingTestModeSignInFlowTest(emailAddress: String) {
        let app = XCUIApplication.fc_launch()

        app.fc_playgroundCell.tap()

        let dataSegmentPickerButton = app.segmentedControls.buttons["Networking"]
        XCTAssertTrue(dataSegmentPickerButton.waitForExistence(timeout: 60.0))
        dataSegmentPickerButton.tap()

        app.fc_playgroundNativeButton.tap()

        let enableTestModeSwitch = app.fc_playgroundEnableTestModeSwitch
        enableTestModeSwitch.turnSwitch(on: true)

        let playgroundEmailTextField = app.textFields["playground-email"]
        XCTAssertTrue(playgroundEmailTextField.waitForExistence(timeout: 60.0))
        playgroundEmailTextField.tap()
        clear(textField: playgroundEmailTextField)
        playgroundEmailTextField.typeText(emailAddress)
        app.dismissKeyboard() // dismiss keyboard (warning: ensure keyboard is visible if manually testing)

        let playgroundTransactionsPermissionsSwitch = app.switches["playground-transactions-permission"]
        XCTAssertTrue(playgroundTransactionsPermissionsSwitch.waitForExistence(timeout: 60.0))
        playgroundTransactionsPermissionsSwitch.turnSwitch(on: true)

        app.fc_playgroundShowAuthFlowButton.tap()
        app.fc_nativeConsentAgreeButton.tap()

        let linkContinueButton = app.buttons["link_continue_button"]
        XCTAssertTrue(linkContinueButton.waitForExistence(timeout: 60.0))
        linkContinueButton.tap()

        let verificationOTPTextView = app.scrollViews.otherElements.textViews["Code field"]
        XCTAssertTrue(verificationOTPTextView.waitForExistence(timeout: 60.0))
        verificationOTPTextView.tap()
        verificationOTPTextView.typeText("111111")

        let successInstitution = app.scrollViews.staticTexts["Success"]
        XCTAssertTrue(successInstitution.waitForExistence(timeout: 120.0)) // need to wait for various API calls to appear
        successInstitution.tap()

        let connectAccountButton = app.buttons["Connect account"]
        XCTAssertTrue(connectAccountButton.waitForExistence(timeout: 60.0))
        connectAccountButton.tap()

        let stepUpVerificationOTPTextView = app.scrollViews.otherElements.textViews["Code field"]
        XCTAssertTrue(stepUpVerificationOTPTextView.waitForExistence(timeout: 60.0))
        stepUpVerificationOTPTextView.tap()
        stepUpVerificationOTPTextView.typeText("111111")

        let successPaneDoneButton = app.fc_nativeSuccessDoneButton
        // this ensures that save to Link was successful...
        // ...we want to check AFTER success screen has rendered with the "Done" button
        XCTAssert(!app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'could not be saved to Link'")).firstMatch
            .exists)
        successPaneDoneButton.tap()

        // ensure alert body contains "Stripe Bank" (AKA one bank is linked)
        XCTAssert(
            app.fc_playgroundSuccessAlertView.staticTexts.containing(NSPredicate(format: "label CONTAINS 'StripeBank'")).firstMatch
                .exists
        )
    }
}
