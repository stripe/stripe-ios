//
//  FinancialConnectionsNetworkingUITests.swift
//  FinancialConnections Example
//
//  Created by Krisjanis Gaidis on 4/24/23.
//  Copyright © 2023 Stripe, Inc. All rights reserved.
//

import XCTest

final class FinancialConnectionsNetworkingUITests: XCTestCase {

    func testNativeNetworkingTestMode() throws {
        let emailAddresss = "\(UUID().uuidString)@UITestForIOS.com"
        executeNativeNetworkingTestModeSignUpFlowTest(emailAddress: emailAddresss)
        executeNativeNetworkingTestModeSignInFlowTest(emailAddress: emailAddresss)
        let bankAccountName = "Insufficient Funds"
        executeNativeNetworkingTestModeAddBankAccount(
            emailAddress: emailAddresss,
            bankAccountName: bankAccountName
        )
        executeNativeNetworkingTestModeUpdateRequired(
            emailAddress: emailAddresss,
            bankAccountName: bankAccountName
        )
    }

    private func executeNativeNetworkingTestModeSignUpFlowTest(emailAddress: String) {
        let app = XCUIApplication.fc_launch(
            configurationJSONString:
"""
{"use_case":"payment_intent","sdk_type":"native","test_mode":true,"merchant":"networking","payment_method_permission":true,"email":""}
"""
        )

        app.fc_playgroundCell.tap()
        app.fc_playgroundShowAuthFlowButton.tap()

        app.fc_nativeConsentAgreeButton.tap()

        let featuredLegacyTestInstitution = app.tables.cells.staticTexts["Test OAuth Institution"]
        XCTAssertTrue(featuredLegacyTestInstitution.waitForExistence(timeout: 60.0))
        featuredLegacyTestInstitution.tap()

        app.fc_nativePrepaneContinueButton.tap()

        let successInstitution = app.scrollViews.staticTexts["Success"]
        XCTAssertTrue(successInstitution.waitForExistence(timeout: 60.0))
        successInstitution.tap()

        app.fc_nativeConnectAccountsButton.tap()

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

        // ensure that there wasn't a Link failure
        //
        // unexpected text: "Your account was connected, but couldn't be saved to Link"
        XCTAssert(!app.textViews.containing(NSPredicate(format: "label CONTAINS 'but'")).firstMatch.exists)

        successPaneDoneButton.tap()

        // ensure alert body contains "Stripe Bank" (AKA one bank is linked)
        XCTAssert(
            app.fc_playgroundSuccessAlertView.staticTexts.containing(NSPredicate(format: "label CONTAINS 'StripeBank'")).firstMatch
                .exists
        )
    }

    private func executeNativeNetworkingTestModeSignInFlowTest(emailAddress: String) {
        let app = XCUIApplication.fc_launch(
            configurationJSONString:
"""
{"use_case":"payment_intent","sdk_type":"native","test_mode":true,"merchant":"networking","payment_method_permission":true,"transactions_permission":true,"email":"\(emailAddress)"}
"""
        )

        app.fc_playgroundCell.tap()
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

        // ensure that there wasn't a Link failure
        //
        // unexpected text: "Your account was connected, but couldn't be saved to Link"
        XCTAssert(!app.textViews.containing(NSPredicate(format: "label CONTAINS 'but'")).firstMatch.exists)

        successPaneDoneButton.tap()

        // ensure alert body contains "Stripe Bank" (AKA one bank is linked)
        XCTAssert(
            app.fc_playgroundSuccessAlertView.staticTexts.containing(NSPredicate(format: "label CONTAINS 'StripeBank'")).firstMatch
                .exists
        )
    }

    private func executeNativeNetworkingTestModeAddBankAccount(
        emailAddress: String,
        bankAccountName: String
    ) {
        // ensure that permissions like "ownership" / "transcations" / "balances" is off
        let app = XCUIApplication.fc_launch(
            configurationJSONString:
"""
{"use_case":"payment_intent","sdk_type":"native","test_mode":true,"merchant":"networking","payment_method_permission":true,"email":"\(emailAddress)"}
"""
        )

        app.fc_playgroundCell.tap()
        app.fc_playgroundShowAuthFlowButton.tap()

        app.fc_nativeConsentAgreeButton.tap()

        let linkContinueButton = app.buttons["link_continue_button"]
        XCTAssertTrue(linkContinueButton.waitForExistence(timeout: 60.0))
        linkContinueButton.tap()

        let verificationOTPTextView = app.scrollViews.otherElements.textViews["Code field"]
        XCTAssertTrue(verificationOTPTextView.waitForExistence(timeout: 60.0))
        verificationOTPTextView.tap()
        verificationOTPTextView.typeText("111111")

        let addBankAccountButton = app.scrollViews.otherElements["add_bank_account"]
        XCTAssertTrue(addBankAccountButton.waitForExistence(timeout: 120.0)) // need to wait for various API calls to appear
        addBankAccountButton.tap()

        // wait for search bar to appear
        _ = app.fc_searchBarTextField

        app.fc_scrollDown() // see all institutions

        app.fc_nativeFeaturedInstitution(name: "Data cannot be shared through Link").tap()

        app.fc_nativeBankAccount(name: bankAccountName).tap()

        app.fc_nativeConnectAccountsButton.tap()

        app.fc_nativeSuccessDoneButton.tap()

        // ensure alert body contains "Stripe Bank" (AKA one bank is linked)
        XCTAssert(
            app.fc_playgroundSuccessAlertView.staticTexts.containing(NSPredicate(format: "label CONTAINS '\(bankAccountName)'")).firstMatch
                .exists
        )
    }

