//
//  PaymentSheetBillingCollectionUITests.swift
//  PaymentSheetUITest
//
//  Created by Eduardo Urias on 2/23/23.
//

import XCTest

class PaymentSheetBillingCollectionUITestCase: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()

        continueAfterFailure = false

        app = XCUIApplication()
        app.launchEnvironment = ["UITesting": "true"]
    }

    var cardInfoField: XCUIElement { app.staticTexts["Card information"] }
    var contactInfoField: XCUIElement { app.staticTexts["Contact information"] }
    var fullNameField: XCUIElement { app.textFields["Full name"] }
    var nameOnCardField: XCUIElement { app.textFields["Name on card"] }
    var emailField: XCUIElement { app.textFields["Email"] }
    var phoneField: XCUIElement { app.textFields["Phone number"] }
    var billingAddressField: XCUIElement { app.staticTexts["Billing address"] }
    var billingDetailsField: XCUIElement { app.staticTexts["Billing details"] }
    var countryField: XCUIElement { app.textFields["Country or region"] }
    var line1Field: XCUIElement { app.textFields["Address line 1"] }
    var line2Field: XCUIElement { app.textFields["Address line 2"] }
    var cityField: XCUIElement { app.textFields["City"] }
    var stateField: XCUIElement { app.textFields["State"] }
    var zipField: XCUIElement { app.textFields["ZIP"] }
    var checkoutButton: XCUIElement { app.buttons["Present PaymentSheet"] }
    var payButton: XCUIElement { app.buttons["Pay $50.99"] }
    var successText: XCUIElement { app.staticTexts["Success!"] }

    // FlowController specific buttons
    var paymentMethodSelectorNoneButton: XCUIElement { app.buttons["None"] }
    var confirmButton: XCUIElement { app.buttons["Confirm"] }
    var continueButton: XCUIElement { app.buttons["Continue"] }

}




