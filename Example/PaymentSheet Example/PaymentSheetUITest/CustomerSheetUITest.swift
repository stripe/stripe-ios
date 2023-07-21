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

    func testAddPaymentMethod_setupIntent_reInitAdddViewController() throws {
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

        let closeButton = app.buttons["Close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 60.0))
        closeButton.tap()

        dismissAlertView(alertBody: "Success: payment method not set, canceled", alertTitle: "Complete", buttonToTap: "OK")

        let selectButtonFinal = app.staticTexts["None"]
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

        let closeButton = app.buttons["Close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 60.0))
        closeButton.tap()

        dismissAlertView(alertBody: "Success: payment method not set, canceled", alertTitle: "Complete", buttonToTap: "OK")

        let selectButtonFinal = app.staticTexts["None"]
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

        let closeButton = app.buttons["Close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 60.0))
        closeButton.tap()

        dismissAlertView(alertBody: "Success: payment method not set, canceled", alertTitle: "Complete", buttonToTap: "OK")

        let selectButtonFinal = app.staticTexts["None"]
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

        let closeButton = app.buttons["Close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 60.0))
        closeButton.tap()

        dismissAlertView(alertBody: "Success: payment method not set, canceled", alertTitle: "Complete", buttonToTap: "OK")

        let selectButtonFinal = app.staticTexts["None"]
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

    func testNoPrevPM_AddPM_canceled_noApplePay() throws {
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

        dismissAlertView(alertBody: "Success: payment method not set, canceled", alertTitle: "Complete", buttonToTap: "OK")
    }

    func testNoPrevPM_AddPM_canceled_ApplePay() throws {
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

        dismissAlertView(alertBody: "Success: payment method not set, canceled", alertTitle: "Complete", buttonToTap: "OK")
    }

    func testPrevPM_AddPM_canceled_noApplePay() throws {
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

        try! fillCardData(app, postalEnabled: true)
        app.buttons["Save"].tap()

        let confirmButton = app.buttons["Confirm"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 60.0))
        // Don't tap!

        let closeButton = app.buttons["Close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 60.0))
        closeButton.tap()

        dismissAlertView(alertBody: "Success: ••••4242, canceled", alertTitle: "Complete", buttonToTap: "OK")
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

        app.staticTexts["Apple Pay"].tap()
        let confirmButton = app.buttons["Confirm"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 60.0))
        // Don't tap!

        let closeButton = app.buttons["Close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 60.0))
        closeButton.tap()

        dismissAlertView(alertBody: "Success: ••••4242, canceled", alertTitle: "Complete", buttonToTap: "OK")
    }
    // TODO: Uncomment when enabling USBankAccount
/*
    func testCustomerSheetStandard_applePayOff_addUSBankAccount() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .off
        settings.paymentMethodTypes = .card_usbank
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
*/
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