    private func executeNativeNetworkingTestModeUpdateRequired(
        emailAddress: String,
        bankAccountName: String
    ) {
        // turn on all permissions so we get an "Update Required" account
        let app = XCUIApplication.fc_launch(
            configurationJSONString:
"""
{"use_case":"data","sdk_type":"native","test_mode":true,"merchant":"networking","payment_method_permission":true,"ownership_permission":true,"balances_permission":true,"transactions_permission":true,"email":"\(emailAddress)"}
"""
        )

        app.fc_playgroundCell.tap()
        app.fc_playgroundShowAuthFlowButton.tap()

        app.fc_nativeConsentAgreeButton.tap()

        let linkContinueButton = app.buttons["link_continue_button"]
        XCTAssertTrue(linkContinueButton.waitForExistence(timeout: 60.0))
        linkContinueButton.tap()

        let verificationOTPTextView = app.scrollViews.otherElements.textViews["Code field"]
        XCTAssertTrue(verificationOTPTextView.waitForExistence(timeout: 60.0))
        verificationOTPTextView.tap()
        verificationOTPTextView.typeText("111111")

        app.fc_nativeBankAccount(name: bankAccountName).tap()

        let accountUpdateRequiredContinueButton = app.buttons["account_update_required_continue_button"]
        XCTAssertTrue(accountUpdateRequiredContinueButton.waitForExistence(timeout: 1))
        accountUpdateRequiredContinueButton.tap()

        app.fc_nativeConnectAccountsButton.tap()

        let successDoneButton = app.fc_nativeSuccessDoneButton

        // ensures that save to Link was successful
        //
        // expected text: "Your account was connected, and saved with Link."
        XCTAssert(app.textViews.containing(NSPredicate(format: "label CONTAINS 'Link'")).firstMatch.exists)

        // ensure that the Link text wasn't a failure
        //
        // unexpected text: "Your account was connected, but couldn't be saved to Link"
        XCTAssert(!app.textViews.containing(NSPredicate(format: "label CONTAINS 'but'")).firstMatch.exists)

        successDoneButton.tap()

        // multiple banks should be checked
        XCTAssert(
            app.fc_playgroundSuccessAlertView.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Success'")).firstMatch
                .exists
        )
        XCTAssert(
            app.fc_playgroundSuccessAlertView.staticTexts.containing(NSPredicate(format: "label CONTAINS '\(bankAccountName)'")).firstMatch
                .exists
        )
    }

    func testNativeNetworkingTestModeSignUpWithMultiSelectAndPrefilledEmail() {
        let emailAddress = "\(UUID().uuidString)@UITestForIOS.com"

        let app = XCUIApplication.fc_launch(
            configurationJSONString:
"""
{"use_case":"data","sdk_type":"native","test_mode":true,"merchant":"networking","payment_method_permission":true,"ownership_permission":true,"balances_permission":true,"transactions_permission":true,"email":"\(emailAddress)"}
"""
        )

        app.fc_playgroundCell.tap()
        app.fc_playgroundShowAuthFlowButton.tap()

        app.fc_nativeConsentAgreeButton.tap()

        let featuredLegacyTestInstitution = app.tables.cells.staticTexts["Test OAuth Institution"]
        XCTAssertTrue(featuredLegacyTestInstitution.waitForExistence(timeout: 60.0))
        featuredLegacyTestInstitution.tap()

        app.fc_nativePrepaneContinueButton.tap()

        // all accounts will be selected by default

        app.fc_nativeConnectAccountsButton.tap()

        // email will already be pre-filled

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

        // ensures that save to Link was successful
        //
        // expected text: "Your account was connected, and saved with Link."
        XCTAssert(app.textViews.containing(NSPredicate(format: "label CONTAINS 'Link'")).firstMatch.exists)

        // ensure that the Link text wasn't a failure
        //
        // unexpected text: "Your account was connected, but couldn't be saved to Link"
        XCTAssert(!app.textViews.containing(NSPredicate(format: "label CONTAINS 'but'")).firstMatch.exists)

        successPaneDoneButton.tap()

        // multiple banks should be checked
        XCTAssert(
            app.fc_playgroundSuccessAlertView.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Success'")).firstMatch
                .exists
        )
        XCTAssert(
            app.fc_playgroundSuccessAlertView.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Insufficient Funds'")).firstMatch
                .exists
        )
    }
}
