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
}
