//
//  PaymentSheetStandardLPMUICBCTests.swift
//  PaymentSheet Example
//
//  Created by David Estes on 2/11/26.
//

import XCTest

class PaymentSheetStandardLPMUICBCTests: PaymentSheetStandardLPMUICase {
    // MARK: Card brand choice

    func testCardBrandChoice() throws {
        // Currently only our French merchant is eligible for card brand choice
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        settings.preferredNetworksEnabled = .off
        settings.apmsEnabled = .off
        settings.supportedPaymentMethods = "card"
        loadPlayground(app, settings)

        _testCardBrandChoice(settings: settings)
    }

    func testCardBrandChoice_setup() throws {
        // Currently only our French merchant is eligible for card brand choice
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.mode = .setup
        settings.customerMode = .new
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        settings.preferredNetworksEnabled = .off
        settings.apmsEnabled = .off
        settings.supportedPaymentMethods = "card"
        loadPlayground(app, settings)

        _testCardBrandChoice(isSetup: true, settings: settings)
    }

    func testCardBrandChoice_deferred() throws {
        // Currently only our French merchant is eligible for card brand choice
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        settings.preferredNetworksEnabled = .off
        settings.integrationType = .deferred_csc
        settings.apmsEnabled = .off
        settings.supportedPaymentMethods = "card"
        loadPlayground(app, settings)

        _testCardBrandChoice(settings: settings)
    }

