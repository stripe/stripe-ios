//
//  FCLiteUITests.swift
//  PaymentSheetUITest
//
//  Created by Mat Schmid on 2025-03-27.
//

import XCTest

// FC Lite UI tests should be kept barebones.
// By nature of this flow being a webview, the content is prone to changes.
class FCLiteUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        app = XCUIApplication()
    }

    func testFCLiteInitialPaneAndDismiss() throws {
        // Setup playground
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.fcLiteEnabled = .on
        settings.apmsEnabled = .off
        settings.supportedPaymentMethods = "us_bank_account"
        settings.layout = .vertical
        settings.defaultBillingAddress = .randomEmail

        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].tap()

        // Launch into FC Lite
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistenceAndTap())

        // Check that we're either on the consent pane or the institution picker pane.
        // The FC Lite flow should usually open to the consent pane,
        // but there are niche scenarios where we open to the institution picker pane.
        let agreeButtonPredicate = NSPredicate(format: "label CONTAINS[cd] 'Agree'") // Consent pane
        let institutionButtonPredicate = NSPredicate(format: "label CONTAINS[cd] 'Institution'") // Institution picker pane
        let agreeButtonOrInstitutionButtonPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [agreeButtonPredicate, institutionButtonPredicate])
        let agreeButtonOrInstitutionButton = app.webViews.firstMatch.buttons.containing(agreeButtonOrInstitutionButtonPredicate).firstMatch
        // Webviews can take a while to load.
        XCTAssertTrue(agreeButtonOrInstitutionButton.waitForExistence(timeout: 30.0))

        // Dismiss the flow
        let closeButtonPredicate = NSPredicate(format: "label CONTAINS[cd] 'Close'")
        let closeButton = app.webViews.firstMatch.buttons.containing(closeButtonPredicate).firstMatch
        XCTAssertTrue(closeButton.waitForExistenceAndTap(timeout: 5.0))

        // Ensure the flow is dismissed by checking the continue button.
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5.0))
        XCTAssertTrue(continueButton.isHittable)
    }

    func testFCLiteUSBankAccountFlow() throws {
        // Setup playground
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.fcLiteEnabled = .on
        settings.apmsEnabled = .off
        settings.supportedPaymentMethods = "us_bank_account"
        settings.layout = .vertical
        settings.defaultBillingAddress = .randomEmail

        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].tap()

        // Launch into FC Lite
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistenceAndTap())

        // Find and tap "Manually verify instead" button
        let manuallyVerifyButtonPredicate = NSPredicate(format: "label CONTAINS[cd] 'Manually verify instead'")
        let manuallyVerifyButton = app.webViews.firstMatch.buttons.containing(manuallyVerifyButtonPredicate).firstMatch
        XCTAssertTrue(manuallyVerifyButton.waitForExistenceAndTap(timeout: 10.0))

        // Tap "Autofill" button
        let autofillButtonPredicate = NSPredicate(format: "label CONTAINS[cd] 'Autofill'")
        let autofillButton = app.webViews.firstMatch.buttons.containing(autofillButtonPredicate).firstMatch
        XCTAssertTrue(autofillButton.waitForExistenceAndTap(timeout: 5.0))

        // Tap "Save with Link" button (tapPrimaryButton handles keyboard dismissal if needed)
        let saveWithLinkButtonPredicate = NSPredicate(format: "label CONTAINS[cd] 'Save with Link'")
        let saveWithLinkButton = app.webViews.firstMatch.buttons.containing(saveWithLinkButtonPredicate).firstMatch
        XCTAssertTrue(saveWithLinkButton.waitForExistence(timeout: 5.0))
        tapPrimaryButton()

        // Tap "Done" button
        let doneButtonPredicate = NSPredicate(format: "label CONTAINS[cd] 'Done'")
        let doneButton = app.webViews.firstMatch.buttons.containing(doneButtonPredicate).firstMatch
        XCTAssertTrue(doneButton.waitForExistenceAndTap(timeout: 5.0))

        // Tap the Pay button on MPE
        let payButton = app.buttons["Pay $50.99"]
        XCTAssertTrue(payButton.waitForExistenceAndTap(timeout: 5.0))

        // Ensure the payment succeeded
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 5.0))
    }

    func testFCLiteInstantDebitsFlow() throws {
        // Setup playground
        var settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        settings.fcLiteEnabled = .on
        settings.apmsEnabled = .off
        settings.supportedPaymentMethods = "link"
        settings.layout = .vertical
        settings.defaultBillingAddress = .randomEmail

        loadPlayground(app, settings)
        app.buttons["Present PaymentSheet"].tap()

        // Launch into FC Lite
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistenceAndTap())

        // Agree and continue
        let agreeButtonPredicate = NSPredicate(format: "label CONTAINS[cd] 'Agree'") // Consent pane
        let agreeButton = app.webViews.firstMatch.buttons.containing(agreeButtonPredicate).firstMatch
        XCTAssertTrue(agreeButton.waitForExistence(timeout: 10.0))
        tapPrimaryButton()

        // Continue with Link
        let continueWithLinkButtonPredicate = NSPredicate(format: "label CONTAINS[cd] 'Continue with Link'") // Link signup pane
        let continueWithLinkButton = app.webViews.firstMatch.buttons.containing(continueWithLinkButtonPredicate).firstMatch
        XCTAssertTrue(continueWithLinkButton.waitForExistence(timeout: 5.0))
        tapPrimaryButton()

        // Payment Success bank
        let paymentSuccessBankButtonPredicate = NSPredicate(format: "label CONTAINS[cd] 'Payment Success'") // Institution Picker
        let paymentSuccessBankButton = app.webViews.firstMatch.buttons.containing(paymentSuccessBankButtonPredicate).firstMatch
        XCTAssertTrue(paymentSuccessBankButton.waitForExistence(timeout: 5.0))
        app.webViews.firstMatch.swipeUp() // Make sure the button is in view
        Thread.sleep(forTimeInterval: 0.5) // Wait after swipe before tapping
        paymentSuccessBankButton.tap()

        // Connect account - wait for button to appear, then tap via coordinate
        let connectAccountButtonPredicate = NSPredicate(format: "label CONTAINS[cd] 'Connect account'") // Account Picker
        let connectAccountButton = app.webViews.firstMatch.buttons.containing(connectAccountButtonPredicate).firstMatch
        XCTAssertTrue(connectAccountButton.waitForExistence(timeout: 10.0))
        tapPrimaryButton()

        // Tap "Done" button
        let doneButtonPredicate = NSPredicate(format: "label CONTAINS[cd] 'Done'")
        let doneButton = app.webViews.firstMatch.buttons.containing(doneButtonPredicate).firstMatch
        XCTAssertTrue(doneButton.waitForExistence(timeout: 5.0))
        tapPrimaryButton()

        // Tap the Pay button on MPE
        let payButton = app.buttons["Pay $50.99"]
        XCTAssertTrue(payButton.waitForExistenceAndTap(timeout: 5.0))

        // Ensure the payment succeeded
        XCTAssertTrue(app.staticTexts["Success!"].waitForExistence(timeout: 5.0))
    }

    /// Taps the primary CTA button at the bottom of the FC webview.
    /// Webview accessibility frames are unreliable, so we tap at a fixed coordinate.
    /// If the keyboard is open, it dismisses it first.
    private func tapPrimaryButton() {
        // Dismiss keyboard if open - check for "Done" (iOS 18) or checkmark button (iOS 26)
        let keyboardDoneButton = app.toolbars.buttons["Done"]

        if keyboardDoneButton.waitForExistence(timeout: 1.0) {
            keyboardDoneButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Primary button is at the bottom center of the webview (roughly 90% down, centered)
        app.webViews.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9)).tap()
    }
}
