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
                                 "FinancialConnectionsSDKAvailable": "true",
                                 "FinancialConnectionsStubbedResult": "false",
        ]
        app.launch()
    }

    func testCustomerSheetStandard_applePayOn_addCard_ensureCanDismissOnUnsupportedPaymentMethod() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .on
        loadPlayground(
            app,
            settings
        )

        let selectButton = app.staticTexts["None"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: timeout))
        selectButton.tap()

        app.staticTexts["+ Add"].waitForExistenceAndTap(timeout: timeout)

        try! fillCardData(app, postalEnabled: true)
        app.buttons["Save"].tap()

        // Verify that when hitting add again, card details are empty
        app.staticTexts["+ Add"].waitForExistenceAndTap(timeout: timeout)

        if let cardInformation = app.textFields["Card number"].value as? String {
            XCTAssert(cardInformation.isEmpty)
        } else {
            XCTFail("unable to get card number field")
        }

        let backButton = app.buttons["Back"]
        XCTAssertTrue(backButton.waitForExistence(timeout: timeout))
        backButton.tap()

        // Confirm the last added payment method
        let confirmButton = app.buttons["Confirm"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: timeout))
        // Don't tap confirm, just close: Test that the first payment method added will automatically be selected

        let closeButton = app.buttons["Close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: timeout))
        closeButton.tap()

        let paymentMethodButton = app.staticTexts["Success: •••• 4242, selected"]  // The card should be saved now
        XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: timeout))

        dismissAlertView(alertBody: "Success: •••• 4242, selected", alertTitle: "Complete", buttonToTap: "OK")

        // Piggy back on the original test to ensure we can dismiss the sheet if we have an unsupported payment method
        app.buttons["SetPMLink"].tap()
        app.staticTexts["None"].waitForExistenceAndTap()
        app.buttons["Close"].waitForExistenceAndTap()

        dismissAlertView(alertBody: "Success: payment method not set, canceled", alertTitle: "Complete", buttonToTap: "OK")

        // Piggy back and now select apple pay
        app.staticTexts["None"].waitForExistenceAndTap(timeout: timeout)
        app.collectionViews.staticTexts["Apple Pay"].waitForExistenceAndTap(timeout: timeout)
        XCTAssertTrue(confirmButton.waitForExistence(timeout: timeout))
        confirmButton.tap()

        let applePaymentMethodButton = app.staticTexts["Success: Apple Pay, selected"]
        XCTAssertTrue(applePaymentMethodButton.waitForExistence(timeout: timeout))

    }

    func testAddPaymentMethod_RemoveBeforeConfirming() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .on
        loadPlayground(
            app,
            settings
        )

        app.staticTexts["None"].waitForExistenceAndTap(timeout: timeout)
        app.staticTexts["+ Add"].waitForExistenceAndTap(timeout: timeout)

        try! fillCardData(app, postalEnabled: true)
        app.buttons["Save"].tap()

        let cardPresence_beforeRemoval = app.staticTexts["•••• 4242"]
        XCTAssertTrue(cardPresence_beforeRemoval.waitForExistence(timeout: 60.0))

        let editButton = app.staticTexts["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 60.0))
        editButton.tap()

        removeFirstPaymentMethodInList()

        let cardPresence_afterRemoval = app.staticTexts["•••• 4242"]
        waitToDisappear(cardPresence_afterRemoval)

        let closeButton = app.buttons["Close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 60.0))
        closeButton.tap()

        dismissAlertView(alertBody: "Success: payment method not set, canceled", alertTitle: "Complete", buttonToTap: "OK")

        let selectButtonFinal = app.staticTexts["None"]
        XCTAssertTrue(selectButtonFinal.waitForExistence(timeout: timeout))
    }

    func testCreateAndAttach() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .on
        settings.paymentMethodMode = .createAndAttach
        loadPlayground(
            app,
            settings
        )

        app.staticTexts["None"].waitForExistenceAndTap(timeout: timeout)
        app.staticTexts["+ Add"].waitForExistenceAndTap(timeout: timeout)

        try! fillCardData(app, postalEnabled: true)
        app.buttons["Save"].tap()

        let cardPresence = app.staticTexts["•••• 4242"]
        XCTAssertTrue(cardPresence.waitForExistence(timeout: timeout))

        app.staticTexts["+ Add"].waitForExistenceAndTap(timeout: timeout)

        // Verify that when hitting add again, card details are empty
        if let cardInformation = app.textFields["Card number"].value as? String {
            XCTAssert(cardInformation.isEmpty)
        } else {
            XCTFail("unable to get card number field")
        }

        let backButton = app.buttons["Back"]
        XCTAssertTrue(backButton.waitForExistence(timeout: timeout))
        backButton.tap()

        let closeButton = app.buttons["Confirm"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: timeout))
        closeButton.tap()

        dismissAlertView(alertBody: "Success: •••• 4242, selected", alertTitle: "Complete", buttonToTap: "OK")

        let selectButtonFinal = app.staticTexts["•••• 4242"]
        XCTAssertTrue(selectButtonFinal.waitForExistence(timeout: timeout))
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
        presentCSAndAddCardFrom(buttonLabel: "•••• 4242", cardNumber: "5555555555554444")

        app.staticTexts["•••• 4444"].waitForExistenceAndTap(timeout: timeout)

        let editButton = app.staticTexts["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: timeout))
        editButton.tap()

        removeFirstPaymentMethodInList(alertBody: "Mastercard •••• 4444")
        // •••• 4444 is rendered as the PM to remove, as well as the status on the playground
        // Check that it is removed by waiting for there only be one instance
        let elementLabel = "•••• 4444"
        let elementQuery = app.staticTexts.matching(NSPredicate(format: "label == %@", elementLabel))
        waitForNItemsExistence(elementQuery, count: 1)

        removeFirstPaymentMethodInList(alertBody: "Visa •••• 4242")
        let visa = app.staticTexts["•••• 4242"]
        waitToDisappear(visa)

        let closeButton = app.buttons["Close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: timeout))
        closeButton.tap()

        dismissAlertView(alertBody: "Success: payment method not set, canceled", alertTitle: "Complete", buttonToTap: "OK")

        let selectButtonFinal = app.staticTexts["None"]
        XCTAssertTrue(selectButtonFinal.waitForExistence(timeout: timeout))
    }

    func testRemoveCardPaymentMethod_customerSessions() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.customerKeyType = .customerSession
        settings.applePay = .on
        loadPlayground(
            app,
            settings
        )

        presentCSAndAddCardFrom(buttonLabel: "None")

        app.staticTexts["•••• 4242"].waitForExistenceAndTap(timeout: timeout)

        let editButton = app.staticTexts["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: timeout))
        editButton.tap()

        removeFirstPaymentMethodInList(alertBody: "Visa •••• 4242")

        let closeButton = app.buttons["Close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: timeout))
        closeButton.tap()

        dismissAlertView(alertBody: "Success: payment method not set, canceled", alertTitle: "Complete", buttonToTap: "OK")
        let selectButtonFinal = app.staticTexts["None"]
        XCTAssertTrue(selectButtonFinal.waitForExistence(timeout: timeout))

        // Reload customer sheet and ensure removal of payment method
        app.buttons["Reload"].tap()
        XCTAssertTrue(app.staticTexts["None"].waitForExistenceAndTap(timeout: 5))
        XCTAssertTrue(app.staticTexts["Manage your payment methods"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["•••• 4242"].waitForExistence(timeout: 5))
    }

    func testRemoveSepaPaymentMethod_customerSessions() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.customerKeyType = .customerSession
        settings.applePay = .on
        loadPlayground(
            app,
            settings
        )

        presentCSAndAddSepaFrom(buttonLabel: "None")

        app.staticTexts["••••3000"].waitForExistenceAndTap(timeout: timeout)

        let editButton = app.staticTexts["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: timeout))
        editButton.tap()

        removeFirstPaymentMethodInList(alertBody: "Bank account •••• 3000", alertTitle: "Remove bank account?")

        let closeButton = app.buttons["Close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: timeout))
        closeButton.tap()

        dismissAlertView(alertBody: "Success: payment method not set, canceled", alertTitle: "Complete", buttonToTap: "OK")
        let selectButtonFinal = app.staticTexts["None"]
        XCTAssertTrue(selectButtonFinal.waitForExistence(timeout: timeout))

        // Reload customer sheet and ensure removal of payment method
        app.buttons["Reload"].tap()
        XCTAssertTrue(app.staticTexts["None"].waitForExistenceAndTap(timeout: 5))
        XCTAssertTrue(app.staticTexts["Manage your payment methods"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["••••3000"].waitForExistence(timeout: 5))
    }

    func testPrevPM_AddPM_canceled() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .on
        loadPlayground(
            app,
            settings
        )

        presentCSAndAddCardFrom(buttonLabel: "None")
        let selectButton = app.staticTexts["•••• 4242"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: timeout))
        selectButton.tap()

        app.staticTexts["+ Add"].waitForExistenceAndTap(timeout: timeout)

        try! fillCardData(app, cardNumber: "5555555555554444", postalEnabled: true)
        app.buttons["Save"].tap()

        app.staticTexts["Apple Pay"].waitForExistenceAndTap()
        let confirmButton = app.buttons["Confirm"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: timeout))
        // Don't tap!

        let closeButton = app.buttons["Close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: timeout))
        closeButton.tap()

        dismissAlertView(alertBody: "Success: •••• 4242, canceled", alertTitle: "Complete", buttonToTap: "OK")
    }

    func testCustomerSheet_addUSBankAccount() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .off
        loadPlayground(
            app,
            settings
        )

        app.staticTexts["None"].waitForExistenceAndTap(timeout: timeout)

        let usBankAccountPMSelectorButton = app.staticTexts["US bank account"]
        XCTAssertTrue(usBankAccountPMSelectorButton.waitForExistence(timeout: timeout))
        usBankAccountPMSelectorButton.tap()

        try! fillUSBankData(app)

        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: timeout))
        continueButton.tap()

        // Go through connections flow
        app.buttons["consent_agree_button"].tap()
        app.staticTexts["Test Institution"].forceTapElement()
        // "Success" institution is automatically selected because its the first
        app.buttons["connect_accounts_button"].waitForExistenceAndTap(timeout: timeout)

        skipLinkSignup(app)

        XCTAssertTrue(app.staticTexts["Success"].waitForExistence(timeout: timeout))
        app.buttons.matching(identifier: "Done").allElementsBoundByIndex.last?.tap()

        let testBankLinkedBankAccount = app.staticTexts["StripeBank"]
        XCTAssertTrue(testBankLinkedBankAccount.waitForExistence(timeout: timeout))

        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: timeout))
        saveButton.tap()

        let confirmButton = app.buttons["Confirm"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: timeout))
        confirmButton.tap()

        dismissAlertView(alertBody: "Success: ••••6789, selected", alertTitle: "Complete", buttonToTap: "OK")
    }

    func testCustomerSheet_addUSBankAccount_MicroDeposit() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .new
        settings.applePay = .off

        loadPlayground(
            app,
            settings
        )

        let selectButton = app.staticTexts["None"]
        XCTAssertTrue(selectButton.waitForExistence(timeout: timeout))
        selectButton.tap()

        let usBankAccountPMSelectorButton = app.staticTexts["US bank account"]
        XCTAssertTrue(usBankAccountPMSelectorButton.waitForExistence(timeout: timeout))
        usBankAccountPMSelectorButton.tap()

        try! fillUSBankData(app)

        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: timeout))
        continueButton.tap()

        // Go through connections flow
        app.otherElements["consent_manually_verify_label"].links.firstMatch.tap()
        try! fillUSBankData_microdeposits(app)

        let continueManualEntry = app.buttons["manual_entry_continue_button"]
        XCTAssertTrue(continueManualEntry.waitForExistence(timeout: timeout))
        continueManualEntry.tap()

        // Fill out Link
        XCTAssertTrue(app.textFields["Email"].waitForExistence(timeout: timeout))
        app.typeText("test-\(UUID().uuidString)@example.com")
        XCTAssertTrue(app.textFields["Phone number"].waitForExistence(timeout: timeout))
        app.typeText("3105551234")
        app.toolbars.buttons["Done"].tap()
        app.buttons["Save with Link"].waitForExistenceAndTap(timeout: timeout)

        let doneManualEntry = app.buttons["success_done_button"]
        XCTAssertTrue(doneManualEntry.waitForExistence(timeout: timeout))
        doneManualEntry.tap()

        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: timeout))
        saveButton.tap()

        dismissAlertView(alertBody: "Success: payment method not set, canceled", alertTitle: "Complete", buttonToTap: "OK")
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

        app.buttons["Payment method"].waitForExistenceAndTap(timeout: timeout)
        app.staticTexts["+ Add"].waitForExistenceAndTap(timeout: timeout)

        let numberField = app.textFields["Card number"]
        let cardBrandChoiceDropdown = app.pickerWheels.firstMatch

        // Type full card number to start fetching card brands again
        numberField.forceTapWhenHittableInTestCase(self)
        app.typeText("4000002500001001")
        app.textFields["expiration date"].waitForExistenceAndTap(timeout: timeout)
        app.typeText("1228") // Expiry
        app.typeText("123") // CVC
        app.typeText("12345") // Postal

        // Card brand choice drop down should be enabled
        XCTAssertTrue(app.textFields["Select card brand (optional)"].waitForExistenceAndTap(timeout: timeout))
        XCTAssertTrue(cardBrandChoiceDropdown.waitForExistence(timeout: timeout))
        cardBrandChoiceDropdown.selectNextOption()
        app.toolbars.buttons["Done"].tap()
        // Bug where it autoadvances to the MM / YY field even though it's filled out, have to tap Done again
        app.toolbars.buttons["Done"].tap()

        // We should have selected cartes bancaires
        XCTAssertTrue(app.textFields["Cartes Bancaires"].waitForExistence(timeout: timeout))

        // Finish saving card
        app.buttons["Save"].waitForExistenceAndTap(timeout: timeout)
        app.buttons["Confirm"].waitForExistenceAndTap(timeout: timeout)
        let completeText = app.staticTexts["Complete"]
        XCTAssertTrue(completeText.waitForExistence(timeout: timeout))

        // Reload w/ same customer
        app.buttons["Reload"].tap()
        app.buttons["Payment method"].waitForExistenceAndTap(timeout: timeout)
        // Saved card should show the cartes bancaires logo
        XCTAssertTrue(app.staticTexts["•••• 1001"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.images["carousel_card_cartes_bancaires"].waitForExistence(timeout: timeout))

        app.staticTexts["Edit"].waitForExistenceAndTap(timeout: timeout)

        // Saved card should show the edit icon since it is co-branded
        XCTAssertTrue(app.buttons["CircularButton.Edit"].waitForExistenceAndTap(timeout: timeout))

        // Update this card
        XCTAssertTrue(app.textFields["Cartes Bancaires"].waitForExistenceAndTap(timeout: timeout))
        XCTAssertTrue(app.pickerWheels.firstMatch.waitForExistence(timeout: timeout))
        app.pickerWheels.firstMatch.swipeUp()
        app.toolbars.buttons["Done"].tap()
        app.buttons["Save"].waitForExistenceAndTap(timeout: timeout)

        // We should have updated to Visa
        XCTAssertTrue(app.images["carousel_card_visa"].waitForExistence(timeout: timeout))

        // Remove this card
        XCTAssertTrue(app.buttons["CircularButton.Edit"].waitForExistenceAndTap(timeout: timeout))
        XCTAssertTrue(app.buttons["Remove"].waitForExistenceAndTap(timeout: timeout))
        let confirmRemoval = app.alerts.buttons["Remove"]
        XCTAssertTrue(confirmRemoval.waitForExistence(timeout: timeout))
        confirmRemoval.tap()

        // Verify card is removed
        app.buttons["Close"].waitForExistenceAndTap(timeout: timeout)
        app.buttons["Reload"].waitForExistenceAndTap(timeout: timeout)
        app.buttons["Payment method"].waitForExistenceAndTap(timeout: timeout)

        // Card is no longer saved - Wait for ApplePay is a signal the view has loaded, then wait 0.5
        // up to 0.5 seconds to ensure card is not there
        XCTAssertTrue(app.collectionViews.staticTexts["Apple Pay"].waitForExistence(timeout: timeout))
        XCTAssertFalse(app.staticTexts["•••• 1001"].waitForExistence(timeout: 0.5))
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

        app.buttons["Payment method"].waitForExistenceAndTap(timeout: timeout)
        app.staticTexts["+ Add"].waitForExistenceAndTap(timeout: timeout)

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
        XCTAssertTrue(cardBrandChoiceDropdown.waitForExistence(timeout: timeout))
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
        app.textFields["expiration date"].waitForExistenceAndTap(timeout: timeout)
        app.typeText("1228") // Expiry
        app.typeText("123") // CVC
        app.typeText("12345") // Postal

        // Card brand choice drop down should be enabled and we should auto select Visa
        XCTAssertTrue(app.textFields["Visa"].waitForExistence(timeout: timeout))

        // Finish saving card
        app.buttons["Save"].tap()
        app.buttons["Confirm"].waitForExistenceAndTap(timeout: timeout)
        let successText = app.staticTexts["Complete"]
        XCTAssertTrue(successText.waitForExistence(timeout: timeout))
    }

    func testCardBrandChoiceUpdateAndRemove() {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.merchantCountryCode = .FR
        settings.customerMode = .returning

        loadPlayground(app, settings)

        app.buttons["None"].waitForExistenceAndTap()
        app.buttons["Edit"].waitForExistenceAndTap()

        // circularEditButton shows up in the view hierarchy, but it's not actually on the screen or tappable so we scroll a little
        let startCoordinate = app.collectionViews.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.99))
        startCoordinate.press(forDuration: 0.1, thenDragTo: app.collectionViews.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.99)))
        XCTAssertTrue(app.buttons.matching(identifier: "CircularButton.Edit").element(boundBy: 1).waitForExistenceAndTap())
        XCTAssertTrue(app.otherElements.matching(identifier: "Card Brand Dropdown").firstMatch.waitForExistenceAndTap())
        app.pickerWheels.firstMatch.selectNextOption()
        app.toolbars.buttons["Done"].tap()
        XCTAssertTrue(app.textFields["Visa"].waitForExistence(timeout: 3))
        app.buttons["Save"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.images.matching(identifier: "carousel_card_visa").count, 2)

        app.buttons.matching(identifier: "CircularButton.Edit").element(boundBy: 2).waitForExistenceAndTap()
        app.buttons["Remove"].waitForExistenceAndTap()
        app.alerts.buttons["Remove"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.images.matching(identifier: "carousel_card_visa").count, 1)
        app.buttons["Done"].waitForExistenceAndTap()
    }
    // MARK: - allowsRemovalOfLastSavedPaymentMethod
    func testRemoveLastSavedPaymentMethod_clientConfig() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.merchantCountryCode = .FR
        settings.customerMode = .new
        settings.applePay = .on
        settings.allowsRemovalOfLastSavedPaymentMethod = .off
        loadPlayground(
            app,
            settings
        )
        try _testRemoveLastSavedPaymentMethod()
    }
    func testRemoveLastSavedPaymentMethod_customerSession() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.merchantCountryCode = .FR
        settings.customerMode = .new
        settings.applePay = .on
        settings.allowsRemovalOfLastSavedPaymentMethod = .on
        settings.customerKeyType = .customerSession
        settings.paymentMethodRemoveLast = .disabled
        loadPlayground(
            app,
            settings
        )
        try _testRemoveLastSavedPaymentMethod()
    }
    func _testRemoveLastSavedPaymentMethod() throws {
        // Save a card
        app.staticTexts["None"].waitForExistenceAndTap()
        app.buttons["+ Add"].waitForExistenceAndTap()
        try! fillCardData(app, postalEnabled: true)
        app.buttons["Save"].tap()
        XCTAssertTrue(app.buttons["Confirm"].waitForExistence(timeout: timeout))

        // Shouldn't be able to edit only one saved PM when allowsRemovalOfLastSavedPaymentMethod = .off
        XCTAssertFalse(app.staticTexts["Edit"].waitForExistence(timeout: 1))

        // Add another PM
        app.buttons["+ Add"].waitForExistenceAndTap()
        try! fillCardData(app, cardNumber: "5555555555554444", postalEnabled: true)
        app.buttons["Save"].tap()
        XCTAssertTrue(app.buttons["Confirm"].waitForExistence(timeout: timeout))

        // Should be able to edit two saved PMs
        XCTAssertTrue(app.staticTexts["Edit"].waitForExistenceAndTap())
        XCTAssertTrue(app.staticTexts["Done"].waitForExistence(timeout: 1)) // Sanity check "Done" button is there

        // Remove one saved PM
        XCTAssertNotNil(scroll(collectionView: app.collectionViews.firstMatch, toFindButtonWithId: "CircularButton.Edit")?.tap())
        app.buttons["Remove"].waitForExistenceAndTap()
        XCTAssertTrue(app.alerts.buttons["Remove"].waitForExistenceAndTap())

        // Sleep for 1 second to ensure animation has been completed
        sleep(1)

        // Should be kicked out of edit mode now that we have one saved PM
        XCTAssertFalse(app.staticTexts["Done"].waitForExistence(timeout: 1)) // "Done" button is gone - we are not in edit mode
        XCTAssertFalse(app.staticTexts["Edit"].waitForExistence(timeout: 1)) // "Edit" button is gone - we can't edit

        // Add a CBC enabled PM
        app.buttons["+ Add"].waitForExistenceAndTap()
        try! fillCardData(app, cardNumber: "4000002500001001", postalEnabled: true)
        app.buttons["Save"].tap()
        XCTAssertTrue(app.buttons["Confirm"].waitForExistence(timeout: timeout))

        // Should be able to edit two saved PMs
        XCTAssertTrue(app.staticTexts["Edit"].waitForExistenceAndTap())
        XCTAssertTrue(app.staticTexts["Done"].waitForExistence(timeout: 1)) // Sanity check "Done" button is there

        // Remove the 4242 saved PM
        // circularEditButton shows up in the view hierarchy, but it's not actually on the screen or tappable so we scroll a little
        let startCoordinate = app.collectionViews.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.99))
        startCoordinate.press(forDuration: 0.1, thenDragTo: app.collectionViews.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.99)))
        XCTAssertTrue(app.buttons.matching(identifier: "CircularButton.Edit").element(boundBy: 1).waitForExistenceAndTap())
        app.buttons["Remove"].waitForExistenceAndTap()
        XCTAssertTrue(app.alerts.buttons["Remove"].waitForExistenceAndTap())

        // Wait for alert view to disappear and removal animation to finish
        sleep(1)

        // Should be able to edit CBC enabled PM even though it's the only one
        XCTAssertTrue(app.buttons["CircularButton.Edit"].waitForExistenceAndTap(timeout: timeout))
        XCTAssertTrue(app.buttons["Save"].waitForExistence(timeout: timeout))

        // ...but should not be able to remove it.
        XCTAssertFalse(app.buttons["Remove"].exists)
    }
    // MARK: - PaymentMethodRemove w/ CBC
    func testCSPaymentMethodRemoveTwoCards() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.merchantCountryCode = .FR
        settings.customerMode = .new
        settings.applePay = .on
        settings.customerKeyType = .customerSession
        settings.paymentMethodRemove = .disabled
        settings.allowsRemovalOfLastSavedPaymentMethod = .on
        loadPlayground(
            app,
            settings
        )

        // Save a card
        app.staticTexts["None"].waitForExistenceAndTap()
        app.buttons["+ Add"].waitForExistenceAndTap()
        try! fillCardData(app, postalEnabled: true)
        app.buttons["Save"].tap()
        XCTAssertTrue(app.buttons["Confirm"].waitForExistence(timeout: timeout))

        // Shouldn't be able to edit non-CBC eligible card when paymentMethodRemove = .disabled
        XCTAssertFalse(app.staticTexts["Edit"].waitForExistence(timeout: 1))

        // Add a CBC enabled PM
        app.buttons["+ Add"].waitForExistenceAndTap()
        try! fillCardData(app, cardNumber: "4000002500001001", postalEnabled: true)
        app.buttons["Save"].tap()
        XCTAssertTrue(app.buttons["Confirm"].waitForExistence(timeout: timeout))

        // Should be able to edit because of CBC saved PMs
        XCTAssertTrue(app.staticTexts["Edit"].waitForExistenceAndTap())
        XCTAssertTrue(app.staticTexts["Done"].waitForExistence(timeout: 1)) // Sanity check "Done" button is there

        // Assert there are no remove buttons on each tile and the update screen
        XCTAssertNil(scroll(collectionView: app.collectionViews.firstMatch, toFindButtonWithId: "CircularButton.Remove"))
        XCTAssertTrue(app.buttons["CircularButton.Edit"].waitForExistenceAndTap(timeout: timeout))

        // Dismiss Sheet
        app.buttons["Back"].waitForExistenceAndTap(timeout: timeout)
        app.buttons["Done"].waitForExistenceAndTap(timeout: timeout)
        app.buttons["Close"].waitForExistenceAndTap(timeout: timeout)
    }

    func testCSPaymentMethodRemoveTwoCards_keeplastSavedPaymentMethod_CBC() throws {
        var settings = CustomerSheetTestPlaygroundSettings.defaultValues()
        settings.merchantCountryCode = .FR
        settings.customerMode = .new
        settings.applePay = .on
        settings.customerKeyType = .customerSession
        settings.paymentMethodRemove = .disabled
        settings.allowsRemovalOfLastSavedPaymentMethod = .off
        loadPlayground(
            app,
            settings
        )

        // Save a card
        app.staticTexts["None"].waitForExistenceAndTap()
        app.buttons["+ Add"].waitForExistenceAndTap()
        try! fillCardData(app, cardNumber: "4000002500001001", postalEnabled: true)
        app.buttons["Save"].tap()
        XCTAssertTrue(app.buttons["Confirm"].waitForExistence(timeout: timeout))

        // Should be able to edit because of CBC saved PMs
        XCTAssertTrue(app.staticTexts["Edit"].waitForExistenceAndTap())
        XCTAssertTrue(app.staticTexts["Done"].waitForExistence(timeout: 1)) // Sanity check "Done" button is there

        // Assert there are no remove buttons on each tile and the update screen
        XCTAssertNil(scroll(collectionView: app.collectionViews.firstMatch, toFindButtonWithId: "CircularButton.Remove"))
        XCTAssertTrue(app.buttons["CircularButton.Edit"].waitForExistenceAndTap(timeout: timeout))

        // Dismiss Sheet
        app.buttons["Back"].waitForExistenceAndTap(timeout: timeout)
        app.buttons["Done"].waitForExistenceAndTap(timeout: timeout)
        app.buttons["Close"].waitForExistenceAndTap(timeout: timeout)
    }

    // MARK: - Helpers

    func presentCSAndAddCardFrom(buttonLabel: String, cardNumber: String? = nil, tapAdd: Bool = true) {
        let selectButton = app.staticTexts[buttonLabel]
        XCTAssertTrue(selectButton.waitForExistence(timeout: timeout))
        selectButton.tap()

        if tapAdd {
            app.staticTexts["+ Add"].waitForExistenceAndTap(timeout: timeout)
        }

        let numberField = app.textFields["Card number"]
        XCTAssertTrue(numberField.waitForExistence(timeout: timeout))

        try! fillCardData(app, cardNumber: cardNumber, postalEnabled: true)
        app.buttons["Save"].tap()

        let confirmButton = app.buttons["Confirm"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: timeout))
        confirmButton.tap()
        if let cardNumber {
            let last4 = String(cardNumber.suffix(4))
            dismissAlertView(alertBody: "Success: •••• \(last4), selected", alertTitle: "Complete", buttonToTap: "OK")
        } else {
            dismissAlertView(alertBody: "Success: •••• 4242, selected", alertTitle: "Complete", buttonToTap: "OK")
        }
    }
    func presentCSAndAddSepaFrom(buttonLabel: String, tapAdd: Bool = true) {
        let selectButton = app.staticTexts[buttonLabel]
        XCTAssertTrue(selectButton.waitForExistence(timeout: timeout))
        selectButton.tap()

        if tapAdd {
            app.staticTexts["+ Add"].waitForExistenceAndTap(timeout: timeout)
        }
        let sepaSelector = app.staticTexts["SEPA Debit"]
        XCTAssertTrue(sepaSelector.waitForExistenceAndTap(timeout: timeout))

        try! fillSepaData(app)

        app.buttons["Save"].tap()

        let confirmButton = app.buttons["Confirm"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: timeout))
        confirmButton.tap()
        dismissAlertView(alertBody: "Success: ••••3000, selected", alertTitle: "Complete", buttonToTap: "OK")
    }

    func removeFirstPaymentMethodInList(alertBody: String = "Visa •••• 4242", alertTitle: String = "Remove card?") {
        let editButton = app.buttons["Edit"].firstMatch
        editButton.tap()
        app.buttons["Remove"].waitForExistenceAndTap()
        dismissAlertView(alertBody: alertBody, alertTitle: alertTitle, buttonToTap: "Remove")
    }

    func dismissAlertView(alertBody: String, alertTitle: String, buttonToTap: String) {
        let alertText = app.staticTexts[alertBody]
        XCTAssertTrue(alertText.waitForExistence(timeout: timeout))

        let alert = app.alerts[alertTitle]
        alert.buttons[buttonToTap].tap()
    }
}
