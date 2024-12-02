//
//  InstantDebitsUITests.swift
//  FinancialConnectionsUITests
//
//  Created by Mat Schmid on 2024-08-15.
//

import XCTest

final class InstantDebitsUITests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
    }

    func test_nux() {
        let app = XCUIApplication.fc_launch(playgroundConfigurationString:
            """
            {"use_case":"payment_intent","experience":"instant_debits","sdk_type":"native","test_mode":true,"merchant":"default","payment_method_permission":true}
            """
        )

        app.fc_playgroundCell.tap()
        app.fc_playgroundShowAuthFlowButton.tap()

        app.fc_nativeConsentAgreeButton.tap()

        let emailTextField = app.textFields["email_text_field"]
        XCTAssertTrue(emailTextField.waitForExistence(timeout: 10.0), "Failed to find email text field")
        emailTextField.typeText("\(UUID().uuidString)@uitest.com")

        let phoneTextField = app.textFields["phone_text_field"]
        XCTAssertTrue(phoneTextField.waitForExistence(timeout: 10.0), "Failed to find phone text field")

        let countryCodeSelector = app.otherElements["phone_country_code_selector"]
        XCTAssertTrue(countryCodeSelector.waitForExistence(timeout: 10.0), "Failed to find phone text field")
        countryCodeSelector.tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "🇺🇸 United States (+1)")
        app.toolbars.buttons["Done"].tap()

        phoneTextField.tap()
        phoneTextField.typeText("4015006000")

        let linkLoginCtaButton = app.buttons["link_login.primary_button"]
        XCTAssertTrue(linkLoginCtaButton.waitForExistence(timeout: 10.0))
        linkLoginCtaButton.tap()

        let featuredLegacyTestInstitution = app.tables.cells.staticTexts["Payment Success"]
        XCTAssertTrue(featuredLegacyTestInstitution.waitForExistence(timeout: 60.0))
        featuredLegacyTestInstitution.tap()

        app.fc_nativeConnectAccountsButton.tap()
        app.fc_nativeSuccessDoneButton.tap()
    }

    func test_rux() {
        let app = XCUIApplication.fc_launch(playgroundConfigurationString:
            """
            {"use_case":"payment_intent","experience":"instant_debits","sdk_type":"native","test_mode":true,"merchant":"default","payment_method_permission":true}
            """
        )

        app.fc_playgroundCell.tap()
        app.fc_playgroundShowAuthFlowButton.tap()

        app.fc_nativeConsentAgreeButton.tap()

        let emailTextField = app.textFields["email_text_field"]
        XCTAssertTrue(emailTextField.waitForExistence(timeout: 10.0), "Failed to find email text field")
        emailTextField.typeText("test@test.com")

        let testModeAutofillButton = app.buttons["test_mode_autofill_button"]
        XCTAssertTrue(testModeAutofillButton.waitForExistence(timeout: 10.0))
        testModeAutofillButton.tap()

        let successBankAccountRow = app.staticTexts["Success"]
        XCTAssertTrue(successBankAccountRow.waitForExistence(timeout: 60.0))
        successBankAccountRow.tap()

        app.fc_nativeConnectAccountsButton.tap()
        app.fc_nativeSuccessDoneButton.tap()
    }

    func test_accountHolder() {
        let app = XCUIApplication.fc_launch(playgroundConfigurationString:
            """
            {"use_case":"payment_intent","experience":"instant_debits","sdk_type":"native","test_mode":true,"merchant":"default","payment_method_permission":true,"email":"test@test.com"}
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

        let successBankAccountRow = app.staticTexts["Success"]
        XCTAssertTrue(successBankAccountRow.waitForExistence(timeout: 60.0))
        successBankAccountRow.tap()

        app.fc_nativeConnectAccountsButton.tap()
        app.fc_nativeSuccessDoneButton.tap()
    }
    
    func test_connect() {
        let app = XCUIApplication.fc_launch(playgroundConfigurationString:
            """
            {"use_case":"payment_intent","experience":"instant_debits","sdk_type":"native","test_mode":true,"merchant":"connect","payment_method_permission":true,"email":"email@email.com"}
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

        let successBankAccountRow = app.staticTexts["Success"]
        XCTAssertTrue(successBankAccountRow.waitForExistence(timeout: 60.0))
        successBankAccountRow.tap()

        app.fc_nativeConnectAccountsButton.tap()
        app.fc_nativeSuccessDoneButton.tap()
    }
}
