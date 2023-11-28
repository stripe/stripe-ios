//
//  CustomerSheetUITest.swift
//  PaymentSheetUITest
//

import Foundation
import XCTest

class CustomerSheetUITest: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchEnvironment = ["UITesting": "true",
                                 "USE_PRODUCTION_FINANCIAL_CONNECTIONS_SDK": "true",
        ]
        app.launch()
    }

    func testCustomerSheetStandard_applePayOff_addCard() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .off
        loadPlayground(
            app,
            settings
        )

        let selectButton = app.staticTexts["None"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 60.0))
        selectButton.tap()
        try! fillCardData(app, postalEnabled: true)
        app.buttons["Save"].tap()

        let confirmButton = app.buttons["Confirm"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 60.0))
        confirmButton.tap()

        let paymentMethodButton = app.staticTexts["Success: ••••4242, selected"]  // The card should be saved now
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 60.0))
    }

    func testCustomerSheetStandard_applePayOn_addCard() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .on
        loadPlayground(
            app,
            settings
        )

        let selectButton = app.staticTexts["None"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 60.0))
        selectButton.tap()

        app.staticTexts["+ Add"].tap()

        try! fillCardData(app, postalEnabled: true)
        app.buttons["Save"].tap()

        let confirmButton = app.buttons["Confirm"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 60.0))
        confirmButton.tap()

        let paymentMethodButton = app.staticTexts["Success: ••••4242, selected"]  // The card should be saved now
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 60.0))
    }

    func testCustomerSheetStandard_applePayOn_selectApplePay() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .on
        loadPlayground(
            app,
            settings
        )

        let selectButton = app.staticTexts["None"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 60.0))
        selectButton.tap()

        app.collectionViews.staticTexts["Apple Pay"].tap()

        let confirmButton = app.buttons["Confirm"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 60.0))
        confirmButton.tap()

        let paymentMethodButton = app.staticTexts["Success: Apple Pay, selected"]  // The card should be saved now
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 60.0))
    }
    func testAddPaymentMethod_RemoveBeforeConfirming() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .on
        loadPlayground(
            app,
            settings
        )
        let selectButton = app.staticTexts["None"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 60.0))
        selectButton.tap()

        app.staticTexts["+ Add"].tap()

        try! fillCardData(app, postalEnabled: true)
        app.buttons["Save"].tap()

        let cardPresence_beforeRemoval = app.staticTexts["••••4242"]
        XCTAssertTrue(cardPresence_beforeRemoval.waitForExistence(timeout: 60.0))

        let editButton = app.staticTexts["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 60.0))
        editButton.tap()

        removeFirstPaymentMethodInList()

        let doneButton = app.staticTexts["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 60.0))
        doneButton.tap()

        let cardPresence_afterRemoval = app.staticTexts["••••4242"]
        XCTAssertFalse(cardPresence_afterRemoval.exists)

        let closeButton = app.buttons["Close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 60.0))
        closeButton.tap()

        dismissAlertView(alertBody: "Success: payment method not set, canceled", alertTitle: "Complete", buttonToTap: "OK")

        let selectButtonFinal = app.staticTexts["None"]
        XCTAssertTrue(selectButtonFinal.waitForExistence(timeout: 60.0))
    }

    func testAddPaymentMethod_setupIntent_reInitAddViewController() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .on
        settings.paymentMethodMode = .setupIntent
        loadPlayground(
            app,
            settings
        )
        let selectButton = app.staticTexts["None"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 60.0))
        selectButton.tap()

        app.staticTexts["+ Add"].tap()

        try! fillCardData(app, postalEnabled: true)
        app.buttons["Save"].tap()

        let cardPresence = app.staticTexts["••••4242"]
        XCTAssertTrue(cardPresence.waitForExistence(timeout: 60.0))

        app.staticTexts["+ Add"].tap()

        if let cardInformation = app.textFields["Card number"].value as? String {
            XCTAssert(cardInformation.isEmpty)
        } else {
            XCTFail("unable to get card number field")
        }

        let backButton = app.buttons["Back"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 60.0))
        backButton.tap()

        let closeButton = app.buttons["Confirm"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 60.0))
        closeButton.tap()

        dismissAlertView(alertBody: "Success: ••••4242, selected", alertTitle: "Complete", buttonToTap: "OK")

        let selectButtonFinal = app.staticTexts["••••4242"]
        XCTAssertTrue(selectButtonFinal.waitForExistence(timeout: 60.0))
    }
    func testAddTwoPaymentMethod_setupIntent() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .on
        settings.paymentMethodMode = .setupIntent
        loadPlayground(
            app,
            settings
        )
        let selectButton = app.staticTexts["None"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 60.0))
        selectButton.tap()

        app.staticTexts["+ Add"].tap()

        try! fillCardData(app, postalEnabled: true)
        app.buttons["Save"].tap()

        let cardPresence = app.staticTexts["••••4242"]
        XCTAssertTrue(cardPresence.waitForExistence(timeout: 60.0))

        app.staticTexts["+ Add"].tap()

        try! fillCardData(app, cardNumber: "5555555555554444", postalEnabled: true)
        app.buttons["Save"].tap()

        let cardPresence4444 = app.staticTexts["••••4444"]
        XCTAssertTrue(cardPresence4444.waitForExistence(timeout: 60.0))

        let cardPresence4242 = app.staticTexts["••••4242"]
        XCTAssertTrue(cardPresence4242.waitForExistence(timeout: 60.0))

        let closeButton = app.buttons["Confirm"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 60.0))
        closeButton.tap()

        dismissAlertView(alertBody: "Success: ••••4444, selected", alertTitle: "Complete", buttonToTap: "OK")

        let selectButtonFinal = app.staticTexts["••••4444"]
        XCTAssertTrue(selectButtonFinal.waitForExistence(timeout: 60.0))
    }
    func testAddPaymentMethod_createAndAttach_reInitAdddViewController() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .on
        settings.paymentMethodMode = .createAndAttach
        loadPlayground(
            app,
            settings
        )
        let selectButton = app.staticTexts["None"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 60.0))
        selectButton.tap()

        app.staticTexts["+ Add"].tap()

        try! fillCardData(app, postalEnabled: true)
        app.buttons["Save"].tap()

        let cardPresence = app.staticTexts["••••4242"]
        XCTAssertTrue(cardPresence.waitForExistence(timeout: 60.0))

        app.staticTexts["+ Add"].tap()

        if let cardInformation = app.textFields["Card number"].value as? String {
            XCTAssert(cardInformation.isEmpty)
        } else {
            XCTFail("unable to get card number field")
        }

        let backButton = app.buttons["Back"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 60.0))
        backButton.tap()

        let closeButton = app.buttons["Confirm"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 60.0))
        closeButton.tap()

        dismissAlertView(alertBody: "Success: ••••4242, selected", alertTitle: "Complete", buttonToTap: "OK")

        let selectButtonFinal = app.staticTexts["••••4242"]
        XCTAssertTrue(selectButtonFinal.waitForExistence(timeout: 60.0))
    }
    func testAddTwoPaymentMethod_createAndAttach() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .on
        settings.paymentMethodMode = .createAndAttach
        loadPlayground(
            app,
            settings
        )
        let selectButton = app.staticTexts["None"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 60.0))
        selectButton.tap()

        app.staticTexts["+ Add"].tap()

        try! fillCardData(app, postalEnabled: true)
        app.buttons["Save"].tap()

        let cardPresence = app.staticTexts["••••4242"]
        XCTAssertTrue(cardPresence.waitForExistence(timeout: 60.0))

        app.staticTexts["+ Add"].tap()

        try! fillCardData(app, cardNumber: "5555555555554444", postalEnabled: true)
        app.buttons["Save"].tap()

        let cardPresence4444 = app.staticTexts["••••4444"]
        XCTAssertTrue(cardPresence4444.waitForExistence(timeout: 60.0))

        let cardPresence4242 = app.staticTexts["••••4242"]
        XCTAssertTrue(cardPresence4242.waitForExistence(timeout: 60.0))

        let closeButton = app.buttons["Confirm"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 60.0))
        closeButton.tap()

        dismissAlertView(alertBody: "Success: ••••4444, selected", alertTitle: "Complete", buttonToTap: "OK")

        let selectButtonFinal = app.staticTexts["••••4444"]
        XCTAssertTrue(selectButtonFinal.waitForExistence(timeout: 60.0))
    }
    func testAddTwoPaymentMethods_RemoveTwoPaymentMethods() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .on
        loadPlayground(
            app,
            settings
        )

        presentCSAndAddCardFrom(buttonLabel: "None")
        presentCSAndAddCardFrom(buttonLabel: "••••4242")

        let selectButton = app.staticTexts["••••4242"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 60.0))
        selectButton.tap()

        let editButton = app.staticTexts["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 60.0))
        editButton.tap()

        removeFirstPaymentMethodInList()
        removeFirstPaymentMethodInList()

        let doneButton = app.staticTexts["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 60.0))
        doneButton.tap()

        let closeButton = app.buttons["Close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 60.0))
        closeButton.tap()

        dismissAlertView(alertBody: "Success: payment method not set, canceled", alertTitle: "Complete", buttonToTap: "OK")

        let selectButtonFinal = app.staticTexts["None"]
        XCTAssertTrue(selectButtonFinal.waitForExistence(timeout: 60.0))
    }

    func testAddTwoPaymentMethods_RemoveTwoPaymentMethods_noapplepay() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .off
        loadPlayground(
            app,
            settings
        )

        presentCSAndAddCardFrom(buttonLabel: "None", tapAdd: false)
        presentCSAndAddCardFrom(buttonLabel: "••••4242")

        let selectButton = app.staticTexts["••••4242"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 60.0))
        selectButton.tap()

        let editButton = app.staticTexts["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 60.0))
        editButton.tap()

        removeFirstPaymentMethodInList()
        removeFirstPaymentMethodInList()

        let doneButton = app.staticTexts["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 60.0))
        doneButton.tap()

        let closeButton = app.buttons["Close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 60.0))
        closeButton.tap()

        dismissAlertView(alertBody: "Success: payment method not set, canceled", alertTitle: "Complete", buttonToTap: "OK")

        let selectButtonFinal = app.staticTexts["None"]
        XCTAssertTrue(selectButtonFinal.waitForExistence(timeout: 60.0))
    }

    func testNoPrevPM_AddPM_noApplePay_closeInsteadOfConfirming() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .off
        loadPlayground(
            app,
            settings
        )

        let selectButton = app.staticTexts["None"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 60.0))
        selectButton.tap()

        try! fillCardData(app, postalEnabled: true)
        app.buttons["Save"].tap()

        let confirmButton = app.buttons["Confirm"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 60.0))
        // Don't tap confirm!

        let closeButton = app.buttons["Close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 60.0))
        closeButton.tap()

        dismissAlertView(alertBody: "Success: ••••4242, selected", alertTitle: "Complete", buttonToTap: "OK")
    }

    func testNoPrevPM_AddPM_ApplePay_closeInsteadOfConfirming() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .on
        loadPlayground(
            app,
            settings
        )

        let selectButton = app.staticTexts["None"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 60.0))
        selectButton.tap()

        let addButton = app.staticTexts["+ Add"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 60.0))
        addButton.tap()

        try! fillCardData(app, postalEnabled: true)
        app.buttons["Save"].tap()

        let confirmButton = app.buttons["Confirm"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 60.0))
        // Don't tap confirm!

        let closeButton = app.buttons["Close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 60.0))
        closeButton.tap()

        dismissAlertView(alertBody: "Success: ••••4242, selected", alertTitle: "Complete", buttonToTap: "OK")
    }

    func testPrevPM_AddPM_selectedWithoutTapping_noApplePay() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .off
        loadPlayground(
            app,
            settings
        )

        presentCSAndAddCardFrom(buttonLabel: "None", tapAdd: false)
        let selectButton = app.staticTexts["••••4242"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 60.0))
        selectButton.tap()

        app.staticTexts["+ Add"].tap()

        try! fillCardData(app, cardNumber: "5555555555554444", postalEnabled: true)
        app.buttons["Save"].tap()

        let confirmButton = app.buttons["Confirm"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 60.0))
        // Don't tap!

        let closeButton = app.buttons["Close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 60.0))
        closeButton.tap()

        dismissAlertView(alertBody: "Success: ••••4444, selected", alertTitle: "Complete", buttonToTap: "OK")
    }

    func testPrevPM_AddPM_canceled_ApplePay() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .on
        loadPlayground(
            app,
            settings
        )

        presentCSAndAddCardFrom(buttonLabel: "None")
        let selectButton = app.staticTexts["••••4242"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 60.0))
        selectButton.tap()

        app.staticTexts["+ Add"].tap()

        try! fillCardData(app, cardNumber: "5555555555554444", postalEnabled: true)
        app.buttons["Save"].tap()

        app.staticTexts["Apple Pay"].waitForExistenceAndTap()
        let confirmButton = app.buttons["Confirm"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 60.0))
        // Don't tap!

        let closeButton = app.buttons["Close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 60.0))
        closeButton.tap()

        dismissAlertView(alertBody: "Success: ••••4242, canceled", alertTitle: "Complete", buttonToTap: "OK")
    }

    func testCustomerSheetStandard_applePayOff_addUSBankAccount() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .off
        loadPlayground(
            app,
            settings
        )

        let selectButton = app.staticTexts["None"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 60.0))
        selectButton.tap()

        let usBankAccountPMSelectorButton = app.staticTexts["US Bank Account"]
        XCTAssertTrue(usBankAccountPMSelectorButton.waitForExistence(timeout: 60.0))
        usBankAccountPMSelectorButton.tap()

        try! fillUSBankData(app)

        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 60.0))
        continueButton.tap()

        // Go through connections flow
        app.buttons["Agree and continue"].tap()
        app.staticTexts["Test Institution"].forceTapElement()
        app.staticTexts["Success"].waitForExistenceAndTap(timeout: 10)
        app.buttons["Link account"].tap()
        XCTAssertTrue(app.staticTexts["Success"].waitForExistence(timeout: 10))
        app.buttons.matching(identifier: "Done").allElementsBoundByIndex.last?.tap()

        let testBankLinkedBankAccount = app.staticTexts["StripeBank"]
        XCTAssertTrue(testBankLinkedBankAccount.waitForExistence(timeout: 60.0))

        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 60.0))
        saveButton.tap()

        let confirmButton = app.buttons["Confirm"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 60.0))
        confirmButton.tap()

        dismissAlertView(alertBody: "Success: ••••6789, selected", alertTitle: "Complete", buttonToTap: "OK")
    }
    func testCustomerSheetStandard_applePayOff_addUSBankAccount_defaultBillingOnCollectNone() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .off
        settings.defaultBillingAddress = .on
        settings.attachDefaults = .on
        settings.collectAddress = .never
        settings.collectEmail = .never
        settings.collectName = .never
        settings.collectPhone = .never
        loadPlayground(
            app,
            settings
        )

        let selectButton = app.staticTexts["None"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 60.0))
        selectButton.tap()

        let usBankAccountPMSelectorButton = app.staticTexts["US Bank Account"]
        XCTAssertTrue(usBankAccountPMSelectorButton.waitForExistence(timeout: 60.0))
        usBankAccountPMSelectorButton.tap()

        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 60.0))
        continueButton.tap()

        // Go through connections flow
        app.buttons["Agree and continue"].tap()
        app.staticTexts["Test Institution"].forceTapElement()
        app.staticTexts["Success"].waitForExistenceAndTap(timeout: 10)
        app.buttons["Link account"].tap()
        XCTAssertTrue(app.staticTexts["Success"].waitForExistence(timeout: 10))
        app.buttons.matching(identifier: "Done").allElementsBoundByIndex.last?.tap()

        let testBankLinkedBankAccount = app.staticTexts["StripeBank"]
        XCTAssertTrue(testBankLinkedBankAccount.waitForExistence(timeout: 60.0))

        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 60.0))
        saveButton.tap()

        let confirmButton = app.buttons["Confirm"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 60.0))
        confirmButton.tap()

        dismissAlertView(alertBody: "Success: ••••6789, selected", alertTitle: "Complete", buttonToTap: "OK")
    }
    func testCustomerSheetStandard_applePayOff_addUSBankAccount_MicroDeposit() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .off

        loadPlayground(
            app,
            settings
        )

        let selectButton = app.staticTexts["None"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 60.0))
        selectButton.tap()

        let usBankAccountPMSelectorButton = app.staticTexts["US Bank Account"]
        XCTAssertTrue(usBankAccountPMSelectorButton.waitForExistence(timeout: 60.0))
        usBankAccountPMSelectorButton.tap()

        try! fillUSBankData(app)

        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 60.0))
        continueButton.tap()

        // Go through connections flow
        app.links["Manually verify instead"].tap()
        try! fillUSBankData_microdeposits(app)

        let continueManualEntry = app.buttons["manual_entry_continue_button"]
        XCTAssertTrue(continueManualEntry.waitForExistence(timeout: 60.0))
        continueManualEntry.tap()

        let doneManualEntry = app.buttons["manual_entry_success_done_button"]
        XCTAssertTrue(doneManualEntry.waitForExistence(timeout: 60.0))
        doneManualEntry.tap()

        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 60.0))
        saveButton.tap()

        dismissAlertView(alertBody: "Success: payment method not set, canceled", alertTitle: "Complete", buttonToTap: "OK")
    }
    func testCustomerSheetSwiftUI() throws {
        app.launch()

        app.staticTexts["CustomerSheet (SwiftUI)"].tap()

        app.buttons["Using Returning Customer (Tap to Switch)"].tap()
        let newCustomerText = app.buttons["Using New Customer (Tap to Switch)"]
        XCTAssertTrue(newCustomerText.waitForExistence(timeout: 10.0))

        let button = app.buttons["Present Customer Sheet"]
        XCTAssertTrue(button.waitForExistence(timeout: 60.0))
        button.forceTapElement()

        app.staticTexts["+ Add"].tap()

        try! fillCardData(app, postalEnabled: true)
        app.buttons["Save"].tap()

        let cardPresence = app.staticTexts["••••4242"]
        XCTAssertTrue(cardPresence.waitForExistence(timeout: 60.0))

        let confirmButton = app.buttons["Confirm"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 60.0))
        confirmButton.tap()

        let last4Label = app.staticTexts["••••4242"]
        XCTAssertTrue(last4Label.waitForExistence(timeout: 10.0))
        let last4Selectedlabel = app.staticTexts["(Selected)"]
        XCTAssertTrue(last4Selectedlabel.waitForExistence(timeout: 10.0))
    }

    // MARK: - Card Brand Choice tests

    func testCardBrandChoiceSavedCard() {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.merchantCountryCode = .FR
        loadPlayground(
            app,
            settings
        )

        let button = app.buttons["Payment method"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.forceTapElement()

        app.staticTexts["+ Add"].tap()

        let numberField = app.textFields["Card number"]
        let cardBrandChoiceDropdown = app.pickerWheels.firstMatch

        // Type full card number to start fetching card brands again
        numberField.forceTapWhenHittableInTestCase(self)
        app.typeText("4000002500001001")
        app.textFields["expiration date"].waitForExistenceAndTap(timeout: 5)
        app.typeText("1228") // Expiry
        app.typeText("123") // CVC
        app.toolbars.buttons["Done"].tap() // Country picker toolbar's "Done" button
        app.typeText("12345") // Postal

        // Card brand choice drop down should be enabled
        XCTAssertTrue(app.textFields["Select card brand (optional)"].waitForExistenceAndTap(timeout: 5))
        XCTAssertTrue(cardBrandChoiceDropdown.waitForExistence(timeout: 5))
        cardBrandChoiceDropdown.selectNextOption()
        app.toolbars.buttons["Done"].tap()

        // We should have selected cartes bancaires
        XCTAssertTrue(app.textFields["Cartes Bancaires"].waitForExistence(timeout: 5))

        // Finish saving card
        app.buttons["Save"].waitForExistenceAndTap(timeout: 5)
        app.buttons["Confirm"].waitForExistenceAndTap(timeout: 5)
        let completeText = app.staticTexts["Complete"]
        XCTAssertTrue(completeText.waitForExistence(timeout: 5))

        // Reload w/ same customer
        app.buttons["Reload"].tap()
        app.buttons["Payment method"].waitForExistenceAndTap(timeout: 5)
        // Saved card should show the cartes bancaires logo
        XCTAssertTrue(app.staticTexts["••••1001"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.images["carousel_card_cartes_bancaires"].waitForExistence(timeout: 5))

        let editButton = app.staticTexts["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 5))
        editButton.tap()

        // Saved card should show the edit icon since it is co-branded
        XCTAssertTrue(app.buttons["CircularButton.Edit"].waitForExistenceAndTap(timeout: 5))

        // Update this card
        XCTAssertTrue(app.textFields["Cartes Bancaires"].waitForExistenceAndTap(timeout: 5))
        XCTAssertTrue(app.pickerWheels.firstMatch.waitForExistence(timeout: 5))
        app.pickerWheels.firstMatch.swipeUp()
        app.toolbars.buttons["Done"].tap()
        app.buttons["Update card"].waitForExistenceAndTap(timeout: 5)

        // We should have updated to Visa
        XCTAssertTrue(app.images["carousel_card_visa"].waitForExistence(timeout: 5))

        // Remove this card
        XCTAssertTrue(app.buttons["CircularButton.Edit"].waitForExistenceAndTap(timeout: 5))
        XCTAssertTrue(app.buttons["Remove card"].waitForExistenceAndTap(timeout: 5))
        let confirmRemoval = app.alerts.buttons["Remove"]
        XCTAssertTrue(confirmRemoval.waitForExistence(timeout: 5))
        confirmRemoval.tap()

        // Verify card is removed
        app.buttons["Done"].waitForExistenceAndTap(timeout: 5)
        app.buttons["Close"].waitForExistenceAndTap(timeout: 5)
        app.buttons["Reload"].waitForExistenceAndTap(timeout: 5)
        app.buttons["Payment method"].waitForExistenceAndTap(timeout: 5)
        // Card is no longer saved
        XCTAssertFalse(app.staticTexts["••••1001"].waitForExistence(timeout: 5))
    }

    func testCardBrandChoiceWithPreferredNetworks() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.merchantCountryCode = .FR
        settings.preferredNetworksEnabled = .on
        loadPlayground(
            app,
            settings
        )

        let button = app.buttons["Payment method"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.forceTapElement()

        app.staticTexts["+ Add"].waitForExistenceAndTap(timeout: 5)

        // We should have selected Visa due to preferreedNetworks configuration API
        let cardBrandTextField = app.textFields["Visa"]
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
        cardBrandChoiceDropdown.swipeDown()
        app.toolbars.buttons["Cancel"].tap()

        // We should have selected Visa due to preferreedNetworks configuration API
        XCTAssertTrue(app.textFields["Visa"].waitForExistence(timeout: 2))

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
        app.toolbars.buttons["Done"].tap() // Country picker toolbar's "Done" button
        app.typeText("12345") // Postal

        // Card brand choice drop down should be enabled and we should auto select Visa
        XCTAssertTrue(app.textFields["Visa"].waitForExistence(timeout: 5))

        // Finish saving card
        app.buttons["Save"].tap()
        app.buttons["Confirm"].waitForExistenceAndTap(timeout: 5)
        let successText = app.staticTexts["Complete"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }

    // MARK: - Helpers

    func presentCSAndAddCardFrom(buttonLabel: String, tapAdd: Bool = true) {
        let selectButton = app.staticTexts[buttonLabel]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 60.0))
        selectButton.tap()

        if tapAdd {
            app.staticTexts["+ Add"].tap()
        }

        try! fillCardData(app, postalEnabled: true)
        app.buttons["Save"].tap()

        let confirmButton = app.buttons["Confirm"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 60.0))
        confirmButton.tap()

        dismissAlertView(alertBody: "Success: ••••4242, selected", alertTitle: "Complete", buttonToTap: "OK")
    }

    func removeFirstPaymentMethodInList() {
        let removeButton1 = app.buttons["Remove"].firstMatch
        removeButton1.tap()
        dismissAlertView(alertBody: "Remove Visa ending in 4242", alertTitle: "Remove Card", buttonToTap: "Remove")
    }

    func dismissAlertView(alertBody: String, alertTitle: String, buttonToTap: String) {
        let alertText = app.staticTexts[alertBody]
        XCTAssertTrue(alertText.waitForExistence(timeout: 60.0))

        let alert = app.alerts[alertTitle]
        alert.buttons[buttonToTap].tap()
    }
}
