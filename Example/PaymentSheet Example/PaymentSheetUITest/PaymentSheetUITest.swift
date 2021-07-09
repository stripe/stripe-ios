//
//  PaymentSheetUITest.swift
//  PaymentSheetUITest
//
//  Created by David Estes on 1/21/21.
//  Copyright © 2021 stripe-ios. All rights reserved.
//

import XCTest

class PaymentSheetUITest: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        
        app = XCUIApplication()
        app.launchEnvironment = ["UITesting": "true"]
        app.launch()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func fillCardData(_ app: XCUIApplication) throws {
        let numberField = app.textFields["Card number"]
        numberField.tap()
        numberField.typeText("4242424242424242")
        let expField = app.textFields["expiration date"]
        expField.tap()
        expField.typeText("1228")
        let cvcField = app.textFields["CVC"]
        cvcField.tap()
        cvcField.typeText("123")
        let postalField = app.textFields["ZIP"]
        postalField.tap()
        postalField.typeText("12345")
    }

    func waitToDisappear(_ target: Any?) {
        let exists = NSPredicate(format: "exists == 0")
        expectation(for: exists, evaluatedWith: target, handler: nil)
        waitForExpectations(timeout: 60.0, handler: nil)
    }

    func testPaymentSheetStandard() throws {
        app /*@START_MENU_TOKEN@*/.staticTexts[
            "PaymentSheet"
        ] /*[[".buttons[\"PaymentSheet\"].staticTexts[\"PaymentSheet\"]",".staticTexts[\"PaymentSheet\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
            .tap()
        let buyButton = app.staticTexts["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 60.0))
        buyButton.tap()

        try! fillCardData(app)
        app.buttons["Pay $9.73"].tap()
        let successText = app.alerts.staticTexts["Your order is confirmed!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        let okButton = app.alerts.scrollViews.otherElements.buttons["OK"]
        okButton.tap()
    }
    
    func testCardFieldAutoAdvance() throws {
        let app = XCUIApplication()
        app.launch()

        app.staticTexts[
            "PaymentSheet"
        ].tap()
        let buyButton = app.staticTexts["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 60.0))
        buyButton.tap()
        
        let numberField = app.textFields["Card number"]
        numberField.tap()
        numberField.typeText("4242424242424242")
        
        let expField = app.textFields["expiration date"]
        XCTAssertTrue((expField.value as? String)?.isEmpty ?? true)
        XCTAssertNoThrow(expField.typeText("1228"))
        
        let cvcField = app.textFields["CVC"]
        XCTAssertTrue((cvcField.value as? String)?.isEmpty ?? true)
        XCTAssertNoThrow(cvcField.typeText("123"))
        
        let postalField = app.textFields["ZIP"]
        XCTAssertTrue((postalField.value as? String)?.isEmpty ?? true)
        XCTAssertNoThrow(postalField.typeText("12345"))
    }
    
    func testCardFieldAutoAdvanceAutoTypeToPostalCode() throws {
        let app = XCUIApplication()
        app.launch()

        app.staticTexts[
            "PaymentSheet"
        ].tap()
        let buyButton = app.staticTexts["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 60.0))
        buyButton.tap()
        
        let numberField = app.textFields["Card number"]
        numberField.tap()
        numberField.typeText("4242424242424242")
        
        let expField = app.textFields["expiration date"]
        XCTAssertTrue((expField.value as? String)?.isEmpty ?? true)
        XCTAssertNoThrow(expField.typeText("1228"))
        
        let cvcField = app.textFields["CVC"]
        XCTAssertTrue((cvcField.value as? String)?.isEmpty ?? true)
        XCTAssertNoThrow(cvcField.typeText("1234"))
        
        let postalField = app.textFields["ZIP"]
        XCTAssertTrue((postalField.value as? String) ?? "" == "4")
    }
    
    func testCardFieldAutoAdvanceAmexCVV() throws {
        let app = XCUIApplication()
        app.launch()

        app.staticTexts[
            "PaymentSheet"
        ].tap()
        let buyButton = app.staticTexts["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 60.0))
        buyButton.tap()
        
        let numberField = app.textFields["Card number"]
        numberField.tap()
        numberField.typeText("378282246310005")
        
        let expField = app.textFields["expiration date"]
        XCTAssertTrue((expField.value as? String)?.isEmpty ?? true)
        XCTAssertNoThrow(expField.typeText("1228"))
        
        let cvvField = app.textFields["CVV"]
        XCTAssertTrue((cvvField.value as? String)?.isEmpty ?? true)
        XCTAssertNoThrow(cvvField.typeText("1234"))
        
        let postalField = app.textFields["ZIP"]
        XCTAssertTrue((postalField.value as? String)?.isEmpty ?? true)
        XCTAssertNoThrow(postalField.typeText("12345"))
    }

    func testPaymentSheetCustom() throws {

        app.staticTexts["PaymentSheet (Custom)"].tap()
        let paymentMethodButton = app.staticTexts["Apple Pay"]
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 60.0))
        paymentMethodButton.tap()

        let addCardButton = app.buttons["+ Add"]
        XCTAssertTrue(addCardButton.waitForExistence(timeout: 4.0))
        addCardButton.tap()

        try! fillCardData(app)
        app.buttons["Add card"].tap()

        let buyButton = app.staticTexts["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 4.0))
        buyButton.tap()

        let successText = app.alerts.staticTexts["Your order is confirmed!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        let okButton = app.alerts.scrollViews.otherElements.buttons["OK"]
        okButton.tap()
    }

    func testPaymentSheetCustomRemoveCard() throws {
        app.staticTexts["PaymentSheet (test playground)"].tap()
        app.buttons["new"].tap() // new customer
        app.buttons["off"].tap() // disable Apple Pay
        app.buttons["Reload PaymentSheet"].tap()

        var paymentMethodButton = app.staticTexts["Select"]
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 60.0))
        paymentMethodButton.tap()

        try! fillCardData(app)

        // toggle save this card
        let saveThisCardToggle = app.switches["Save this card for future Example, Inc. payments"]
        XCTAssertTrue(saveThisCardToggle.isSelected)
        saveThisCardToggle.tap()
        XCTAssertFalse(saveThisCardToggle.isSelected)
        saveThisCardToggle.tap()
        XCTAssertTrue(saveThisCardToggle.isSelected)

        // Add the card
        app.buttons["Add card"].tap()

        // Complete payment
        app.buttons["Checkout (Custom)"].tap()
        let successText = app.alerts.staticTexts["success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        app.alerts.scrollViews.otherElements.buttons["OK"].tap()

        // Reload w/ same customer
        app.buttons["Reload PaymentSheet"].tap()

        expectation(
            for: NSPredicate(format: "enabled == true"),
            evaluatedWith: app.buttons["Checkout (Custom)"],
            handler: nil
        )
        waitForExpectations(timeout: 10, handler: nil)

        // return to payment method selector
        paymentMethodButton = app.staticTexts["••••4242"]
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 60.0))
        paymentMethodButton.tap()

        let editButton = app.staticTexts["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 60.0))
        editButton.tap()

        let removeButton = app.buttons["Remove"]
        XCTAssertTrue(removeButton.waitForExistence(timeout: 60.0))
        removeButton.tap()

        let confirmRemoval = app.alerts.buttons["Remove"]
        XCTAssertTrue(confirmRemoval.waitForExistence(timeout: 60.0))
        confirmRemoval.tap()

        XCTAssertTrue(app.cells.count == 1)
    }

    func testPaymentSheetSwiftUI() throws {
        app.staticTexts["PaymentSheet (SwiftUI)"].tap()
        let buyButton = app.buttons["Buy button"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 60.0))
        buyButton.forceTapElement()

        try! fillCardData(app)
        app.buttons["Pay $9.73"].tap()
        let successText = app.staticTexts["Payment status view"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        XCTAssertNotNil(successText.label.range(of: "Your order is confirmed!"))
    }

    func testPaymentSheetSwiftUICustom() throws {
        app.staticTexts["PaymentSheet (SwiftUI Custom)"].tap()
        let paymentMethodButton = app.buttons["Payment method"]
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 60.0))
        paymentMethodButton.forceTapElement()

        let addCardButton = app.buttons["+ Add"]
        XCTAssertTrue(addCardButton.waitForExistence(timeout: 4.0))
        addCardButton.tap()
        try! fillCardData(app)
        app.buttons["Add card"].tap()

        // XCTest is too eager to tap the buy button: Wait until the sheet dismisses first.
        waitToDisappear(app.textFields["Card number"])

        let buyButton = app.buttons["Buy button"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 4.0))
        buyButton.forceTapElement()

        let successText = app.staticTexts["Payment status view"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
        XCTAssertNotNil(successText.label.range(of: "Your order is confirmed!"))
    }
    
    // iDEAL has some text fields and a dropdown, and
    func testIdealPaymentMethod() throws {
        app.staticTexts["PaymentSheet (test playground)"].tap()
        app.buttons["new"].tap() // new customer
        app.buttons["off"].tap() // disable Apple Pay
        app.buttons["EUR"].tap() // EUR currency
        app.buttons["Reload PaymentSheet"].tap()

        let checkout = app.buttons["Checkout (Complete)"]
        expectation(
            for: NSPredicate(format: "enabled == true"),
            evaluatedWith: checkout,
            handler: nil
        )
        waitForExpectations(timeout: 60.0, handler: nil)
        checkout.tap()
        let payButton = app.buttons["Pay €9.73"]
        
        // Select iDEAL
        app.cells["iDEAL"].tap()

        XCTAssertFalse(payButton.isEnabled)
        let name = app.textFields["Name"]
        name.tap()
        name.typeText("John Doe")
        name.typeText(XCUIKeyboardKey.return.rawValue)
        
        app.typeText("stripe@stripe.com")
        app.typeText(XCUIKeyboardKey.return.rawValue)

        let bank = app.textFields["iDEAL Bank"]
        bank.tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "ASN Bank")
        app.toolbars.buttons["Done"].tap()

        // Attempt payment
        payButton.tap()
        
        // Close the webview, no need to see the successful pay
        let webviewCloseButton = app.otherElements["TopBrowserBar"].buttons["Close"]
        XCTAssertTrue(webviewCloseButton.waitForExistence(timeout: 10.0))
        webviewCloseButton.tap()
    }
}

// There seems to be an issue with our SwiftUI buttons - XCTest fails to scroll to the button's position.
// Work around this by targeting a coordinate inside the button.
// https://stackoverflow.com/questions/33422681/xcode-ui-test-ui-testing-failure-failed-to-scroll-to-visible-by-ax-action
extension XCUIElement {
    func forceTapElement() {
        if self.isHittable {
            self.tap()
        } else {
            // Tap the middle of the element.
            // (Sometimes the edges of rounded buttons aren't tappable in certain web elements.)
            let coordinate: XCUICoordinate = self.coordinate(
                withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            coordinate.tap()
        }
    }
}
