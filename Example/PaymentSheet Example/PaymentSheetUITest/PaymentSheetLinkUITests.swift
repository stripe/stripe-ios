//
//  PaymentSheetLinkUITests.swift
//  PaymentSheet Example
//
//  Created by David Estes on 2/11/26.
//


import XCTest

class PaymentSheetLinkUITests: PaymentSheetUITestCase {
    // MARK: PaymentSheet Link inline signup

    // Tests the #1 flow in PaymentSheet where the merchant disable saved payment methods and first time Link user
    func testLinkPaymentSheet_disabledSPM_firstTimeLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .guest
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm

        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        fillLinkAndPay(mode: .checkbox)
    }

    // Tests the #2 flow in PaymentSheet where the merchant disable saved payment methods and returning Link user
    func testLinkPaymentSheet_disabledSPM_returningLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .guest
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.defaultBillingAddress = .on // the email on the default billings details is signed up for Link

        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        // Close the Link sheet
        let closeButton = app.buttons["LinkVerificationCloseButton"]
        closeButton.waitForExistenceAndTap()

        // Ensure Link wallet button is shown in SPM view
        XCTAssertTrue(app.buttons["pay_with_link_button"].waitForExistence(timeout: 5.0))
        assertLinkInlineSignupNotShown()

        // Disable postal code input, it is pre-filled by `defaultBillingAddress`
        try! fillCardData(app, postalEnabled: false)
        app.buttons["Pay $50.99"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
    }

    // Tests the #3 flow in PaymentSheet where the merchant enables saved payment methods, buyer has no SPMs and first time Link user
    func testLinkPaymentSheet_enabledSPM_noSPMs_firstTimeLinkUser() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm

        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        fillLinkAndPay(mode: .fieldConsent)
    }

    // Tests the #4 flow in PaymentSheet where the merchant enables saved payment methods, buyer has no SPMs and returning Link user
    func testLinkPaymentSheet_enabledSPM_noSPMs_returningLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.defaultBillingAddress = .on // the email on the default billings details is signed up for Link

        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        // Close the Link sheet
        let closeButton = app.buttons["LinkVerificationCloseButton"]
        closeButton.waitForExistenceAndTap()

        // Ensure Link wallet button is shown in SPM view
        XCTAssertTrue(app.buttons["pay_with_link_button"].waitForExistence(timeout: 5.0))
        assertLinkInlineSignupNotShown()

        // Disable postal code input, it is pre-filled by `defaultBillingAddress`
        try! fillCardData(app, postalEnabled: false)
        app.buttons["Pay $50.99"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
    }

    // Tests Native Link with a returning user, 2FA prompt shows first
    func testLinkPaymentSheet_native_enabledSPM_noSPMs_returningLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.defaultBillingAddress = .on // the email on the default billings details is signed up for Link

        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        let codeField = app.textViews["Code field"]
        _ = codeField.waitForExistence(timeout: 5.0)
        codeField.typeText("000000")
        let pwlController = app.otherElements["Stripe.Link.PayWithLinkViewController"]
        let payButton = pwlController.buttons["Pay $50.99"]
        _ = payButton.waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
    }

    // Tests Native Link in Flow Controller with a returning user
    func testLinkPaymentSheetFC_native_enabledSPM_noSPMs_returningLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.uiStyle = .flowController
        settings.defaultBillingAddress = .on // the email on the default billings details is signed up for Link

        loadPlayground(app, settings)

        app.buttons["Payment method"].waitForExistenceAndTap()
        app.buttons["Link"].waitForExistenceAndTap()
        app.buttons["Confirm"].waitForExistenceAndTap()
        let codeField = app.textViews["Code field"]
        _ = codeField.waitForExistence(timeout: 5.0)
        codeField.typeText("000000")
        let pwlController = app.otherElements["Stripe.Link.PayWithLinkViewController"]
        let payButton = pwlController.buttons["Pay $50.99"]
        _ = payButton.waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
    }

    // Tests Native Link with confirmation tokens - client-side confirmation
    func testLinkPaymentSheet_native_ConfirmationToken_ClientSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.integrationType = .deferred_csc
        settings.confirmationMode = .confirmationToken
        settings.defaultBillingAddress = .on // the email on the default billings details is signed up for Link

        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        let codeField = app.textViews["Code field"]
        _ = codeField.waitForExistence(timeout: 5.0)
        codeField.typeText("000000")
        let pwlController = app.otherElements["Stripe.Link.PayWithLinkViewController"]
        let payButton = pwlController.buttons["Pay $50.99"]
        _ = payButton.waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
    }

    // Tests Native Link with confirmation tokens - server-side confirmation
    func testLinkPaymentSheet_native_ConfirmationToken_ServerSideConfirmation() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.integrationType = .deferred_ssc
        settings.confirmationMode = .confirmationToken
        settings.defaultBillingAddress = .on // the email on the default billings details is signed up for Link

        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        let codeField = app.textViews["Code field"]
        _ = codeField.waitForExistence(timeout: 5.0)
        codeField.typeText("000000")
        let pwlController = app.otherElements["Stripe.Link.PayWithLinkViewController"]
        let payButton = pwlController.buttons["Pay $50.99"]
        _ = payButton.waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
    }

    // Tests the #5 flow in PaymentSheet where the merchant enables saved payment methods, buyer has SPMs and first time Link user
    func testLinkPaymentSheet_enabledSPM_hasSPMs_firstTimeLinkUser_legacy() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.customerKeyType = .legacy
        _testLinkPaymentSheet_enabledSPM_hasSPMs_firstTimeLinkUser(settings: settings)
    }
    func testLinkPaymentSheet_enabledSPM_hasSPMs_firstTimeLinkUser_customerSession() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.customerKeyType = .customerSession
        _testLinkPaymentSheet_enabledSPM_hasSPMs_firstTimeLinkUser(settings: settings)
    }
    func _testLinkPaymentSheet_enabledSPM_hasSPMs_firstTimeLinkUser(settings: PaymentSheetTestPlaygroundSettings) {
        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        // Begin by saving a card for this new user who is not signed up for Link
        try! fillCardData(app)

        var saveThisCardToggle = app.switches["Save payment details to Example, Inc. for future purchases"]
        XCTAssertFalse(saveThisCardToggle.isSelected)
        saveThisCardToggle.tap()
        XCTAssertTrue(saveThisCardToggle.isSelected)

        app.buttons["Pay $50.99"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))

        // reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        // Ensure Link wallet button is shown in SPM view
        XCTAssertTrue(app.buttons["pay_with_link_button"].waitForExistence(timeout: 5.0))
        let addCardButton = app.buttons["+ Add"]
        XCTAssertTrue(addCardButton.waitForExistence(timeout: 4.0))
        addCardButton.tap()

        saveThisCardToggle = app.switches["Save payment details to Example, Inc. for future purchases"]
        XCTAssertFalse(saveThisCardToggle.isSelected)
        saveThisCardToggle.tap()
        XCTAssertTrue(saveThisCardToggle.isSelected)

        fillLinkAndPay(mode: .fieldConsent, cardNumber: "5555555555554444")

        // reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        // Ensure both PMs exist
        XCTAssertTrue(app.staticTexts["•••• 4242"].waitForExistence(timeout: 5.0))
        XCTAssertTrue(app.staticTexts["•••• 4444"].waitForExistence(timeout: 5.0))
    }

    // Tests the #6 flow in PaymentSheet where the merchant enables saved payment methods, buyer has SPMs and returning Link user
    func testLinkPaymentSheet_enabledSPM_hasSPMs_returningLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.defaultBillingAddress = .on // the email on the default billings details is signed up for Link

        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        // Close the Link sheet
        let closeButton = app.buttons["LinkVerificationCloseButton"]
        closeButton.waitForExistenceAndTap()

        // Setup a saved card to simulate having saved payment methods
        try! fillCardData(app, postalEnabled: false) // postal pre-filled by default billing address

        let saveThisCardToggle = app.switches["Save payment details to Example, Inc. for future purchases"]
        XCTAssertFalse(saveThisCardToggle.isSelected)
        saveThisCardToggle.tap()
        XCTAssertTrue(saveThisCardToggle.isSelected)

        app.buttons["Pay $50.99"].tap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))

        // reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        // Close the Link sheet
        closeButton.waitForExistenceAndTap()

        // Ensure Link wallet button is shown in SPM view
        XCTAssertTrue(app.buttons["pay_with_link_button"].waitForExistence(timeout: 5.0))
        let addCardButton = app.buttons["+ Add"]
        XCTAssertTrue(addCardButton.waitForExistence(timeout: 4.0))
        addCardButton.tap()
        assertLinkInlineSignupNotShown()
    }

    // MARK: PaymentSheet.FlowController Link inline signup

    // Tests the #7 flow in PaymentSheet.FlowController where the merchant disables Apple Pay and saved payment methods and first time Link user
    // Seealso: testLinkOnlyFlowController for testing wallet button behavior in this flow
    func testLinkPaymentSheetFlow_disabledApplePay_disabledSPM_firstTimeLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .flowController
        settings.customerMode = .guest
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.applePayEnabled = .off

        loadPlayground(app, settings)
        app.buttons["Payment method"].waitForExistenceAndTap()
        fillLinkAndPay(mode: .checkbox, uiStyle: .flowController)
    }

    // Tests the #8 flow in PaymentSheet.FlowController where the merchant disables Apple Pay and saved payment methods and returning Link user
    func testLinkPaymentSheetFlow_disabledApplePay_disabledSPM_returningLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .flowController
        settings.customerMode = .guest
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.applePayEnabled = .off
        settings.defaultBillingAddress = .on // the email on the default billings details is signed up for Link

        loadPlayground(app, settings)
        app.buttons["Payment method"].waitForExistenceAndTap()

        // Ensure Link wallet button is shown
        XCTAssertTrue(app.buttons["pay_with_link_button"].waitForExistence(timeout: 5.0))
        assertLinkInlineSignupNotShown()

        // Disable postal code input, it is pre-filled by `defaultBillingAddress`
        try! fillCardData(app, postalEnabled: false)
        app.buttons["Continue"].tap()
        app.buttons["Confirm"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
    }

    // Tests the #9 flow in PaymentSheet.FlowController where the merchant disables Apple Pay and enables saved payment methods and first time Link user
    func testLinkPaymentSheetFlow_disabledApplePay_enabledSPM_firstTimeLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .flowController
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.applePayEnabled = .off

        loadPlayground(app, settings)
        app.buttons["Payment method"].waitForExistenceAndTap()
        fillLinkAndPay(mode: .fieldConsent, uiStyle: .flowController)
    }

    // Tests the #10 flow in PaymentSheet.FlowController where the merchant disables Apple Pay and enables saved payment methods and returning Link user
    func testLinkPaymentSheetFlow_disabledApplePay_enabledSPM_returningLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .flowController
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.applePayEnabled = .off
        settings.defaultBillingAddress = .on // the email on the default billings details is signed up for Link

        loadPlayground(app, settings)
        app.buttons["Payment method"].waitForExistenceAndTap()

        // Ensure Link wallet button is shown
        XCTAssertTrue(app.buttons["pay_with_link_button"].waitForExistence(timeout: 5.0))
        assertLinkInlineSignupNotShown()

        // Disable postal code input, it is pre-filled by `defaultBillingAddress`
        try! fillCardData(app, postalEnabled: false)
        app.buttons["Continue"].tap()
        app.buttons["Confirm"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
    }

    // Tests the #11 flow in PaymentSheet.FlowController where the merchant disables Apple Pay and enables saved payment methods and first time Link user
    func testLinkPaymentSheetFlow_disabledApplePay_enabledSPM_hasSPMs_firstTimeLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .flowController
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.applePayEnabled = .off

        loadPlayground(app, settings)
        app.buttons["Payment method"].waitForExistenceAndTap()
        // Begin by saving a card for this new user who is not signed up for Link
        try! fillCardData(app)

        var saveThisCardToggle = app.switches["Save payment details to Example, Inc. for future purchases"]
        XCTAssertFalse(saveThisCardToggle.isSelected)
        saveThisCardToggle.tap()
        XCTAssertTrue(saveThisCardToggle.isSelected)

        app.buttons["Continue"].tap()
        app.buttons["Confirm"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))

        // reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Payment method"].waitForExistenceAndTap()
        // Ensure Link wallet button is NOT shown in SPM view
        XCTAssertFalse(app.buttons["pay_with_link_button"].waitForExistence(timeout: 5.0))
        let addCardButton = app.buttons["+ Add"]
        XCTAssertTrue(addCardButton.waitForExistence(timeout: 4.0))
        addCardButton.tap()
        saveThisCardToggle = app.switches["Save payment details to Example, Inc. for future purchases"]
        XCTAssertFalse(saveThisCardToggle.isSelected)
        saveThisCardToggle.tap()
        XCTAssertTrue(saveThisCardToggle.isSelected)
        fillLinkAndPay(mode: .fieldConsent, uiStyle: .flowController, showLinkWalletButton: false)
    }

    // Tests the #11.1 flow in PaymentSheet.FlowController where the merchant enables Apple Pay and enables saved payment methods and first time Link user
    func testLinkPaymentSheetFlow_enabledApplePay_enabledSPM_hasSPMs_firstTimeLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .flowController
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.applePayEnabled = .on

        loadPlayground(app, settings)
        app.buttons["Payment method"].waitForExistenceAndTap()
        XCTAssertTrue(app.buttons["+ Add"].waitForExistenceAndTap())
        // Begin by saving a card for this new user who is not signed up for Link
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 5))
        try! fillCardData(app)
        app.buttons["Continue"].tap()
        app.buttons["Confirm"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))

        // reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Payment method"].waitForExistenceAndTap()
        // Ensure Link wallet button is NOT shown in SPM view
        XCTAssertFalse(app.buttons["pay_with_link_button"].waitForExistence(timeout: 5.0))
        let addCardButton = app.buttons["+ Add"]
        XCTAssertTrue(addCardButton.waitForExistence(timeout: 4.0))
        addCardButton.tap()
        fillLinkAndPay(mode: .fieldConsent, uiStyle: .flowController, showLinkWalletButton: false)
    }

    // Tests the #12 flow in PaymentSheet.FlowController where the merchant disables Apple Pay and enables saved payment methods and returning Link user
    func testLinkPaymentSheetFlow_disabledApplePay_enabledSPM_hasSPMs_returningLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .flowController
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.applePayEnabled = .off
        settings.defaultBillingAddress = .on // the email on the default billings details is signed up for Link

        loadPlayground(app, settings)
        app.buttons["Payment method"].waitForExistenceAndTap()

        // Setup a saved card to simulate having saved payment methods
        try! fillCardData(app, postalEnabled: false) // postal pre-filled by default billing address

        // toggle save this card on
        let saveThisCardToggle = app.switches["Save payment details to Example, Inc. for future purchases"]
        saveThisCardToggle.tap()
        XCTAssertTrue(saveThisCardToggle.isSelected)

        app.buttons["Continue"].tap()
        app.buttons["Confirm"].waitForExistenceAndTap()
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))

        // reload w/ same customer
        reload(app, settings: settings)
        app.buttons["Payment method"].waitForExistenceAndTap()

        // Ensure Link wallet button is NOT shown in SPM view
        XCTAssertFalse(app.buttons["pay_with_link_button"].waitForExistence(timeout: 5.0))
        app.buttons["+ Add"].waitForExistenceAndTap()
        assertLinkInlineSignupNotShown() // Link should not be shown in this flow
    }

    // Tests the #12.1 flow in PaymentSheet.FlowController where the merchant enables Apple Pay and enables saved payment methods and returning Link user
    func testLinkPaymentSheetFlow_enablesApplePay_enabledSPM_hasSPMs_returningLinkUser() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .flowController
        settings.customerMode = .new
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.applePayEnabled = .on
        settings.defaultBillingAddress = .on // the email on the default billings details is signed up for Link

        loadPlayground(app, settings)
        app.buttons["Payment method"].waitForExistenceAndTap()
        // Ensure Link wallet button is NOT shown in SPM view
        XCTAssertFalse(app.buttons["pay_with_link_button"].waitForExistence(timeout: 5.0))
        app.buttons["+ Add"].waitForExistenceAndTap()
        assertLinkInlineSignupNotShown() // Link should not be shown in this flow
    }

    func testLinkPaymentSheetFlowController_returnsCardPaymentOptionDisplayDataForLinkInlineSignup() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.uiStyle = .flowController
        settings.customerMode = .guest
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.applePayEnabled = .off

        loadPlayground(app, settings)
        app.buttons["Payment method"].waitForExistenceAndTap()

        fillLinkCardAndSignup(mode: .checkbox)

        // Assert that card is the returned payment method type
        app.buttons["Continue"].tap()
        let paymentMethodButton = app.buttons["Payment method"]
        // Sometimes this button takes a short bit to update so we give a second of allowance
        let labelExpectation = expectation(
            for: NSPredicate(format: "label == %@", "•••• 4242, card, 12345, US"),
            evaluatedWith: paymentMethodButton
        )
        wait(for: [labelExpectation], timeout: 5)
    }

    func testLinkInlineSignup_gb() throws {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .guest
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.userOverrideCountry = .GB

        loadPlayground(app, settings)

        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        try fillCardData(app)

        app.switches["Save my info for faster checkout with Link"].tap()

        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("mobile-payments-sdk-ci+\(UUID())@stripe.com")

        let phoneField = app.textFields["Phone number"]
        // Phone field appears after the network call finishes. We want to wait for it to appear.
        XCTAssert(phoneField.waitForExistence(timeout: 10))
        phoneField.tap()
        phoneField.typeText("3105551234")

        // The name field is required for non-US countries
        let nameField = app.textFields["Full name"]
        XCTAssert(nameField.waitForExistence(timeout: 10))
        nameField.tap()
        nameField.typeText("Jane Doe")

        // Pay!
        app.buttons["Pay $50.99"].tap()

        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
    }

    func testLinkInlineSignup_deferred() {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.layout = .horizontal
        settings.customerMode = .guest
        settings.apmsEnabled = .on
        settings.linkPassthroughMode = .pm
        settings.integrationType = .deferred_ssc
        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()
        fillLinkAndPay(mode: .checkbox)
    }

    // MARK: Link bank payments

    // Disabled
    func _testLinkCardBrand() {
        _testInstantDebits(mode: .payment, useLinkCardBrand: true)
    }

    // Disabled
    func _testLinkCardBrand_flowController() {
        _testInstantDebits(mode: .payment, useLinkCardBrand: true, uiStyle: .flowController)
    }

    // MARK: Native Link bank payments

    func testBankPaymentInNativeLinkInPaymentMethodMode() {
        testBankPaymentInNativeLink(passthroughMode: false)
    }

    func testBankPaymentInNativeLinkInPassthroughMode() {
        testBankPaymentInNativeLink(passthroughMode: true)
    }

    private func testBankPaymentInNativeLink(passthroughMode: Bool) {
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.customerMode = .guest
        settings.linkPassthroughMode = passthroughMode ? .passthrough : .pm
        settings.defaultBillingAddress = .customEmail
        settings.customEmail = "foo@bar.com"
        settings.apmsEnabled = .off
        settings.supportedPaymentMethods = passthroughMode ? "card" : "card,link"
        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        // Enter OTC in dialog
        let textField = app.textViews["Code field"]
        XCTAssertTrue(textField.waitForExistence(timeout: 10.0))
        textField.typeText("000000")

        app.otherElements["Stripe.Link.PaymentMethodPicker"].waitForExistenceAndTap(timeout: 10)

        let bankRow = app
            .otherElements
            .matching(NSPredicate(format: "label CONTAINS 'Success'"))
            .firstMatch
        XCTAssertTrue(bankRow.waitForExistenceAndTap())

        app.buttons
            .matching(identifier: "Pay $50.99")
            .matching(NSPredicate(format: "isEnabled == true"))
            .firstMatch
            .waitForExistenceAndTap()

        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
    }

    // MARK: Native Link payments with billing details collection

    func testBillingDetailsCollectionInNativeLinkInPassthroughModeForNewUser() {
        testBillingDetailsCollectionInNativeLinkForNewUser(passthroughMode: true)
    }

    func testBillingDetailsCollectionInNativeLinkInPaymentMethodModeForNewUser() {
        testBillingDetailsCollectionInNativeLinkForNewUser(passthroughMode: false)
    }

    func testBillingDetailsCollectionInNativeLinkInPassthroughModeForExistingUser() {
        testBillingDetailsCollectionInNativeLinkForExistingUser(passthroughMode: true)
    }

    func testBillingDetailsCollectionInNativeLinkInPaymentMethodModeForExistingUser() {
        testBillingDetailsCollectionInNativeLinkForExistingUser(passthroughMode: false)
    }

    private func testBillingDetailsCollectionInNativeLinkForNewUser(passthroughMode: Bool) {
        let email = "billing_details_test+\(UUID().uuidString)@link.com"
        let cvc = "1234"

        let settings = createLinkPlaygroundSettings(
            passthroughMode: passthroughMode,
            collectBillingDetails: true
        )
        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        // Sign up and add a payment method with billing details
        signUpFor(app, email: email)
        fillOutLinkCardData(app, cardNumber: "378282246310005", cvc: cvc, includingBillingDetails: true)

        payLink(app)
        assertLinkPaymentSuccess(app)
    }

    private func testBillingDetailsCollectionInNativeLinkForExistingUser(passthroughMode: Bool) {
        let email = "billing_details_test+\(UUID().uuidString)@link.com"
        let cvc = "1234"

        let settings = createLinkPlaygroundSettings(
            passthroughMode: passthroughMode,
            collectBillingDetails: false
        )
        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        // Sign up and add a payment method without billing details
        signUpFor(app, email: email)
        fillOutLinkCardData(app, cardNumber: "378282246310005", cvc: cvc, includingBillingDetails: false)
        payLink(app)
        assertLinkPaymentSuccess(app)

        // Now request billing details
        let settingsWithBillingDetails = createLinkPlaygroundSettings(
            passthroughMode: passthroughMode,
            collectBillingDetails: true
        )
        loadPlayground(app, settingsWithBillingDetails)
        app.buttons["Present PaymentSheet"].waitForExistenceAndTap()

        // Pay again
        logInToLink(app, email: email)

        // Enter CVC if requested
        let cvcField = app.textFields["CVC"]
        if cvcField.waitForExistence(timeout: 5) {
            cvcField.tap()
            cvcField.typeText(cvc)
        }

        payLink(app)

        // Fill out missing details
        XCTAssertTrue(app.staticTexts["Confirm payment details"].waitForExistence(timeout: 5))
        fillOutBillingDetails(app)

        payLink(app)
        assertLinkPaymentSuccess(app)
    }

    // MARK: Link test helpers

    private enum LinkMode {
        case checkbox
        case fieldConsent
    }

    private func fillLinkAndPay(mode: LinkMode,
                                uiStyle: PaymentSheetTestPlaygroundSettings.UIStyle = .paymentSheet,
                                showLinkWalletButton: Bool = true,
                                cardNumber: String? = nil) {

        fillLinkCardAndSignup(mode: mode, showLinkWalletButton: showLinkWalletButton, cardNumber: cardNumber)

        // Pay!
        switch uiStyle {
        case .paymentSheet:
            app.buttons["Pay $50.99"].tap()
        case .flowController:
            app.buttons["Continue"].tap()
            app.buttons["Confirm"].waitForExistenceAndTap()
        case .embedded:
            // TODO(porter) Fill in embedded UI test steps
            break
        }
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
        // Roundabout way to validate that signup completed successfully
        let signupCompleteAnalytic = analyticsLog.first { payload in
            payload["event"] as? String == "link.signup.complete"
        }
        XCTAssertNotNil(signupCompleteAnalytic)
    }

    private func fillLinkCardAndSignup(
        mode: LinkMode,
        showLinkWalletButton: Bool = true,
        cardNumber: String? = nil
    ) {
        try! fillCardData(app, cardNumber: cardNumber)

        if showLinkWalletButton {
            // Confirm Link wallet button is visible
            XCTAssertTrue(app.buttons["pay_with_link_button"].exists)
        }

        if mode == .checkbox {
            app.switches["Save my info for faster checkout with Link"].tap()
        }

        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 10))
        emailField.tap()
        emailField.typeText("mobile-payments-sdk-ci+\(UUID())@stripe.com")

        let phoneField = app.textFields["Phone number"]
        XCTAssert(phoneField.waitForExistence(timeout: 10))
        phoneField.tap()
        phoneField.typeText("3105551234")

        // The name field is only required for non-US countries. Only fill it out if it exists.
        let nameField = app.textFields["Full name"]
        if nameField.exists {
            nameField.tap()
            nameField.typeText("Jane Done")
        }
    }

    private func assertLinkInlineSignupNotShown() {
        // Ensure checkbox is not shown for checkbox mode
        XCTAssertFalse(app.switches["Save my info for faster checkout with Link"].waitForExistence(timeout: 2))
        // Ensure email is not shown for field consent mode
        XCTAssertFalse(app.textFields["Email"].waitForExistence(timeout: 3))
    }

//    TODO: This is disabled until the Link team adds some hooks for testing.
//    func testLinkWebFlow() throws {
//        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
//        settings.layout = .horizontal
//        settings.customerMode = .guest
//        settings.linkMode = .on
//
//        loadPlayground(app, settings)
//
//        app.buttons["Present PaymentSheet"].tap()
//
//        app.buttons["Pay with Link"].forceTapWhenHittableInTestCase(self)
//
//        // Allow link.com to sign in
//        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
//        springboard.buttons["Continue"].forceTapWhenHittableInTestCase(self)
//
//        let emailField = app.webViews.textFields.firstMatch
//        emailField.forceTapWhenHittableInTestCase(self)
//        emailField.typeText("test@example.com")
//
//        let verificationCodeField = app.webViews.staticTexts["•"]
//        verificationCodeField.forceTapWhenHittableInTestCase(self)
//        verificationCodeField.typeText("000000")
//
//        // Pay!
//        app.webViews.buttons["Pay $50.99"].tap()
//
//        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 10.0))
//    }
}