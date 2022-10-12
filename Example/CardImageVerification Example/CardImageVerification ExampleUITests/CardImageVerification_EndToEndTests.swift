//
//  CardImageVerification_EndToEndTests.swift
//  CardImageVerification ExampleUITests
//
//  Created by Scott Grant on 9/25/22.
//

@testable @_spi(STP) import StripeCardScan
import XCTest

#if targetEnvironment(simulator)

extension XCUIElementQuery {
    func softMatching(substring: String) -> [XCUIElement] {
        return self.allElementsBoundByIndex.filter { $0.label.contains(substring) }
    }
}

#endif // targetEnvironment(simulator)

class CardImageVerification_EndToEndTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchEnvironment = ["UITesting": "true"]
        app.launch()
    }

    func testEndtoEnd() throws {
#if targetEnvironment(simulator)
        // Wait for the screen to load
        let verificationSheet = app.staticTexts["CardImageVerificationSheet"]
        XCTAssertTrue(verificationSheet.waitForExistence(timeout: 60))
        verificationSheet.tap()

        // Test that Amex card changes "CVC" -> "CVV" and allows 4 digits
        let iinField = app.textFields["424242"]
        XCTAssertTrue(iinField.waitForExistence(timeout: 10))
        iinField.tap()
        XCTAssertNoThrow(iinField.typeText("258393"))

        let last4Field = app.textFields["4242"]
        last4Field.tap()
        XCTAssertNoThrow(last4Field.typeText("1681"))

        let firstContinueButton = app.buttons["Card Input Continue Button"]
        XCTAssertTrue(firstContinueButton.waitForExistence(timeout: 10))
        firstContinueButton.tap()

        let secondContinueButton = app.buttons["Explaination Continue Button"]
        let secondContinueButtonExpectation = expectation(
            for: NSPredicate(format: "exists == true AND enabled == true"),
            evaluatedWith: secondContinueButton,
            handler: .none
        )

        wait(for: [secondContinueButtonExpectation], timeout: 120)

        secondContinueButton.tap()

        let okButton = app.buttons["OK"]
        let okButtonExpectation = expectation(
            for: NSPredicate(format: "exists == true AND enabled == true"),
            evaluatedWith: secondContinueButton,
            handler: .none
        )

        wait(for: [okButtonExpectation], timeout: 120)

        let titlePredicate = NSPredicate(format: "label CONTAINS[c] 'Verification Completed'")
        let titleLabel = app.staticTexts.matching(titlePredicate).element
        XCTAssertTrue(titleLabel.waitForExistence(timeout: 10))

        let subTitleLabelPredicate = NSPredicate(format: "label CONTAINS[c] 'design_mismatch'")
        let subTitleLabel = app.staticTexts.matching(subTitleLabelPredicate).element
        XCTAssertTrue(subTitleLabel.waitForExistence(timeout: 10))

        okButton.tap()
#endif // targetEnvironment(simulator)
    }
}
