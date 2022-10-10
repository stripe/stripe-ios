//
//  CardImageVerification_ExampleUITests.swift
//  CardImageVerification ExampleUITests
//
//  Created by Jaime Park on 11/17/21.
//

@testable @_spi(STP) import StripeCore
import XCTest

class CardImageVerification_ExampleUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        STPLocalizationUtils.overrideLanguage(to: "en")

        app = XCUIApplication()
        app.launchEnvironment = ["UITesting": "true"]
        app.launch()
    }

    override func tearDown() {
        STPLocalizationUtils.overrideLanguage(to: nil)
    }

    func testPrivacyLinkExists() throws {
        // Wait for the screen to load
        let verificationSheet = app.staticTexts["CardImageVerificationSheet"]
        XCTAssertTrue(verificationSheet.waitForExistence(timeout: 60.0))
        verificationSheet.tap()

        // Test that Amex card changes "CVC" -> "CVV" and allows 4 digits
        let iinField = app.textFields["424242"]
        XCTAssertTrue(iinField.waitForExistence(timeout: 10.0))
        iinField.tap()
        XCTAssertNoThrow(iinField.typeText("258393"))

        let last4Field = app.textFields["4242"]
        last4Field.tap()
        XCTAssertNoThrow(last4Field.typeText("1681"))

        let firstContinueButton = app.buttons["Continue"]
        firstContinueButton.tap()

        let secondContinueButton = app.buttons["Continue"]
        XCTAssertTrue(secondContinueButton.waitForExistence(timeout: 120.0))
        secondContinueButton.tap()

        let privacyLink = app.textViews.element(matching: .textView, identifier: "Privacy Link Text")
        XCTAssertTrue(privacyLink.waitForExistence(timeout: 60.0))

        if let privacyLinkText = privacyLink.value as? String {
            XCTAssertTrue(privacyLinkText == String.Localized.scanCardExpectedPrivacyLinkText()?.string)
        } else {
            XCTFail("Privacy Text Link is missing!")
        }
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
