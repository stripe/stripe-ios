//
//  LinkTestHelpers.swift
//  PaymentSheetUITest
//
//  Created by Till Hellmund on 3/28/25.
//

import XCTest

extension XCTestCase {

    func createLinkPlaygroundSettings(
        passthroughMode: Bool,
        collectBillingDetails: Bool
    ) -> PaymentSheetTestPlaygroundSettings {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .guest
        settings.linkPassthroughMode = passthroughMode ? .passthrough : .pm
        settings.defaultBillingAddress = .off
        settings.apmsEnabled = .off
        settings.supportedPaymentMethods = passthroughMode ? "card" : "card,link"

        if collectBillingDetails {
            settings.collectAddress = .full
            settings.collectEmail = .always
            settings.collectName = .always
            settings.collectPhone = .always
        }

        return settings
    }

    func signUpFor(
        _ app: XCUIApplication,
        email: String
    ) {
        app.buttons["Pay with Link"].waitForExistenceAndTap()

        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 10.0))
        emailField.typeText(email)

        let phoneField = app.textFields["Phone number"]
        XCTAssertTrue(phoneField.waitForExistenceAndTap(timeout: 10.0))
        phoneField.typeText("3432353214")

        let nameField = app.textFields["Full name"]
        let showingNameField = nameField.waitForExistence(timeout: 10.0)
        if showingNameField {
            nameField.tap()
            nameField.typeText("John Doe")
        }

        XCTAssertTrue(app.buttons["Agree and continue"].waitForExistenceAndTap(timeout: 10))
    }

    func fillOutLinkCardData(
        _ app: XCUIApplication,
        cardNumber: String,
        cvc: String,
        includingBillingDetails: Bool
    ) {
        try! fillCardData(app, cardNumber: cardNumber, cvc: cvc, postalEnabled: !includingBillingDetails)

        if includingBillingDetails {
            fillOutBillingDetails(app)
        } else {
            XCTAssertTrue(app.toolbars.buttons["Done"].waitForExistenceAndTap(timeout: 10))
        }
    }

    func fillOutBillingDetails(_ app: XCUIApplication) {
        let nameField = app.textFields["Name on card"]
        nameField.tap()
        nameField.typeText("Jane Doe")

        let line1Field = app.textFields["Address line 1"]
        line1Field.tap()
        line1Field.typeText("123 Main St")

        let cityField = app.textFields["City"]
        cityField.tap()
        cityField.typeText("Big City")

        let zipField = app.textFields["ZIP"]
        zipField.tap()
        zipField.typeText("12345")

        XCTAssertTrue(app.toolbars.buttons["Done"].waitForExistenceAndTap(timeout: 10))
    }

    func logInToLink(
        _ app: XCUIApplication,
        email: String
    ) {
        app.buttons["Pay with Link"].waitForExistenceAndTap()

        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 10.0))
        emailField.typeText(email)

        let otcField = app.textViews["Code field"]
        XCTAssertTrue(otcField.waitForExistence(timeout: 10.0))
        otcField.typeText("000000")
    }

    func payLink(_ app: XCUIApplication) {
        app.buttons
            .matching(identifier: "Pay $50.99")
            .matching(NSPredicate(format: "isEnabled == true"))
            .firstMatch
            .waitForExistenceAndTap()
    }

    func assertLinkPaymentSuccess(_ app: XCUIApplication) {
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
    }
}
