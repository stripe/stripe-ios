//
//  PaymentSheetLocalizationScreenshotGenerator.swift
//  PaymentSheetLocalizationScreenshotGenerator
//
//  Created by Cameron Sabol on 7/28/21.
//  Copyright © 2021 stripe-ios. All rights reserved.
//

import XCTest

@testable import PaymentSheet_Example

class PaymentSheetLocalizationScreenshotGenerator: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        
        app = XCUIApplication()
        app.launchEnvironment = ["UITesting": "true"]
        app.launch()
    }
    
    func waitToAppear(_ target: XCUIElement?) {
        _ = target?.waitForExistence(timeout: 60)
    }
    
    func saveScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
        attachment.lifetime = .keepAlways
        attachment.name = name
        add(attachment)
    }
    
    func scrollToPaymentMethodCell(_ cell: String) {
        let paymentMethodTypeCollectionView = app.collectionViews["PaymentMethodTypeCollectionView"]
        waitToAppear(paymentMethodTypeCollectionView)
        let targetCell = paymentMethodTypeCollectionView.cells[cell]
        
        // This is not particularly efficient or robust but it's working
        // Unfortunately UICollectionViews are setup for KVO so we can't query
        // contentOffset or contentSize here
        let maxScrollPerDirection = 10
        var scrollsLeft = 0
        var scrollsRight = 0
        while !targetCell.isHittable,
              (scrollsLeft < maxScrollPerDirection ||
              scrollsRight < maxScrollPerDirection) {
            if scrollsLeft < maxScrollPerDirection {
                paymentMethodTypeCollectionView.swipeLeft()
                scrollsLeft += 1
            } else if scrollsRight < maxScrollPerDirection {
                paymentMethodTypeCollectionView.swipeRight()
                scrollsRight += 1
            }
        }
        waitToAppear(targetCell)
    }

    func testAllStrings() {
        app.staticTexts["PaymentSheet (test playground)"].tap()
        app.segmentedControls["customer_mode_selector"].buttons["new"].tap() // new customer
        app.segmentedControls["apple_pay_selector"].buttons["off"].tap() // disable Apple Pay
        app.segmentedControls["currency_selector"].buttons["EUR"].tap() // EUR currency
        app.segmentedControls["mode_selector"].buttons["Pay"].tap() // PaymentIntent
        app.segmentedControls["automatic_payment_methods_selector"].buttons["off"].tap() // disable automatic payment methods
        app.buttons["Reload PaymentSheet"].tap()
        
        let checkout = app.buttons["Checkout (Complete)"]
        expectation(
            for: NSPredicate(format: "enabled == true"),
            evaluatedWith: checkout,
            handler: nil
        )
        waitForExpectations(timeout: 60.0, handler: nil)
        checkout.tap()

        do {
            let cardCell = app.cells["card"]
            scrollToPaymentMethodCell("card")

            cardCell.tap()
            saveScreenshot("card_entry")

            let numberField = app.textFields["Card number"]
            let expField = app.textFields["expiration date"]
            let cvcField = app.textFields["CVC"]
            let postalField = app.textFields["Postal Code"]

            numberField.tap()
            numberField.typeText("1234")
            expField.clearText()
            cvcField.clearText()
            if postalField.exists, postalField.isHittable {
                postalField.clearText()
            }
            saveScreenshot("card_bad_number")

            numberField.clearText()
            numberField.tap()
            numberField.typeText("4")
            expField.clearText()
            cvcField.clearText()
            if postalField.exists, postalField.isHittable {
                postalField.clearText()
            }
            cvcField.tap()
            saveScreenshot("card_incomplete_number")

            numberField.clearText()
            expField.tap()
            expField.typeText("1111")
            cvcField.clearText()
            if postalField.exists, postalField.isHittable {
                postalField.clearText()
            }
            saveScreenshot("card_bad_exp_year")

            numberField.clearText()
            expField.clearText()
            expField.tap()
            expField.typeText("13")
            cvcField.clearText()
            if postalField.exists, postalField.isHittable {
                postalField.clearText()
            }
            saveScreenshot("card_bad_exp_month")

            numberField.clearText()
            expField.clearText()
            expField.tap()
            expField.typeText("1311")
            cvcField.clearText()
            if postalField.exists, postalField.isHittable {
                postalField.clearText()
            }
            saveScreenshot("card_bad_exp_date")

            numberField.clearText()
            expField.clearText()
            expField.tap()
            expField.typeText("1")
            cvcField.clearText()
            if postalField.exists, postalField.isHittable {
                postalField.clearText()
            }
            cvcField.tap()
            saveScreenshot("card_incomplete_exp_date")


            numberField.clearText()
            expField.clearText()
            cvcField.tap()
            cvcField.typeText("1")
            if postalField.exists, postalField.isHittable {
                postalField.clearText()
            }
            numberField.tap()
            saveScreenshot("card_incomplete_cvc")

        }

        do {
            let idealCell = app.cells["ideal"]
            scrollToPaymentMethodCell("ideal")

            idealCell.tap()
            idealCell.tap() // hacky to double tap but fixes transition if software keyboard is enabled
            saveScreenshot("ideal_entry")
        }
        
        do {
            let bancontactCell = app.cells["bancontact"]
            scrollToPaymentMethodCell("bancontact")
            
            bancontactCell.tap()
            bancontactCell.tap() // hacky to double tap but fixes transition if software keyboard is enabled
            saveScreenshot("bancontact_entry")
        }

        app.buttons["UIButton.Close"].tap()
        waitToAppear(app.buttons["Checkout (Complete)"])

        app.segmentedControls["mode_selector"].buttons["Setup"].tap() // setup intent
        app.buttons["Reload PaymentSheet"].tap()

        expectation(
            for: NSPredicate(format: "enabled == true"),
            evaluatedWith: checkout,
            handler: nil
        )
        waitForExpectations(timeout: 60.0, handler: nil)
        checkout.tap()

        do {
            saveScreenshot("card_entry_setup")
        }

        app.buttons["UIButton.Close"].tap()
        // This section commented out for CI since it depends on global state
        // of the returning customer. Uncomment when generating screenshots
//        waitToAppear(app.buttons["Checkout (Complete)"])
//
//        app.segmentedControls["mode_selector"].buttons["Pay"].tap() // payment intent
//        app.segmentedControls["customer_mode_selector"].buttons["returning"].tap() // returning customer
//        app.buttons["Reload PaymentSheet"].tap()
//
//        expectation(
//            for: NSPredicate(format: "enabled == true"),
//            evaluatedWith: checkout,
//            handler: nil
//        )
//        waitForExpectations(timeout: 60.0, handler: nil)
//        checkout.tap()
//
//        do {
//            let editButton = app.buttons["edit_saved_button"]
//            waitToAppear(editButton)
//            saveScreenshot("payment_selector")
//
//            editButton.tap()
//            saveScreenshot("payment_selector_editing")
//
//            app.cells.containing(.button, identifier: "Remove").firstMatch.buttons["Remove"].tap()
//            saveScreenshot("removing_payment_method_confirmation")
//        }
        
        
    }
}

extension XCUIElement {
    func clearText() {
        guard let stringValue = value as? String, !stringValue.isEmpty else {
            return
        }
        
        // offset tap location a bit so cursor is at end of string
        let offsetTapLocation = coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.6))
        offsetTapLocation.tap()

        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
    }
}