    func testCardBrandChoiceWithPreferredNetworks() throws {
        // Currently only our French merchant is eligible for card brand choice
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        settings.preferredNetworksEnabled = .on
        settings.apmsEnabled = .off
        settings.supportedPaymentMethods = "card"

        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()

        // We should have selected Visa due to preferreedNetworks configuration API
        let cardBrandChoiceVisa = app.buttons["Visa"]
        let cardBrandChoiceCB = app.buttons["Cartes Bancaires"]
        // Card brand choice textfield/dropdown should not be visible
        XCTAssertFalse(cardBrandChoiceVisa.waitForExistence(timeout: 2))

        let numberField = app.textFields["Card number"]
        numberField.tap()
        // Enter 8 digits to start fetching card brand
        numberField.typeText("49730197")

        // Card brand choice selector should be enabled
        XCTAssertTrue(cardBrandChoiceVisa.waitForExistence(timeout: 5))
        // We should have selected Visa due to preferreedNetworks configuration API
        XCTAssertTrue(cardBrandChoiceVisa.isSelected)
        XCTAssertFalse(cardBrandChoiceCB.isSelected)

        // Clear card text field, should reset selected card brand
        numberField.tap()
        numberField.clearText()

        // We should reset to showing unknown in the textfield for card brand
        XCTAssertFalse(cardBrandChoiceVisa.waitForExistence(timeout: 2))

        // Type full card number to start fetching card brands again
        numberField.forceTapWhenHittableInTestCase(self)
        app.typeText("4000002500001001")
        app.textFields["expiration date"].waitForExistenceAndTap(timeout: 5.0)
        app.typeText("1228") // Expiry
        app.typeText("123") // CVC
        app.typeText("12345") // Postal

        // Card brand choice selector should be enabled and we should auto select Visa
        XCTAssertTrue(cardBrandChoiceVisa.waitForExistence(timeout: 5))
        XCTAssertTrue(cardBrandChoiceVisa.isSelected)
        XCTAssertFalse(cardBrandChoiceCB.isSelected)

        // Finish checkout
        app.buttons["Pay €50.99"].tap()
        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    func testCardBrandChoiceSavedCard() {
        // Currently only our French merchant is eligible for card brand choice
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        settings.apmsEnabled = .off
        settings.supportedPaymentMethods = "card"
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap(timeout: 5)
        let numberField = app.textFields["Card number"]
        let cardBrandChoiceCB = app.buttons["Cartes Bancaires"]
        let cardBrandChoiceVisa = app.buttons["Visa"]

        // Type full card number to start fetching card brands again
        numberField.forceTapWhenHittableInTestCase(self)
        app.typeText("4000002500001001")
        app.textFields["expiration date"].waitForExistenceAndTap(timeout: 5.0)
        app.typeText("1228") // Expiry
        app.typeText("123") // CVC
        app.typeText("12345") // Postal

        // Card brand choice selector should be enabled
        XCTAssertTrue(cardBrandChoiceCB.waitForExistence(timeout: 5))
        cardBrandChoiceCB.tap()

        // We should have selected cartes bancaires
        XCTAssertTrue(cardBrandChoiceCB.isSelected)
        XCTAssertFalse(cardBrandChoiceVisa.isSelected)

        // toggle save this card on
        let saveThisCardToggle = app.switches["Save payment details to Example, Inc. for future purchases"]
        saveThisCardToggle.tap()
        XCTAssertTrue(saveThisCardToggle.isSelected)

        // Finish checkout
        app.buttons["Pay €50.99"].tap()
        let successText = app.staticTexts["Success!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap(timeout: 5)
        // Saved card should show the cartes bancaires logo
        XCTAssertTrue(app.staticTexts["•••• 1001"].waitForExistence(timeout: 5.0))
        XCTAssertTrue(app.images["carousel_card_cartes_bancaires"].waitForExistence(timeout: 5))

        let editButton = app.staticTexts["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 60.0))
        editButton.tap()

        // Saved card should show the edit icon since it is co-branded
        XCTAssertTrue(app.buttons["CircularButton.Edit"].waitForExistenceAndTap(timeout: 5))

        // Tapping the selected card brand again should not deselect it
        XCTAssertTrue(cardBrandChoiceCB.isSelected)
        cardBrandChoiceCB.tap()
        XCTAssertTrue(cardBrandChoiceCB.isSelected)

        // Update this card
        XCTAssertFalse(cardBrandChoiceVisa.isSelected)
        cardBrandChoiceVisa.tap()
        XCTAssertTrue(cardBrandChoiceVisa.isSelected)
        app.buttons["Save"].waitForExistenceAndTap(timeout: 5)

        // We should have updated to Visa
        XCTAssertTrue(app.images["carousel_card_visa"].waitForExistence(timeout: 5))

        // Update this card again
        XCTAssertTrue(app.buttons["CircularButton.Edit"].waitForExistenceAndTap(timeout: 5))
        XCTAssertTrue(app.buttons["Cartes Bancaires"].waitForExistenceAndTap(timeout: 5))
        app.buttons["Save"].waitForExistenceAndTap(timeout: 5)

        // We should have updated to Cartes Bancaires
        XCTAssertTrue(app.images["carousel_card_cartes_bancaires"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()

        // Pay with this card
        app.buttons["Pay €50.99"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))

        // Reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap(timeout: 5)
        // Saved card should show the cartes bancaires logo
        XCTAssertTrue(app.staticTexts["•••• 1001"].waitForExistence(timeout: 5.0))
        XCTAssertTrue(app.images["carousel_card_cartes_bancaires"].waitForExistence(timeout: 5))

        // Remove this card
        XCTAssertTrue(app.staticTexts["Edit"].waitForExistenceAndTap(timeout: 60.0))
        XCTAssertTrue(app.buttons["CircularButton.Edit"].waitForExistenceAndTap(timeout: 5))
        XCTAssertTrue(app.buttons["Remove"].waitForExistenceAndTap(timeout: 5))
        let confirmRemoval = app.alerts.buttons["Remove"]
        XCTAssertTrue(confirmRemoval.waitForExistence(timeout: 5))
        confirmRemoval.tap()

        // Card should be removed
        XCTAssertFalse(app.staticTexts["•••• 1001"].waitForExistence(timeout: 5.0))
    }

    func testCardBrandChoiceUpdateAndRemove() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.merchantCountryCode = .FR
        settings.currency = .eur
        settings.customerMode = .returning
        settings.layout = .horizontal
        settings.apmsEnabled = .off
        settings.supportedPaymentMethods = "card"

        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        app.buttons["Edit"].waitForExistenceAndTap()

        XCTAssertEqual(app.images.matching(identifier: "carousel_card_cartes_bancaires").count, 1)
        XCTAssertEqual(app.images.matching(identifier: "carousel_card_visa").count, 1)

        XCTAssertEqual(app.buttons.matching(identifier: "CircularButton.Edit").count, 2)

        app.buttons.matching(identifier: "CircularButton.Edit").firstMatch.waitForExistenceAndTap()
        app.buttons["Visa"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Visa"].isSelected)
        app.buttons["Save"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.images.matching(identifier: "carousel_card_visa").count, 2)

        app.buttons.matching(identifier: "CircularButton.Edit").element(boundBy: 1).waitForExistenceAndTap()
        app.buttons["Remove"].waitForExistenceAndTap()
        app.alerts.buttons["Remove"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.images.matching(identifier: "carousel_card_visa").count, 1)
        app.buttons["Done"].waitForExistenceAndTap()
    }

    func testCustomPaymentMethod() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.merchantCountryCode = .US
        settings.currency = .usd
        settings.customPaymentMethods = .on
        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].tap()

        tapPaymentMethod("BufoPay (test)")

        app.buttons["Pay $50.99"].tap()
        app.alerts.buttons["Confirm"].waitForExistenceAndTap()

        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10))
    }
}
