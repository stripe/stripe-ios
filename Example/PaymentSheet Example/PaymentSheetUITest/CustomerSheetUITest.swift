//
//  CustomerSheetUITest.swift
//  PaymentSheetUITest
//

import Foundation
import XCTest

class CustomerSheetUITest: XCTestCase {
    var app: XCUIApplication!
    let timeout: TimeInterval = 10

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

        let selectButton = app.staticTexts["None"].firstMatch
        XCTAssertTrue(selectButton.waitForExistenceIfNeeded(timeout: timeout))
        selectButton.tap()
        try! fillCardData(app, postalEnabled: true)
        app.buttons["Save"].firstMatch.tap()

        let confirmButton = app.buttons["Confirm"].firstMatch
        XCTAssertTrue(confirmButton.waitForExistenceIfNeeded(timeout: timeout))
        confirmButton.tap()

        let paymentMethodButton = app.staticTexts["Success: ••••4242, selected"].firstMatch  // The card should be saved now
        XCTAssertTrue(paymentMethodButton.waitForExistenceIfNeeded(timeout: timeout))
    }

    func testCustomerSheetStandard_applePayOn_addCard_ensureCanDismissOnUnsupportedPaymentMethod() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .on
        loadPlayground(
            app,
            settings
        )

        let selectButton = app.staticTexts["None"].firstMatch
        XCTAssertTrue(selectButton.waitForExistenceIfNeeded(timeout: timeout))
        selectButton.tap()

        app.staticTexts["+ Add"].firstMatch.waitForExistenceAndTap(timeout: timeout)

        try! fillCardData(app, postalEnabled: true)
        app.buttons["Save"].firstMatch.tap()

        let confirmButton = app.buttons["Confirm"].firstMatch
        XCTAssertTrue(confirmButton.waitForExistenceIfNeeded(timeout: timeout))
        confirmButton.tap()

        let paymentMethodButton = app.staticTexts["Success: ••••4242, selected"].firstMatch  // The card should be saved now
        XCTAssertTrue(paymentMethodButton.waitForExistenceIfNeeded(timeout: timeout))

        dismissAlertView(alertBody: "Success: ••••4242, selected", alertTitle: "Complete", buttonToTap: "OK")

        // Piggy back on the original test to ensure we can dismiss the sheet if we have an unsupported payment method
        app.buttons["SetPMLink"].firstMatch.tap()
        app.staticTexts["None"].firstMatch.waitForExistenceAndTap()
        app.buttons["Close"].firstMatch.waitForExistenceAndTap()

        dismissAlertView(alertBody: "Success: payment method not set, canceled", alertTitle: "Complete", buttonToTap: "OK")
    }

    func testCustomerSheetStandard_applePayOn_selectApplePay() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .on
        loadPlayground(
            app,
            settings
        )

        app.staticTexts["None"].firstMatch.waitForExistenceAndTap(timeout: timeout)

        app.collectionViews.staticTexts["Apple Pay"].firstMatch.tap()

        let confirmButton = app.buttons["Confirm"].firstMatch
        XCTAssertTrue(confirmButton.waitForExistenceIfNeeded(timeout: timeout))
        confirmButton.tap()

        let paymentMethodButton = app.staticTexts["Success: Apple Pay, selected"].firstMatch  // The card should be saved now
        XCTAssertTrue(paymentMethodButton.waitForExistenceIfNeeded(timeout: timeout))
    }

    func testAddPaymentMethod_RemoveBeforeConfirming() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .on
        loadPlayground(
            app,
            settings
        )

        app.staticTexts["None"].firstMatch.waitForExistenceAndTap(timeout: timeout)
        app.staticTexts["+ Add"].firstMatch.waitForExistenceAndTap(timeout: timeout)

        try! fillCardData(app, postalEnabled: true)
        app.buttons["Save"].firstMatch.tap()

        let cardPresence_beforeRemoval = app.staticTexts["••••4242"].firstMatch
        XCTAssertTrue(cardPresence_beforeRemoval.waitForExistenceIfNeeded(timeout: 60.0))

        let editButton = app.staticTexts["Edit"].firstMatch
        XCTAssertTrue(editButton.waitForExistenceIfNeeded(timeout: 60.0))
        editButton.tap()

        removeFirstPaymentMethodInList()

        let cardPresence_afterRemoval = app.staticTexts["••••4242"].firstMatch
        waitToDisappear(cardPresence_afterRemoval)

        let closeButton = app.buttons["Close"].firstMatch
        XCTAssertTrue(closeButton.waitForExistenceIfNeeded(timeout: 60.0))
        closeButton.tap()

        dismissAlertView(alertBody: "Success: payment method not set, canceled", alertTitle: "Complete", buttonToTap: "OK")

        let selectButtonFinal = app.staticTexts["None"].firstMatch
        XCTAssertTrue(selectButtonFinal.waitForExistenceIfNeeded(timeout: timeout))
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

        app.staticTexts["None"].firstMatch.waitForExistenceAndTap(timeout: timeout)
        app.staticTexts["+ Add"].firstMatch.waitForExistenceAndTap(timeout: timeout)

        try! fillCardData(app, postalEnabled: true)
        app.buttons["Save"].firstMatch.tap()

        let cardPresence = app.staticTexts["••••4242"].firstMatch
        XCTAssertTrue(cardPresence.waitForExistenceIfNeeded(timeout: timeout))

        app.staticTexts["+ Add"].firstMatch.waitForExistenceAndTap(timeout: timeout)

        if let cardInformation = app.textFields["Card number"].firstMatch.value as? String {
            XCTAssert(cardInformation.isEmpty)
        } else {
            XCTFail("unable to get card number field")
        }

        let backButton = app.buttons["Back"].firstMatch
        XCTAssertTrue(backButton.waitForExistenceIfNeeded(timeout: timeout))
        backButton.tap()

        let closeButton = app.buttons["Confirm"].firstMatch
        XCTAssertTrue(closeButton.waitForExistenceIfNeeded(timeout: timeout))
        closeButton.tap()

        dismissAlertView(alertBody: "Success: ••••4242, selected", alertTitle: "Complete", buttonToTap: "OK")

        let selectButtonFinal = app.staticTexts["••••4242"].firstMatch
        XCTAssertTrue(selectButtonFinal.waitForExistenceIfNeeded(timeout: timeout))
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

        app.staticTexts["None"].firstMatch.waitForExistenceAndTap(timeout: timeout)
        app.staticTexts["+ Add"].firstMatch.waitForExistenceAndTap(timeout: timeout)

        try! fillCardData(app, postalEnabled: true)
        app.buttons["Save"].firstMatch.tap()

        let cardPresence = app.staticTexts["••••4242"].firstMatch
        XCTAssertTrue(cardPresence.waitForExistenceIfNeeded(timeout: timeout))

        app.staticTexts["+ Add"].firstMatch.waitForExistenceAndTap(timeout: timeout)

        try! fillCardData(app, cardNumber: "5555555555554444", postalEnabled: true)
        app.buttons["Save"].firstMatch.tap()

        let cardPresence4444 = app.staticTexts["••••4444"].firstMatch
        XCTAssertTrue(cardPresence4444.waitForExistenceIfNeeded(timeout: timeout))

        let cardPresence4242 = app.staticTexts["••••4242"].firstMatch
        XCTAssertTrue(cardPresence4242.waitForExistenceIfNeeded(timeout: timeout))

        let closeButton = app.buttons["Confirm"].firstMatch
        XCTAssertTrue(closeButton.waitForExistenceIfNeeded(timeout: timeout))
        closeButton.tap()

        dismissAlertView(alertBody: "Success: ••••4444, selected", alertTitle: "Complete", buttonToTap: "OK")

        let selectButtonFinal = app.staticTexts["••••4444"].firstMatch
        XCTAssertTrue(selectButtonFinal.waitForExistenceIfNeeded(timeout: timeout))
    }
    func testAddPaymentMethod_createAndAttach_reInitAddViewController() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .on
        settings.paymentMethodMode = .createAndAttach
        loadPlayground(
            app,
            settings
        )

        app.staticTexts["None"].firstMatch.waitForExistenceAndTap(timeout: timeout)
        app.staticTexts["+ Add"].firstMatch.waitForExistenceAndTap(timeout: timeout)

        try! fillCardData(app, postalEnabled: true)
        app.buttons["Save"].firstMatch.tap()

        let cardPresence = app.staticTexts["••••4242"].firstMatch
        XCTAssertTrue(cardPresence.waitForExistenceIfNeeded(timeout: timeout))

        app.staticTexts["+ Add"].firstMatch.waitForExistenceAndTap(timeout: timeout)

        if let cardInformation = app.textFields["Card number"].firstMatch.value as? String {
            XCTAssert(cardInformation.isEmpty)
        } else {
            XCTFail("unable to get card number field")
        }

        let backButton = app.buttons["Back"].firstMatch
        XCTAssertTrue(backButton.waitForExistenceIfNeeded(timeout: timeout))
        backButton.tap()

        let closeButton = app.buttons["Confirm"].firstMatch
        XCTAssertTrue(closeButton.waitForExistenceIfNeeded(timeout: timeout))
        closeButton.tap()

        dismissAlertView(alertBody: "Success: ••••4242, selected", alertTitle: "Complete", buttonToTap: "OK")

        let selectButtonFinal = app.staticTexts["••••4242"].firstMatch
        XCTAssertTrue(selectButtonFinal.waitForExistenceIfNeeded(timeout: timeout))
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

        app.staticTexts["None"].firstMatch.waitForExistenceAndTap(timeout: timeout)
        app.staticTexts["+ Add"].firstMatch.waitForExistenceAndTap(timeout: timeout)

        try! fillCardData(app, postalEnabled: true)
        app.buttons["Save"].firstMatch.tap()

        let cardPresence = app.staticTexts["••••4242"].firstMatch
        XCTAssertTrue(cardPresence.waitForExistenceIfNeeded(timeout: timeout))

        app.staticTexts["+ Add"].firstMatch.waitForExistenceAndTap(timeout: timeout)

        try! fillCardData(app, cardNumber: "5555555555554444", postalEnabled: true)
        app.buttons["Save"].firstMatch.tap()

        let cardPresence4444 = app.staticTexts["••••4444"].firstMatch
        XCTAssertTrue(cardPresence4444.waitForExistenceIfNeeded(timeout: timeout))

        let cardPresence4242 = app.staticTexts["••••4242"].firstMatch
        XCTAssertTrue(cardPresence4242.waitForExistenceIfNeeded(timeout: timeout))

        let closeButton = app.buttons["Confirm"].firstMatch
        XCTAssertTrue(closeButton.waitForExistenceIfNeeded(timeout: timeout))
        closeButton.tap()

        dismissAlertView(alertBody: "Success: ••••4444, selected", alertTitle: "Complete", buttonToTap: "OK")

        let selectButtonFinal = app.staticTexts["••••4444"].firstMatch
        XCTAssertTrue(selectButtonFinal.waitForExistenceIfNeeded(timeout: timeout))
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
        presentCSAndAddCardFrom(buttonLabel: "••••4242", cardNumber: "5555555555554444")

        app.staticTexts["••••4444"].firstMatch.waitForExistenceAndTap(timeout: timeout)

        let editButton = app.staticTexts["Edit"].firstMatch
        XCTAssertTrue(editButton.waitForExistenceIfNeeded(timeout: timeout))
        editButton.tap()

        removeFirstPaymentMethodInList(alertBody: "Mastercard •••• 4444")
        // ••••4444 is rendered as the PM to remove, as well as the status on the playground
        // Check that it is removed by waiting for there only be one instance
        let elementLabel = "••••4444"
        let elementQuery = app.staticTexts.matching(NSPredicate(format: "label == %@", elementLabel))
        waitForNItemsExistence(elementQuery, count: 1)

        removeFirstPaymentMethodInList(alertBody: "Visa •••• 4242")
        let visa = app.staticTexts["••••4242"].firstMatch
        waitToDisappear(visa)

        let closeButton = app.buttons["Close"].firstMatch
        XCTAssertTrue(closeButton.waitForExistenceIfNeeded(timeout: timeout))
        closeButton.tap()

        dismissAlertView(alertBody: "Success: payment method not set, canceled", alertTitle: "Complete", buttonToTap: "OK")

        let selectButtonFinal = app.staticTexts["None"].firstMatch
        XCTAssertTrue(selectButtonFinal.waitForExistenceIfNeeded(timeout: timeout))
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
        presentCSAndAddCardFrom(buttonLabel: "••••4242", cardNumber: "5555555555554444")

        let selectButton = app.staticTexts["••••4444"].firstMatch
        XCTAssertTrue(selectButton.waitForExistenceIfNeeded(timeout: timeout))
        selectButton.tap()

        let editButton = app.staticTexts["Edit"].firstMatch
        XCTAssertTrue(editButton.waitForExistenceIfNeeded(timeout: timeout))
        editButton.tap()

        removeFirstPaymentMethodInList(alertBody: "Mastercard •••• 4444")
        // ••••4444 is rendered as the PM to remove, as well as the status on the playground
        // Check that it is removed by waiting for there only be one instance
        let elementLabel = "••••4444"
        let elementQuery = app.staticTexts.matching(NSPredicate(format: "label == %@", elementLabel))
        waitForNItemsExistence(elementQuery, count: 1)

        removeFirstPaymentMethodInList(alertBody: "Visa •••• 4242")
        let visa = app.staticTexts["••••4242"].firstMatch
        waitToDisappear(visa)

        let closeButton = app.buttons["Close"].firstMatch
        XCTAssertTrue(closeButton.waitForExistenceIfNeeded(timeout: timeout))
        closeButton.tap()

        dismissAlertView(alertBody: "Success: payment method not set, canceled", alertTitle: "Complete", buttonToTap: "OK")

        let selectButtonFinal = app.staticTexts["None"].firstMatch
        XCTAssertTrue(selectButtonFinal.waitForExistenceIfNeeded(timeout: timeout))
    }
    func testAddTwoPaymentMethods_thenUseCustomerSessionOnePM() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .on
        loadPlayground(
            app,
            settings
        )

        presentCSAndAddCardFrom(buttonLabel: "None")
        presentCSAndAddCardFrom(buttonLabel: "••••4242")

        // Reload
        app.buttons["Reload"].firstMatch.tap()

        // Present Sheet
        let selectButton = app.staticTexts["••••4242"].firstMatch
        XCTAssertTrue(selectButton.waitForExistenceIfNeeded(timeout: timeout))
        selectButton.tap()

        let editButton = app.staticTexts["Edit"].firstMatch
        XCTAssertTrue(editButton.waitForExistenceIfNeeded(timeout: timeout))

        // Assert there are two payment methods using legacy customer ephemeral key
        // value == 2, 1 value on playground + 2 payment method
        XCTAssertEqual(app.staticTexts.matching(identifier: "••••4242").count, 3)
        app.buttons["Close"].firstMatch.tap()
        dismissAlertView(alertBody: "Success: ••••4242, canceled", alertTitle: "Complete", buttonToTap: "OK")

        // Switch to use customer session
        app.buttons["customer_session"].firstMatch.tap()

        // TODO: Use default payment method from elements/sessions payload
        let selectButton2 = app.staticTexts["None"].firstMatch
        XCTAssertTrue(selectButton2.waitForExistenceIfNeeded(timeout: timeout))
        selectButton2.tap()

        // Wait for sheet to present
        XCTAssertTrue(editButton.waitForExistenceIfNeeded(timeout: timeout))

        // Requires FF: elements_enable_read_allow_redisplay, to return "1", otherwise 0
        XCTAssertEqual(app.staticTexts.matching(identifier: "••••4242").count, 1)

        XCTAssertTrue(app.staticTexts["Edit"].firstMatch.waitForExistenceAndTap())
        XCTAssertTrue(app.staticTexts["Done"].firstMatch.waitForExistenceIfNeeded(timeout: 1)) // Sanity check "Done" button is there

        // Remove one saved PM, which should remove both PMs
        XCTAssertNotNil(scroll(collectionView: app.collectionViews.firstMatch, toFindButtonWithId: "CircularButton.Remove")?.tap())
        XCTAssertTrue(app.alerts.buttons["Remove"].firstMatch.waitForExistenceAndTap())

        // Should be kicked out of edit mode now that we have one saved PM
        XCTAssertFalse(app.staticTexts["Done"].firstMatch.waitForExistenceIfNeeded(timeout: 1)) // "Done" button is gone - we are not in edit mode
        XCTAssertFalse(app.staticTexts["Edit"].firstMatch.waitForExistenceIfNeeded(timeout: 1)) // "Edit" button is gone - we can't edit

        let closeButton = app.buttons["Close"].firstMatch
        XCTAssertTrue(closeButton.waitForExistenceIfNeeded(timeout: timeout))
        closeButton.tap()

        dismissAlertView(alertBody: "Success: payment method not set, canceled", alertTitle: "Complete", buttonToTap: "OK")

        let selectButton3 = app.staticTexts["None"].firstMatch
        XCTAssertTrue(selectButton3.waitForExistenceIfNeeded(timeout: timeout))
        selectButton3.tap()

        // There should be zero cards left, because both should have been deleted
        XCTAssertEqual(app.staticTexts.matching(identifier: "••••4242").count, 0)
    }
    func testNoPrevPM_AddPM_noApplePay_closeInsteadOfConfirming() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .off
        loadPlayground(
            app,
            settings
        )

        let selectButton = app.staticTexts["None"].firstMatch
        XCTAssertTrue(selectButton.waitForExistenceIfNeeded(timeout: timeout))
        selectButton.tap()

        try! fillCardData(app, postalEnabled: true)
        app.buttons["Save"].firstMatch.tap()

        let confirmButton = app.buttons["Confirm"].firstMatch
        XCTAssertTrue(confirmButton.waitForExistenceIfNeeded(timeout: timeout))
        // Don't tap confirm!

        let closeButton = app.buttons["Close"].firstMatch
        XCTAssertTrue(closeButton.waitForExistenceIfNeeded(timeout: timeout))
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

        let selectButton = app.staticTexts["None"].firstMatch
        XCTAssertTrue(selectButton.waitForExistenceIfNeeded(timeout: timeout))
        selectButton.tap()

        app.staticTexts["+ Add"].firstMatch.waitForExistenceAndTap(timeout: timeout)

        try! fillCardData(app, postalEnabled: true)
        app.buttons["Save"].firstMatch.tap()

        let confirmButton = app.buttons["Confirm"].firstMatch
        XCTAssertTrue(confirmButton.waitForExistenceIfNeeded(timeout: timeout))
        // Don't tap confirm!

        let closeButton = app.buttons["Close"].firstMatch
        XCTAssertTrue(closeButton.waitForExistenceIfNeeded(timeout: timeout))
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
        let selectButton = app.staticTexts["••••4242"].firstMatch
        XCTAssertTrue(selectButton.waitForExistenceIfNeeded(timeout: timeout))
        selectButton.tap()

        app.staticTexts["+ Add"].firstMatch.waitForExistenceAndTap(timeout: timeout)

        try! fillCardData(app, cardNumber: "5555555555554444", postalEnabled: true)
        app.buttons["Save"].firstMatch.tap()

        let confirmButton = app.buttons["Confirm"].firstMatch
        XCTAssertTrue(confirmButton.waitForExistenceIfNeeded(timeout: timeout))
        // Don't tap!

        let closeButton = app.buttons["Close"].firstMatch
        XCTAssertTrue(closeButton.waitForExistenceIfNeeded(timeout: timeout))
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
        let selectButton = app.staticTexts["••••4242"].firstMatch
        XCTAssertTrue(selectButton.waitForExistenceIfNeeded(timeout: timeout))
        selectButton.tap()

        app.staticTexts["+ Add"].firstMatch.waitForExistenceAndTap(timeout: timeout)

        try! fillCardData(app, cardNumber: "5555555555554444", postalEnabled: true)
        app.buttons["Save"].firstMatch.tap()

        app.staticTexts["Apple Pay"].firstMatch.waitForExistenceAndTap()
        let confirmButton = app.buttons["Confirm"].firstMatch
        XCTAssertTrue(confirmButton.waitForExistenceIfNeeded(timeout: timeout))
        // Don't tap!

        let closeButton = app.buttons["Close"].firstMatch
        XCTAssertTrue(closeButton.waitForExistenceIfNeeded(timeout: timeout))
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

        app.staticTexts["None"].firstMatch.waitForExistenceAndTap(timeout: timeout)

        let usBankAccountPMSelectorButton = app.staticTexts["US Bank Account"].firstMatch
        XCTAssertTrue(usBankAccountPMSelectorButton.waitForExistenceIfNeeded(timeout: timeout))
        usBankAccountPMSelectorButton.tap()

        try! fillUSBankData(app)

        let continueButton = app.buttons["Continue"].firstMatch
        XCTAssertTrue(continueButton.waitForExistenceIfNeeded(timeout: timeout))
        continueButton.tap()

        // Go through connections flow
        app.buttons["consent_agree_button"].firstMatch.tap()
        app.staticTexts["Test Institution"].firstMatch.forceTapElement()
        app.staticTexts["Success"].firstMatch.waitForExistenceAndTap(timeout: timeout)
        app.buttons["account_picker_link_accounts_button"].firstMatch.tap()

        let notNowButton = app.buttons["Not now"].firstMatch
        if notNowButton.waitForExistenceIfNeeded(timeout: timeout) {
            notNowButton.tap()
        }

        XCTAssertTrue(app.staticTexts["Success"].firstMatch.waitForExistenceIfNeeded(timeout: timeout))
        app.buttons.matching(identifier: "Done").allElementsBoundByIndex.last?.tap()

        let testBankLinkedBankAccount = app.staticTexts["StripeBank"].firstMatch
        XCTAssertTrue(testBankLinkedBankAccount.waitForExistenceIfNeeded(timeout: timeout))

        let saveButton = app.buttons["Save"].firstMatch
        XCTAssertTrue(saveButton.waitForExistenceIfNeeded(timeout: timeout))
        saveButton.tap()

        let confirmButton = app.buttons["Confirm"].firstMatch
        XCTAssertTrue(confirmButton.waitForExistenceIfNeeded(timeout: timeout))
        confirmButton.tap()

        dismissAlertView(alertBody: "Success: ••••1113, selected", alertTitle: "Complete", buttonToTap: "OK")
    }
    func testCustomerSheetStandard_applePayOff_addUSBankAccount_customerSession() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .off
        settings.customerKeyType = .customerSession
        loadPlayground(
            app,
            settings
        )

        app.staticTexts["None"].firstMatch.waitForExistenceAndTap(timeout: timeout)
        app.staticTexts["US Bank Account"].firstMatch.waitForExistenceAndTap(timeout: timeout)

        try! fillUSBankData(app)

        app.buttons["Continue"].firstMatch.waitForExistenceAndTap(timeout: timeout)

        // Go through connections flow
        app.buttons["consent_agree_button"].firstMatch.tap()
        app.staticTexts["Test Institution"].firstMatch.forceTapElement()
        app.staticTexts["Success"].firstMatch.waitForExistenceAndTap(timeout: timeout)
        app.buttons["account_picker_link_accounts_button"].firstMatch.tap()

        let notNowButton = app.buttons["Not now"].firstMatch
        if notNowButton.waitForExistenceIfNeeded(timeout: timeout) {
            notNowButton.tap()
        }

        XCTAssertTrue(app.staticTexts["Success"].firstMatch.waitForExistenceIfNeeded(timeout: timeout))
        app.buttons.matching(identifier: "Done").allElementsBoundByIndex.last?.tap()

        let testBankLinkedBankAccount = app.staticTexts["StripeBank"].firstMatch
        XCTAssertTrue(testBankLinkedBankAccount.waitForExistenceIfNeeded(timeout: timeout))

        let saveButton = app.buttons["Save"].firstMatch
        XCTAssertTrue(saveButton.waitForExistenceIfNeeded(timeout: timeout))
        saveButton.tap()

        let confirmButton = app.buttons["Confirm"].firstMatch
        XCTAssertTrue(confirmButton.waitForExistenceIfNeeded(timeout: timeout))
        confirmButton.tap()

        dismissAlertView(alertBody: "Success: ••••1113, selected", alertTitle: "Complete", buttonToTap: "OK")
    }
    func testCustomerSheetStandard_applePayOff_addSepa() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .off
        loadPlayground(
            app,
            settings
        )

        let selectButton = app.staticTexts["None"].firstMatch
        XCTAssertTrue(selectButton.waitForExistenceIfNeeded(timeout: timeout))
        selectButton.tap()

        let sepaDebit = app.staticTexts["SEPA Debit"].firstMatch
        XCTAssertTrue(sepaDebit.waitForExistenceIfNeeded(timeout: timeout))
        sepaDebit.tap()

        try! fillSepaData(app)

        let saveButton = app.buttons["Save"].firstMatch
        XCTAssertTrue(saveButton.waitForExistenceIfNeeded(timeout: timeout))
        saveButton.tap()

        let confirmButton = app.buttons["Confirm"].firstMatch
        XCTAssertTrue(confirmButton.waitForExistenceIfNeeded(timeout: timeout))
        confirmButton.tap()

        dismissAlertView(alertBody: "Success: ••••3000, selected", alertTitle: "Complete", buttonToTap: "OK")
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

        let selectButton = app.staticTexts["None"].firstMatch
        XCTAssertTrue(selectButton.waitForExistenceIfNeeded(timeout: timeout))
        selectButton.tap()

        let usBankAccountPMSelectorButton = app.staticTexts["US Bank Account"].firstMatch
        XCTAssertTrue(usBankAccountPMSelectorButton.waitForExistenceIfNeeded(timeout: timeout))
        usBankAccountPMSelectorButton.tap()

        let continueButton = app.buttons["Continue"].firstMatch
        XCTAssertTrue(continueButton.waitForExistenceIfNeeded(timeout: timeout))
        continueButton.tap()

        // Go through connections flow
        app.buttons["consent_agree_button"].firstMatch.tap()
        app.staticTexts["Test Institution"].firstMatch.forceTapElement()
        app.staticTexts["Success"].firstMatch.waitForExistenceAndTap(timeout: timeout)
        app.buttons["account_picker_link_accounts_button"].firstMatch.tap()

        let notNowButton = app.buttons["Not now"].firstMatch
        if notNowButton.waitForExistenceIfNeeded(timeout: timeout) {
            notNowButton.tap()
        }

        XCTAssertTrue(app.staticTexts["Success"].firstMatch.waitForExistenceIfNeeded(timeout: timeout))
        app.buttons.matching(identifier: "Done").allElementsBoundByIndex.last?.tap()

        let testBankLinkedBankAccount = app.staticTexts["StripeBank"].firstMatch
        XCTAssertTrue(testBankLinkedBankAccount.waitForExistenceIfNeeded(timeout: timeout))

        let saveButton = app.buttons["Save"].firstMatch
        XCTAssertTrue(saveButton.waitForExistenceIfNeeded(timeout: timeout))
        saveButton.tap()

        let confirmButton = app.buttons["Confirm"].firstMatch
        XCTAssertTrue(confirmButton.waitForExistenceIfNeeded(timeout: timeout))
        confirmButton.tap()

        dismissAlertView(alertBody: "Success: ••••1113, selected", alertTitle: "Complete", buttonToTap: "OK")
    }
    func testCustomerSheetStandard_applePayOff_addUSBankAccount_MicroDeposit() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .off

        loadPlayground(
            app,
            settings
        )

        let selectButton = app.staticTexts["None"].firstMatch
        XCTAssertTrue(selectButton.waitForExistenceIfNeeded(timeout: timeout))
        selectButton.tap()

        let usBankAccountPMSelectorButton = app.staticTexts["US Bank Account"].firstMatch
        XCTAssertTrue(usBankAccountPMSelectorButton.waitForExistenceIfNeeded(timeout: timeout))
        usBankAccountPMSelectorButton.tap()

        try! fillUSBankData(app)

        let continueButton = app.buttons["Continue"].firstMatch
        XCTAssertTrue(continueButton.waitForExistenceIfNeeded(timeout: timeout))
        continueButton.tap()

        // Go through connections flow
        app.otherElements["consent_manually_verify_label"].links.firstMatch.tap()
        try! fillUSBankData_microdeposits(app)

        let continueManualEntry = app.buttons["manual_entry_continue_button"].firstMatch
        XCTAssertTrue(continueManualEntry.waitForExistenceIfNeeded(timeout: timeout))
        continueManualEntry.tap()

        let doneManualEntry = app.buttons["success_done_button"].firstMatch
        XCTAssertTrue(doneManualEntry.waitForExistenceIfNeeded(timeout: timeout))
        doneManualEntry.tap()

        let saveButton = app.buttons["Save"].firstMatch
        XCTAssertTrue(saveButton.waitForExistenceIfNeeded(timeout: timeout))
        saveButton.tap()

        dismissAlertView(alertBody: "Success: payment method not set, canceled", alertTitle: "Complete", buttonToTap: "OK")
    }
    func testCustomerSheetSwiftUI() throws {
        app.launch()

        app.staticTexts["CustomerSheet (SwiftUI)"].firstMatch.tap()

        app.buttons["Using Returning Customer (Tap to Switch)"].firstMatch.tap()
        let newCustomerText = app.buttons["Using New Customer (Tap to Switch)"].firstMatch
        XCTAssertTrue(newCustomerText.waitForExistenceIfNeeded(timeout: timeout))

        let button = app.buttons["Present Customer Sheet"].firstMatch
        XCTAssertTrue(button.waitForExistenceIfNeeded(timeout: timeout))
        button.forceTapElement()

        app.staticTexts["+ Add"].firstMatch.waitForExistenceAndTap(timeout: timeout)

        try! fillCardData(app, postalEnabled: true)
        app.buttons["Save"].firstMatch.tap()

        let cardPresence = app.staticTexts["••••4242"].firstMatch
        XCTAssertTrue(cardPresence.waitForExistenceIfNeeded(timeout: timeout))

        let confirmButton = app.buttons["Confirm"].firstMatch
        XCTAssertTrue(confirmButton.waitForExistenceIfNeeded(timeout: timeout))
        confirmButton.tap()

        let last4Label = app.staticTexts["••••4242"].firstMatch
        XCTAssertTrue(last4Label.waitForExistenceIfNeeded(timeout: timeout))
        let last4Selectedlabel = app.staticTexts["(Selected)"].firstMatch
        XCTAssertTrue(last4Selectedlabel.waitForExistenceIfNeeded(timeout: timeout))
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

        app.buttons["Payment method"].firstMatch.waitForExistenceAndTap(timeout: timeout)
        app.staticTexts["+ Add"].firstMatch.waitForExistenceAndTap(timeout: timeout)

        let numberField = app.textFields["Card number"].firstMatch
        let cardBrandChoiceDropdown = app.pickerWheels.firstMatch

        // Type full card number to start fetching card brands again
        numberField.forceTapWhenHittableInTestCase(self)
        app.typeText("4000002500001001")
        app.textFields["expiration date"].firstMatch.waitForExistenceAndTap(timeout: timeout)
        app.typeText("1228") // Expiry
        app.typeText("123") // CVC
        app.toolbars.buttons["Done"].firstMatch.tap() // Country picker toolbar's "Done" button
        app.typeText("12345") // Postal

        // Card brand choice drop down should be enabled
        XCTAssertTrue(app.textFields["Select card brand (optional)"].firstMatch.waitForExistenceAndTap(timeout: timeout))
        XCTAssertTrue(cardBrandChoiceDropdown.waitForExistenceIfNeeded(timeout: timeout))
        cardBrandChoiceDropdown.selectNextOption()
        app.toolbars.buttons["Done"].firstMatch.tap()

        // We should have selected cartes bancaires
        XCTAssertTrue(app.textFields["Cartes Bancaires"].firstMatch.waitForExistenceIfNeeded(timeout: timeout))

        // Finish saving card
        app.buttons["Save"].firstMatch.waitForExistenceAndTap(timeout: timeout)
        app.buttons["Confirm"].firstMatch.waitForExistenceAndTap(timeout: timeout)
        let completeText = app.staticTexts["Complete"].firstMatch
        XCTAssertTrue(completeText.waitForExistenceIfNeeded(timeout: timeout))

        // Reload w/ same customer
        app.buttons["Reload"].firstMatch.tap()
        app.buttons["Payment method"].firstMatch.waitForExistenceAndTap(timeout: timeout)
        // Saved card should show the cartes bancaires logo
        XCTAssertTrue(app.staticTexts["••••1001"].firstMatch.waitForExistenceIfNeeded(timeout: timeout))
        XCTAssertTrue(app.images["carousel_card_cartes_bancaires"].waitForExistenceIfNeeded(timeout: timeout))

        let editButton = app.staticTexts["Edit"].firstMatch
        XCTAssertTrue(editButton.waitForExistenceIfNeeded(timeout: timeout))
        editButton.tap()

        // Saved card should show the edit icon since it is co-branded
        XCTAssertTrue(app.buttons["CircularButton.Edit"].firstMatch.waitForExistenceAndTap(timeout: timeout))

        // Update this card
        XCTAssertTrue(app.textFields["Cartes Bancaires"].firstMatch.waitForExistenceAndTap(timeout: timeout))
        XCTAssertTrue(app.pickerWheels.firstMatch.waitForExistenceIfNeeded(timeout: timeout))
        app.pickerWheels.firstMatch.swipeUp()
        app.toolbars.buttons["Done"].firstMatch.tap()
        app.buttons["Update card"].firstMatch.waitForExistenceAndTap(timeout: timeout)

        // We should have updated to Visa
        XCTAssertTrue(app.images["carousel_card_visa"].waitForExistenceIfNeeded(timeout: timeout))

        // Remove this card
        XCTAssertTrue(app.buttons["CircularButton.Edit"].firstMatch.waitForExistenceAndTap(timeout: timeout))
        XCTAssertTrue(app.buttons["Remove card"].firstMatch.waitForExistenceAndTap(timeout: timeout))
        let confirmRemoval = app.alerts.buttons["Remove"].firstMatch
        XCTAssertTrue(confirmRemoval.waitForExistenceIfNeeded(timeout: timeout))
        confirmRemoval.tap()

        // Verify card is removed
        app.buttons["Done"].firstMatch.waitForExistenceAndTap(timeout: timeout)
        app.buttons["Close"].firstMatch.waitForExistenceAndTap(timeout: timeout)
        app.buttons["Reload"].firstMatch.waitForExistenceAndTap(timeout: timeout)
        app.buttons["Payment method"].firstMatch.waitForExistenceAndTap(timeout: timeout)
        // Card is no longer saved
        XCTAssertFalse(app.staticTexts["••••1001"].firstMatch.waitForExistenceIfNeeded(timeout: timeout))
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

        app.buttons["Payment method"].firstMatch.waitForExistenceAndTap(timeout: timeout)
        app.staticTexts["+ Add"].firstMatch.waitForExistenceAndTap(timeout: timeout)

        // We should have selected Visa due to preferreedNetworks configuration API
        let cardBrandTextField = app.textFields["Visa"].firstMatch
        let cardBrandChoiceDropdown = app.pickerWheels.firstMatch
        // Card brand choice textfield/dropdown should not be visible
        XCTAssertFalse(cardBrandTextField.waitForExistenceIfNeeded(timeout: 2))

        let numberField = app.textFields["Card number"].firstMatch
        numberField.tap()
        // Enter 8 digits to start fetching card brand
        numberField.typeText("49730197")

        // Card brand choice drop down should be enabled
        cardBrandTextField.tap()
        XCTAssertTrue(cardBrandChoiceDropdown.waitForExistenceIfNeeded(timeout: timeout))
        cardBrandChoiceDropdown.swipeDown()
        app.toolbars.buttons["Cancel"].firstMatch.tap()

        // We should have selected Visa due to preferreedNetworks configuration API
        XCTAssertTrue(app.textFields["Visa"].firstMatch.waitForExistenceIfNeeded(timeout: 2))

        // Clear card text field, should reset selected card brand
        numberField.tap()
        numberField.clearText()

        // We should reset to showing unknown in the textfield for card brand
        XCTAssertFalse(app.textFields["Select card brand (optional)"].firstMatch.waitForExistenceIfNeeded(timeout: 2))

        // Type full card number to start fetching card brands again
        numberField.forceTapWhenHittableInTestCase(self)
        app.typeText("4000002500001001")
        app.textFields["expiration date"].firstMatch.waitForExistenceAndTap(timeout: timeout)
        app.typeText("1228") // Expiry
        app.typeText("123") // CVC
        app.toolbars.buttons["Done"].firstMatch.tap() // Country picker toolbar's "Done" button
        app.typeText("12345") // Postal

        // Card brand choice drop down should be enabled and we should auto select Visa
        XCTAssertTrue(app.textFields["Visa"].firstMatch.waitForExistenceIfNeeded(timeout: timeout))

        // Finish saving card
        app.buttons["Save"].firstMatch.tap()
        app.buttons["Confirm"].firstMatch.waitForExistenceAndTap(timeout: timeout)
        let successText = app.staticTexts["Complete"].firstMatch
        XCTAssertTrue(successText.waitForExistenceIfNeeded(timeout: timeout))
    }

    // MARK: - allowsRemovalOfLastSavedPaymentMethod
    func testRemoveLastSavedPaymentMethod() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.merchantCountryCode = .FR
        settings.customerMode = .new
        settings.applePay = .on
        settings.allowsRemovalOfLastSavedPaymentMethod = .off
        loadPlayground(
            app,
            settings
        )

        // Save a card
        app.staticTexts["None"].firstMatch.waitForExistenceAndTap()
        app.buttons["+ Add"].firstMatch.waitForExistenceAndTap()
        try! fillCardData(app, postalEnabled: true)
        app.buttons["Save"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Confirm"].firstMatch.waitForExistenceIfNeeded(timeout: timeout))

        // Shouldn't be able to edit only one saved PM when allowsRemovalOfLastSavedPaymentMethod = .off
        XCTAssertFalse(app.staticTexts["Edit"].firstMatch.waitForExistenceIfNeeded(timeout: 1))

        // Add another PM
        app.buttons["+ Add"].firstMatch.waitForExistenceAndTap()
        try! fillCardData(app, postalEnabled: true)
        app.buttons["Save"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Confirm"].firstMatch.waitForExistenceIfNeeded(timeout: timeout))

        // Should be able to edit two saved PMs
        XCTAssertTrue(app.staticTexts["Edit"].firstMatch.waitForExistenceAndTap())
        XCTAssertTrue(app.staticTexts["Done"].firstMatch.waitForExistenceIfNeeded(timeout: 1)) // Sanity check "Done" button is there

        // Remove one saved PM
        XCTAssertNotNil(scroll(collectionView: app.collectionViews.firstMatch, toFindButtonWithId: "CircularButton.Remove")?.tap())
        XCTAssertTrue(app.alerts.buttons["Remove"].firstMatch.waitForExistenceAndTap())

        // Should be kicked out of edit mode now that we have one saved PM
        XCTAssertFalse(app.staticTexts["Done"].firstMatch.waitForExistenceIfNeeded(timeout: 1)) // "Done" button is gone - we are not in edit mode
        XCTAssertFalse(app.staticTexts["Edit"].firstMatch.waitForExistenceIfNeeded(timeout: 1)) // "Edit" button is gone - we can't edit

        // Add a CBC enabled PM
        app.buttons["+ Add"].firstMatch.waitForExistenceAndTap()
        try! fillCardData(app, cardNumber: "4000002500001001", postalEnabled: true)
        app.buttons["Save"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Confirm"].firstMatch.waitForExistenceIfNeeded(timeout: timeout))

        // Should be able to edit two saved PMs
        XCTAssertTrue(app.staticTexts["Edit"].firstMatch.waitForExistenceAndTap())
        XCTAssertTrue(app.staticTexts["Done"].firstMatch.waitForExistenceIfNeeded(timeout: 1)) // Sanity check "Done" button is there

        // Remove the 4242 saved PM
        XCTAssertNotNil(scroll(collectionView: app.collectionViews.firstMatch, toFindButtonWithId: "CircularButton.Remove")?.tap())
        XCTAssertTrue(app.alerts.buttons["Remove"].firstMatch.waitForExistenceAndTap())

        // Should be able to edit CBC enabled PM even though it's the only one
        XCTAssertTrue(app.buttons["CircularButton.Edit"].firstMatch.waitForExistenceAndTap(timeout: timeout))
        XCTAssertTrue(app.buttons["Update card"].firstMatch.waitForExistenceIfNeeded(timeout: timeout))

        // ...but should not be able to remove it.
        XCTAssertFalse(app.buttons["Remove card"].firstMatch.exists)
    }

    // MARK: - Helpers

    func presentCSAndAddCardFrom(buttonLabel: String, cardNumber: String? = nil, tapAdd: Bool = true) {
        let selectButton = app.staticTexts[buttonLabel]
        XCTAssertTrue(selectButton.waitForExistenceIfNeeded(timeout: timeout))
        selectButton.tap()

        if tapAdd {
            app.staticTexts["+ Add"].firstMatch.waitForExistenceAndTap(timeout: timeout)
        }

        let numberField = app.textFields["Card number"].firstMatch
        XCTAssertTrue(numberField.waitForExistenceIfNeeded(timeout: timeout))

        try! fillCardData(app, cardNumber: cardNumber, postalEnabled: true)
        app.buttons["Save"].firstMatch.tap()

        let confirmButton = app.buttons["Confirm"].firstMatch
        XCTAssertTrue(confirmButton.waitForExistenceIfNeeded(timeout: timeout))
        confirmButton.tap()
        if let cardNumber {
            let last4 = String(cardNumber.suffix(4))
            dismissAlertView(alertBody: "Success: ••••\(last4), selected", alertTitle: "Complete", buttonToTap: "OK")
        } else {
            dismissAlertView(alertBody: "Success: ••••4242, selected", alertTitle: "Complete", buttonToTap: "OK")
        }
    }

    func removeFirstPaymentMethodInList(alertBody: String = "Visa •••• 4242") {
        let removeButton1 = app.buttons["Remove"].firstMatch
        removeButton1.tap()
        dismissAlertView(alertBody: alertBody, alertTitle: "Remove card?", buttonToTap: "Remove")
    }

    func dismissAlertView(alertBody: String, alertTitle: String, buttonToTap: String) {
        let alertText = app.staticTexts[alertBody]
        XCTAssertTrue(alertText.waitForExistenceIfNeeded(timeout: timeout))

        let alert = app.alerts[alertTitle]
        alert.buttons[buttonToTap].tap()
    }
}
