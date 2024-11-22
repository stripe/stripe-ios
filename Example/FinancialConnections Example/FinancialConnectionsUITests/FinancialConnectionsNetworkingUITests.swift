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
        // TODO(mats): Reenable once step up verification issues are resolved (BANKCON-14617).
        // executeNativeNetworkingTestModeSignInFlowTest(emailAddress: emailAddresss)
        executeNativeNetworkingTestModeAutofillSignInFlowTest(emailAddress: emailAddresss)
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
            playgroundConfigurationString:
"""
{"use_case":"payment_intent","experience":"financial_connections","sdk_type":"native","test_mode":true,"merchant":"networking","payment_method_permission":true,"email":""}
"""
        )

        app.fc_playgroundCell.tap()
        app.fc_playgroundShowAuthFlowButton.tap()

        app.fc_nativeConsentAgreeButton.tap()

        let featuredLegacyTestInstitution = app.tables.cells.staticTexts["Test OAuth Institution"]
        XCTAssertTrue(featuredLegacyTestInstitution.waitForExistence(timeout: 60.0))
        featuredLegacyTestInstitution.tap()

        app.fc_nativePrepaneContinueButton.tap()

        // "Success" institution is automatically selected in the Account Picker
        app.fc_nativeConnectAccountsButton.tap()

        let emailTextField = app.textFields["email_text_field"]
        XCTAssertTrue(emailTextField.waitForExistence(timeout: 120.0))  // wait for synchronize to complete
        // there is no need to tap inside of the e-mail text
        // field because we auto-focus it
        emailTextField.typeText(emailAddress)

        let phoneTextField = app.textFields["phone_text_field"]
        XCTAssertTrue(phoneTextField.waitForExistence(timeout: 120.0))  // wait for lookup to complete
        phoneTextField.tap()
        phoneTextField.typeText("4015006000")

        let phoneTextFieldToolbarDoneButton = app.toolbars["Toolbar"].buttons["Done"]
        XCTAssertTrue(phoneTextFieldToolbarDoneButton.waitForExistence(timeout: 60.0))
        phoneTextFieldToolbarDoneButton.tap()

        let saveToLinkButon = app.buttons["networking_link_signup_footer_view.save_to_link_button"]
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
            playgroundConfigurationString:
"""
{"use_case":"payment_intent","experience":"financial_connections","sdk_type":"native","test_mode":true,"merchant":"networking","payment_method_permission":true,"transactions_permission":true,"email":"\(emailAddress)"}
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

    private func executeNativeNetworkingTestModeAutofillSignInFlowTest(emailAddress: String) {
        let app = XCUIApplication.fc_launch(
            playgroundConfigurationString:
"""
{"use_case":"payment_intent","experience":"financial_connections","sdk_type":"native","test_mode":true,"merchant":"networking","payment_method_permission":true,"transactions_permission":true,"email":"\(emailAddress)"}
"""
        )

        app.fc_playgroundCell.tap()
        app.fc_playgroundShowAuthFlowButton.tap()

        app.fc_nativeConsentAgreeButton.tap()

        let linkContinueButton = app.buttons["link_continue_button"]
        XCTAssertTrue(linkContinueButton.waitForExistence(timeout: 60.0))
        linkContinueButton.tap()

        let testModeAutofillButton = app.buttons["test_mode_autofill_button"]
        XCTAssertTrue(testModeAutofillButton.waitForExistence(timeout: 10.0))
        testModeAutofillButton.tap()

        let successInstitution = app.scrollViews.staticTexts["Success"]
        XCTAssertTrue(successInstitution.waitForExistence(timeout: 120.0)) // need to wait for various API calls to appear
        successInstitution.tap()

        let connectAccountButton = app.buttons["Connect account"]
        XCTAssertTrue(connectAccountButton.waitForExistence(timeout: 60.0))
        connectAccountButton.tap()

        XCTAssertTrue(testModeAutofillButton.waitForExistence(timeout: 10.0))
        testModeAutofillButton.tap()

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
            playgroundConfigurationString:
"""
{"use_case":"payment_intent","experience":"financial_connections","sdk_type":"native","test_mode":true,"merchant":"networking","payment_method_permission":true,"email":"\(emailAddress)"}
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
            playgroundConfigurationString:
"""
{"use_case":"data","experience":"financial_connections","sdk_type":"native","test_mode":true,"merchant":"networking","payment_method_permission":true,"ownership_permission":true,"balances_permission":true,"transactions_permission":true,"email":"\(emailAddress)"}
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

        let accountUpdateRequiredContinueButton = app.buttons["generic_info_primary_button"]
        XCTAssertTrue(accountUpdateRequiredContinueButton.waitForExistence(timeout: 10))
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
            playgroundConfigurationString:
"""
{"use_case":"data","experience":"financial_connections","sdk_type":"native","test_mode":true,"merchant":"networking","payment_method_permission":true,"ownership_permission":true,"balances_permission":true,"transactions_permission":true,"email":"\(emailAddress)"}
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

        let saveToLinkButon = app.buttons["networking_link_signup_footer_view.save_to_link_button"]
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

    func testNativeNetworkingTestModeSignUpWithPrefilledEmailAndPhone() {
        let emailAddress = "\(UUID().uuidString)@UITestForIOS.com"

        let app = XCUIApplication.fc_launch(
            playgroundConfigurationString:
"""
{"use_case":"payment_intent","experience":"financial_connections","sdk_type":"native","test_mode":true,"merchant":"networking","transactions_permission":true,"email":"\(emailAddress)","phone":"4015006000"}
"""
        )

        app.fc_playgroundCell.tap()
        app.fc_playgroundShowAuthFlowButton.tap()

        app.fc_nativeConsentAgreeButton.tap()

        let featuredLegacyTestInstitution = app.tables.cells.staticTexts["Test OAuth Institution"]
        XCTAssertTrue(featuredLegacyTestInstitution.waitForExistence(timeout: 60.0))
        featuredLegacyTestInstitution.tap()

        app.fc_nativePrepaneContinueButton.tap()

        // success institution will be selected by default

        app.fc_nativeConnectAccountsButton.tap()

        // both, email and phone, will already be pre-filled

        let saveToLinkButon = app.buttons["networking_link_signup_footer_view.save_to_link_button"]
        XCTAssertTrue(saveToLinkButon.waitForExistence(timeout: 120.0))  // glitch app can take time to lload
        saveToLinkButon.tap()

        let successPaneDoneButton = app.fc_nativeSuccessDoneButton

        // ensure that the Link text wasn't a failure
        //
        // unexpected text: "Your account was connected, but couldn't be saved to Link"
        XCTAssert(!app.textViews.containing(NSPredicate(format: "label CONTAINS 'but'")).firstMatch.exists)

        successPaneDoneButton.tap()

        XCTAssert(
            app.fc_playgroundSuccessAlertView.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Success'")).firstMatch
                .exists
        )
    }

    func testNativeNetworkingManualEntryTestMode() throws {
        let emailAddresss = "\(UUID().uuidString)@UITestForIOS.com"
        executeNativeNetworkingManualEntryTestModeSignUpFlowTest(emailAddress: emailAddresss)
        executeNativeNetworkingManualEntryTestModeSignInFlowTest(emailAddress: emailAddresss)
        executeNativeNetworkingManualEntryTestModeConsentWithUpdateRequiredTest(emailAddress: emailAddresss)
        executeNativeNetworkingManualEntryTestModeNotNowFlowTest(emailAddress: emailAddresss)
    }

    private func executeNativeNetworkingManualEntryTestModeSignUpFlowTest(emailAddress: String) {
        let app = XCUIApplication.fc_launch(
            playgroundConfigurationString:
"""
{"use_case":"payment_intent","experience":"financial_connections","sdk_type":"native","test_mode":true,"merchant":"networking","payment_method_permission":true,"email":"\(emailAddress)","phone":"4015006000"}
"""
        )

        app.fc_playgroundCell.tap()
        app.fc_playgroundShowAuthFlowButton.tap()

        app.fc_nativeManuallyVerifyLabel.waitForExistenceAndTap()

        // auto-fill manual entry screen
        app.fc_nativeTestModeAutofillButton.waitForExistenceAndTap()

        app.fc_nativeSaveToLinkButton.waitForExistenceAndTap()

        app.fc_nativeSuccessDoneButton.waitForExistenceAndTap()

        XCTAssert(app.fc_playgroundSuccessAlertView.exists)
    }

    private func executeNativeNetworkingManualEntryTestModeSignInFlowTest(emailAddress: String) {
        let app = XCUIApplication.fc_launch(
            playgroundConfigurationString:
"""
{"use_case":"token","experience":"financial_connections","sdk_type":"native","test_mode":true,"merchant":"networking","payment_method_permission":true,"email":"\(emailAddress)"}
"""
        )

        app.fc_playgroundCell.tap()
        app.fc_playgroundShowAuthFlowButton.tap()

        // we expect this to open the warm up pane (a new behavior in networking manual entry)
        app.fc_nativeManuallyVerifyLabel.waitForExistenceAndTap()

        app.fc_nativeNetworkingWarmupContinueButton.waitForExistenceAndTap()

        // auto-fill OTP
        app.fc_nativeTestModeAutofillButton.waitForExistenceAndTap()

        // tap manual entry institution
        app.scrollViews.staticTexts["Test Institution"].waitForExistenceAndTap()

        app.fc_nativeConnectAccountsButton.waitForExistenceAndTap()

        app.fc_nativeSuccessDoneButton.waitForExistenceAndTap()

        XCTAssert(app.fc_playgroundSuccessAlertView.exists)
    }

    // this test exercises a user tapping on manual entry from consent, logging into link,
    // seeing the RUX/Link Account Picker which will have a "Agree and connect account"
    // button, _and_ the user will have to update the bank account through the
    // "Account Update Required" drawer
    private func executeNativeNetworkingManualEntryTestModeConsentWithUpdateRequiredTest(emailAddress: String) {
        let linkAnDataCannotBeSharedThroughLinkAccount = {
            let app = XCUIApplication.fc_launch(
                playgroundConfigurationString:
    """
    {"use_case":"payment_intent","experience":"financial_connections","sdk_type":"native","test_mode":true,"merchant":"networking","email":"\(emailAddress)","phone":"4015006000"}
    """
            )

            app.fc_playgroundCell.tap()
            app.fc_playgroundShowAuthFlowButton.tap()

            app.fc_nativeConsentAgreeButton.tap()

            app.fc_nativeNetworkingWarmupContinueButton.waitForExistenceAndTap()

            app.fc_nativeTestModeAutofillButton.waitForExistenceAndTap()

            app.scrollViews.otherElements["add_bank_account"].waitForExistenceAndTap()

            // wait for search bar to appear
            _ = app.fc_searchBarTextField

            app.fc_scrollDown() // see all institutions

            app.fc_nativeFeaturedInstitution(name: "Data cannot be shared through Link").tap()

            // select "High Balance" instead of the default "Success" account because
            // selecting the "Success" will override the previously-linked manual entry account
            XCTAssertTrue(app.fc_nativeConnectAccountsButton.waitForExistence(timeout: 60.0))
            app.fc_scrollDown()
            app.staticTexts["High Balance"].waitForExistenceAndTap()

            app.fc_nativeConnectAccountsButton.tap()

            app.fc_nativeSuccessDoneButton.waitForExistenceAndTap()

            XCTAssert(app.fc_playgroundSuccessAlertView.exists)
        }
        linkAnDataCannotBeSharedThroughLinkAccount()

        // turn on all permissions so we get an "Update Required" account
        let app = XCUIApplication.fc_launch(
            playgroundConfigurationString:
"""
{"use_case":"token","experience":"financial_connections","sdk_type":"native","test_mode":true,"merchant":"networking","payment_method_permission":true,"ownership_permission":true,"balances_permission":true,"transactions_permission":true,"email":"\(emailAddress)"}
"""
        )

        app.fc_playgroundCell.tap()
        app.fc_playgroundShowAuthFlowButton.tap()

        // we expect this to open the warm up pane (a new behavior in networking manual entry)
        app.fc_nativeManuallyVerifyLabel.waitForExistenceAndTap()

        app.fc_nativeNetworkingWarmupContinueButton.waitForExistenceAndTap()

        // auto-fill OTP
        app.fc_nativeTestModeAutofillButton.waitForExistenceAndTap()

        // tap institution
        //
        // note that this will NOT present a drawer because user needs to consent
        app.scrollViews.staticTexts["High Balance"].waitForExistenceAndTap()

        // this will get consent
        app.fc_nativeConnectAccountsButton.waitForExistenceAndTap()

        // a drawer will present to confirm
        let accountUpdateRequiredContinueButton = app.buttons["generic_info_primary_button"]
        accountUpdateRequiredContinueButton.waitForExistenceAndTap()

        app.fc_nativeConnectAccountsButton.waitForExistenceAndTap()

        app.fc_nativeSuccessDoneButton.waitForExistenceAndTap()

        XCTAssert(app.fc_playgroundSuccessAlertView.exists)
    }

    private func executeNativeNetworkingManualEntryTestModeNotNowFlowTest(emailAddress: String) {
        let app = XCUIApplication.fc_launch(
            playgroundConfigurationString:
"""
{"use_case":"token","experience":"financial_connections","sdk_type":"native","test_mode":true,"merchant":"networking","payment_method_permission":true,"email":"\(emailAddress)"}
"""
        )

        app.fc_playgroundCell.tap()
        app.fc_playgroundShowAuthFlowButton.tap()

        // we expect this to open the warm up pane (a new behavior in networking manual entry)
        app.fc_nativeManuallyVerifyLabel.waitForExistenceAndTap()

        // pressing "Not Now" should forward to manual entry pane (a new behavior in networking manual entry)
        app.buttons["Not now"].waitForExistenceAndTap()

        // fill out manual entry
        app.fc_nativeTestModeAutofillButton.waitForExistenceAndTap()

        app.fc_nativeSuccessDoneButton.waitForExistenceAndTap()

        XCTAssert(app.fc_playgroundSuccessAlertView.exists)
    }
}
