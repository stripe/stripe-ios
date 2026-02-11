//
//  PaymentSheetUITestCase+Helpers.swift
//  PaymentSheet Example
//
//  Created by David Estes on 2/11/26.
//


import XCTest

extension PaymentSheetUITestCase {
    func _testUSBankAccount(mode: PaymentSheetTestPlaygroundSettings.Mode, integrationType: PaymentSheetTestPlaygroundSettings.IntegrationType, vertical: Bool = false) {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.apmsEnabled = .off
        settings.allowsDelayedPMs = .on
        settings.mode = mode
        settings.customerKeyType = .customerSession
        settings.integrationType = integrationType
        if vertical {
            settings.layout = .vertical
        }

        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].tap()

        // Select US bank account
        if vertical {
            XCTAssertTrue(app.buttons["US bank account"].waitForExistenceAndTap())
        } else {
            XCTAssertTrue(scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "US bank account")?.waitForExistenceAndTap() ?? false)
        }

        // Fill out name and email fields
        let continueButton = app.buttons["Continue"]
        XCTAssertFalse(continueButton.isEnabled)
        app.textFields["Full name"].tap()
        app.typeText("John Doe" + XCUIKeyboardKey.return.rawValue)
        app.typeText("test-\(UUID().uuidString)@example.com" + XCUIKeyboardKey.return.rawValue)
        XCTAssertTrue(continueButton.isEnabled)
        continueButton.tap()

        // Go through connections flow
        app.buttons["Agree and continue"].tap()
        app.staticTexts["Test (Non-OAuth)"].forceTapElement()
        // "Success" institution is automatically selected because its the first
        app.buttons["connect_accounts_button"].waitForExistenceAndTap(timeout: 10)

        skipLinkSignup(app)

        XCTAssertTrue(app.staticTexts["Success"].waitForExistence(timeout: 10))
        app.buttons.matching(identifier: "Done").allElementsBoundByIndex.last?.tap()

        // Make sure bottom notice mandate is visible
        let paymentMandateText = "By continuing, you agree to authorize payments pursuant to these terms."
        let setupMandateText = "By saving your bank account for Example, Inc. you agree to authorize payments pursuant to these terms."

        switch mode {
        case .payment:
            // Save the payment method
            XCTAssertTrue(app.textViews[paymentMandateText].waitForExistence(timeout: 5))
            let saveThisAccountToggle = app.switches["Save this account for future Example, Inc. payments"]
            XCTAssertFalse(saveThisAccountToggle.isSelected)
            saveThisAccountToggle.tap()

            // Tapping the checkbox changes the mandate
            XCTAssertTrue(app.textViews[setupMandateText].waitForExistence(timeout: 5))
        default:
            // Since the payment method is being set up, it always shows the setup mandate
            XCTAssertTrue(app.textViews[setupMandateText].waitForExistence(timeout: 5))
            let saveThisAccountToggle = app.switches["Save this account for future Example, Inc. payments"]
            XCTAssertFalse(saveThisAccountToggle.isSelected)
            saveThisAccountToggle.tap()

            // Tapping the checkbox doesn't change the mandate
            XCTAssertTrue(app.textViews[setupMandateText].waitForExistence(timeout: 5))
        }

        // Confirm
        let confirmButtonText = mode == .payment ? "Pay $50.99" : "Set up"

        app.buttons[confirmButtonText].waitForExistenceAndTap()
        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))

        // Reload and pay with the now-saved US bank account
        reload(app, settings: settings)
        app.buttons["Present PaymentSheet"].tap()
        XCTAssertTrue(app.buttons["••••6789"].waitForExistenceAndTap())

        // Make sure bottom notice mandate is visible
        XCTAssertTrue(app.textViews["By continuing, you agree to authorize payments pursuant to these terms."].exists)

        app.buttons[confirmButtonText].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10))
    }

    func _testInstantDebits(
        mode: PaymentSheetTestPlaygroundSettings.Mode,
        vertical: Bool = false,
        useLinkCardBrand: Bool = false,
        uiStyle: PaymentSheetTestPlaygroundSettings.UIStyle = .paymentSheet
    ) {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.mode = mode
        settings.uiStyle = uiStyle
        settings.apmsEnabled = .off
        settings.supportedPaymentMethods = useLinkCardBrand ? "card" : "card,link"
        if vertical {
            settings.layout = .vertical
        }

        loadPlayground(app, settings)

        if uiStyle == .flowController {
            app.buttons["Apple Pay, apple_pay"].waitForExistenceAndTap(timeout: 30) // Should default to Apple Pay
            app.buttons["+ Add"].waitForExistenceAndTap()
        } else {
            app.buttons["Present PaymentSheet"].tap()
        }

        // Select "Bank"
        if vertical {
            XCTAssertTrue(app.buttons["Bank"].waitForExistenceAndTap())
        } else {
            XCTAssertTrue(scroll(collectionView: app.collectionViews.firstMatch, toFindCellWithId: "Bank")?.waitForExistenceAndTap() ?? false)
        }
        let email = "paymentsheetuitest-\(UUID().uuidString)@example.com"

        // Fill out name and email fields
        let continueButton = app.buttons["Continue"]
        XCTAssertFalse(continueButton.isEnabled)
        app.textFields["Email"].tap()
        app.typeText(email + XCUIKeyboardKey.return.rawValue)
        XCTAssertTrue(continueButton.isEnabled)
        continueButton.tap()

        Self.stepThroughNativeInstantDebitsFlow(app: app)

        // Back to Payment Sheet
        switch uiStyle {
        case .paymentSheet:
            app.buttons[mode == .setup ? "Set up" : "Pay $50.99"].waitForExistenceAndTap(timeout: 10)
        case .flowController, .embedded:
            // Give time for the dismiss animation
            sleep(2)
            app.buttons["Continue"].waitForExistenceAndTap(timeout: 10)
            XCTAssertTrue(app.staticTexts["••••6789"].waitForExistence(timeout: 10))
            app.buttons["Confirm"].waitForExistenceAndTap(timeout: 10)
        }

        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
    }

    func payWithApplePay() {
        let applePay = XCUIApplication(bundleIdentifier: "com.apple.PassbookUIService")
        _ = applePay.wait(for: .runningForeground, timeout: 10)

        addApplePayContactIfNeeded(applePay)

        let predicate = NSPredicate(format: "label CONTAINS 'Simulated Card - AmEx, ‪•••• 1234‬'")

        let cardButton = applePay.buttons.containing(predicate).firstMatch
        XCTAssertTrue(cardButton.waitForExistence(timeout: 10.0))
        cardButton.forceTapElement()

        addApplePayBillingIfNeeded(applePay)

        let cardSelectionButton = applePay.buttons["Simulated Card - AmEx, ‪•••• 1234‬"].firstMatch
        XCTAssertTrue(cardSelectionButton.waitForExistence(timeout: 10.0))
        cardSelectionButton.forceTapElement()

        let payButton = applePay.buttons["Pay with Passcode"]
        XCTAssertTrue(payButton.waitForExistence(timeout: 10.0))
        payButton.forceTapElement()

        let successText = app.staticTexts["Success!"]
        //      This actually takes upwards of 20 seconds sometimes, especially in the deferred flow :/
        XCTAssertTrue(successText.waitForExistence(timeout: 30.0))
    }

    func addApplePayBillingIfNeeded(_ applePay: XCUIApplication) {
        // Fill out billing details if required
        let addBillingDetailsButton = applePay.buttons["Add Billing Address"]
        if addBillingDetailsButton.waitForExistence(timeout: 4.0) {
            addBillingDetailsButton.tap()

            let firstNameCell = applePay.textFields["First Name"]
            firstNameCell.tap()
            firstNameCell.typeText("Jane")

            let lastNameCell = applePay.textFields["Last Name"]
            lastNameCell.tap()
            lastNameCell.typeText("Doe")

            let streetCell = applePay.textFields["Street"]
            streetCell.tap()
            streetCell.typeText("One Apple Park Way")

            let cityCell = applePay.textFields["City"]
            cityCell.tap()
            cityCell.typeText("Cupertino")

            let stateCell = applePay.textFields["State"]
            stateCell.tap()
            stateCell.typeText("CA")

            let zipCell = applePay.textFields["ZIP"]
            zipCell.tap()
            zipCell.typeText("95014")

            applePay.buttons["Done"].tap()
        }
    }

    func addApplePayContactIfNeeded(_ applePay: XCUIApplication) {
        // Fill out contact info (email) if required
        let addEmailButton = applePay.buttons["Add Email Address"]
        if addEmailButton.waitForExistence(timeout: 4.0) {
            addEmailButton.tap()
            XCTAssertTrue(applePay.staticTexts["Select An Email Address"].waitForExistence(timeout: 4.0))
            applePay.buttons.matching(identifier: "Add Email Address").element(boundBy: 1).tap()
            applePay.typeText("test@example.com")
            // Hit the checkmark done button in the top right
            applePay.buttons["Done"].tap()
        }
    }

    func _testCardBrandChoice(isSetup: Bool = false, settings: PaymentSheetTestPlaygroundSettings) {
        app.buttons["Present PaymentSheet"].tap()

        let cardBrandTextField = app.textFields["Select card brand (optional)"]
        let cardBrandChoiceDropdown = app.pickerWheels.firstMatch
        // Card brand choice textfield/dropdown should not be visible
        XCTAssertFalse(cardBrandTextField.waitForExistence(timeout: 2))

        let numberField = app.textFields["Card number"]
        numberField.tap()
        // Enter 8 digits to start fetching card brand
        numberField.typeText("49730197")

        // Card brand choice drop down should be enabled
        cardBrandTextField.tap()
        XCTAssertTrue(cardBrandChoiceDropdown.waitForExistence(timeout: 5))
        cardBrandChoiceDropdown.swipeUp()
        app.toolbars.buttons["Cancel"].tap()

        // We should still have no selected card brand
        XCTAssertTrue(app.textFields["Select card brand (optional)"].waitForExistence(timeout: 2))

        // Select Visa from the CBC dropdown
        cardBrandTextField.tap()
        XCTAssertTrue(cardBrandChoiceDropdown.waitForExistence(timeout: 5))
        cardBrandChoiceDropdown.swipeUp()
        app.toolbars.buttons["Done"].tap()

        // We should have selected Visa
        XCTAssertTrue(app.textFields["Visa"].waitForExistence(timeout: 5))

        // Clear card text field, should reset selected card brand
        numberField.tap()
        numberField.clearText()

        // We should reset to showing unknown in the textfield for card brand
        XCTAssertFalse(app.textFields["Select card brand (optional)"].waitForExistence(timeout: 2))

        // Type full card number to start fetching card brands again
        numberField.forceTapWhenHittableInTestCase(self)
        app.typeText("4000002500001001")
        app.textFields["expiration date"].waitForExistenceAndTap(timeout: 5.0)
        app.typeText("1228") // Expiry
        app.typeText("123") // CVC
        app.typeText("12345") // Postal

        // Card brand choice drop down should be enabled
        XCTAssertTrue(app.textFields["Select card brand (optional)"].waitForExistenceAndTap(timeout: 5))
        XCTAssertTrue(cardBrandChoiceDropdown.waitForExistence(timeout: 5))
        cardBrandChoiceDropdown.swipeUp() // Swipe to select Visa
        app.toolbars.buttons["Done"].tap()

        // We should have selected Visa
        XCTAssertTrue(app.textFields["Visa"].waitForExistence(timeout: 5))

        // Finish checkout
        let confirmButtonText = isSetup ? "Set up" : "Pay €50.99"
        app.buttons[confirmButtonText].tap()
        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    static func stepThroughNativeInstantDebitsFlow(app: XCUIApplication, emailPrefilled: Bool = true) {
        // "Consent" pane
        app.buttons["Agree and continue"].waitForExistenceAndTap(timeout: 10)

        // "Sign Up" pane
        if !emailPrefilled {
            app.textFields
                .matching(NSPredicate(format: "label CONTAINS 'Email address'"))
                .firstMatch
                .waitForExistenceAndTap(timeout: 10)
            let email = "linkpaymentcontrolleruitest-\(UUID().uuidString)@example.com"
            app.typeText(email + XCUIKeyboardKey.return.rawValue)
        }

        let phoneTextField = app.textFields["phone_text_field"]
        XCTAssertTrue(phoneTextField.waitForExistence(timeout: 10.0), "Failed to find phone text field")

        let countryCodeSelector = app.otherElements["phone_country_code_selector"]
        XCTAssertTrue(countryCodeSelector.waitForExistence(timeout: 10.0), "Failed to find phone text field")
        countryCodeSelector.tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "🇺🇸 United States (+1)")
        app.toolbars.buttons["Done"].tap()

        sleep(1) // Wait for keyboard to dismiss
        phoneTextField.tap()
        phoneTextField.typeText("4015006000")

        let linkLoginCtaButton = app.buttons["link_login.primary_button"]
        XCTAssertTrue(linkLoginCtaButton.waitForExistence(timeout: 10.0))
        linkLoginCtaButton.tap()

        // "Institution picker" pane
        let featuredLegacyTestInstitution = app.tables.cells.staticTexts["Success"]
        XCTAssertTrue(featuredLegacyTestInstitution.waitForExistence(timeout: 60.0))
        featuredLegacyTestInstitution.tap()

        let accountPickerLinkAccountsButton = app.buttons["connect_accounts_button"]
        XCTAssertTrue(accountPickerLinkAccountsButton.waitForExistence(timeout: 120.0), "Failed to open Account Picker pane - \(#function) waiting failed")  // wait for accounts to fetch
        XCTAssert(accountPickerLinkAccountsButton.isEnabled, "no account selected")
        accountPickerLinkAccountsButton.tap()

        // "Success" pane
        let successDoneButton = app.buttons["success_done_button"]
        XCTAssertTrue(successDoneButton.waitForExistence(timeout: 120.0), "Failed to open Success pane - \(#function) waiting failed")  // wait for accounts to link
        successDoneButton.tap()
    }
}
