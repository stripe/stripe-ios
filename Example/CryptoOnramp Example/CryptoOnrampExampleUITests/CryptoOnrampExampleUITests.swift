//
//  CryptoOnrampExampleUITests.swift
//  CryptoOnrampExampleUITests
//
//  Created by Michael Liberatore on 12/1/25.
//

import XCTest

final class CryptoOnrampExampleUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchEnvironment = ["UITesting": "true"]
        app.launch()
    }

    /// Tests a happy-path flow from log in (existing account) to successful checkout, followed by re-authentication using seamless sign-in.
    @MainActor
    func testCryptoOnrampEndToEnd() throws {
        // Step 1: Enter email and password
        let emailField = app.textFields["Enter email addresses"].firstMatch
        XCTAssertTrue(emailField.waitForExistence(timeout: .networkTimeout), "Email field should exist")
        emailField.tap()
        emailField.typeText("onramptest@stripe.com")

        let passwordField = app.secureTextFields["Enter password"].firstMatch
        XCTAssertTrue(passwordField.exists, "Password field should exist")
        passwordField.tap()
        passwordField.typeText("testing1234")

        // Step 2: Tap Log In button
        let logInButton = app.buttons["Log In"].firstMatch
        XCTAssertTrue(logInButton.exists)
        logInButton.tap()

        // Step 3: Wait for OTP field and enter 000000. It will auto-submit.
        let otpField = app.textViews["Code field"].firstMatch
        XCTAssertTrue(otpField.waitForExistence(timeout: .networkTimeout), "OTP screen should appear")
        otpField.tap()
        otpField.typeText("000000")

        // Step 4: Wait for wallet selection screen and tap the Next button.
        // The Next button will be enabled once the user's wallets load and we auto-select the first wallet.
        let walletsLabel = app.staticTexts["Wallets"].firstMatch
        XCTAssertTrue(walletsLabel.waitForExistence(timeout: .networkTimeout), "Wallet selection screen should appear")

        let nextButton = app.buttons["Next"].firstMatch
        XCTAssertTrue(nextButton.wait(for: \.isEnabled, toEqual: true, timeout: .networkTimeout), "Next button should become enabled.")
        nextButton.tap()

        // Step 5: Wait for the payment screen, select the $3 button, and the most recent payment method, then tap Next.
        let paymentLabel = app.staticTexts["Payment"].firstMatch
        XCTAssertTrue(paymentLabel.waitForExistence(timeout: .networkTimeout), "Payment screen should appear")

        let threeButton = app.buttons["$3"].firstMatch
        XCTAssertTrue(threeButton.exists, "$3 button should exist")
        threeButton.tap()

        let selectAPaymentMethodButton = app.buttons["Select a payment method"].firstMatch
        XCTAssertTrue(selectAPaymentMethodButton.exists, "Select a payment method button should exist")
        selectAPaymentMethodButton.tap()

        let firstPaymentMethodButton = app.buttons.matching(identifier: "Card, Visa Credit •••• 4242").element(boundBy: 0)
        XCTAssertTrue(firstPaymentMethodButton.waitForExistence(timeout: .animationTimeout), "There should be at least one saved card in the account matching expected test account details.")
        firstPaymentMethodButton.tap()

        let continueButton = app.buttons["Continue"].firstMatch
        XCTAssertTrue(continueButton.exists, "Continue button should exist")
        continueButton.tap()

        // Step 6: Wait for the Review screen, and then tap the Confirm button.
        let reviewLabel = app.staticTexts["Review"].firstMatch
        XCTAssertTrue(reviewLabel.waitForExistence(timeout: .networkTimeout), "Review screen should appear")

        let confirmButton = app.buttons["Confirm"].firstMatch
        XCTAssertTrue(confirmButton.exists, "Confirm button should exist")
        confirmButton.tap()

        // Step 7: Wait for the Success screen, then log out.
        let successLabel = app.staticTexts["Purchase successful"].firstMatch
        XCTAssertTrue(successLabel.waitForExistence(timeout: .networkTimeout), "Success screen should appear")

        let userButton = app.images["person.fill"].firstMatch
        XCTAssertTrue(userButton.exists, "User toolbar button should exist")
        userButton.tap()

        let logOutMenuItem = app.buttons["Log out"].firstMatch
        XCTAssertTrue(logOutMenuItem.waitForExistence(timeout: .animationTimeout), "Log out menu item should exist")
        logOutMenuItem.tap()

        // Step 8: Authenticate again using seamless sign-in (no OTP, stored auth token from prior login).
        let seamlessSignInLabel = app.staticTexts["Continue as onramptest@stripe.com?"]
        XCTAssertTrue(seamlessSignInLabel.waitForExistence(timeout: .networkTimeout), "Seamless sign-in label should exist")

        let seamlessSignInButton = app.buttons["Continue"].firstMatch
        XCTAssertTrue(seamlessSignInButton.exists, "Seamless sign-in (Continue) button should exist")
        seamlessSignInButton.tap()

        // Step 9: We should skip right to the wallet selection screen without the need to enter an OTP code.
        let walletsLabel2 = app.staticTexts["Wallets"].firstMatch
        XCTAssertTrue(walletsLabel2.waitForExistence(timeout: .networkTimeout), "Wallet selection screen should appear")
    }
}

private extension TimeInterval {
    /// Rough timeout value to use when awaiting an operation that relies on networking.
    static let networkTimeout: TimeInterval = 60

    /// Rough timeout value to use when awaiting an operation that performs an animation or transition.
    static let animationTimeout: TimeInterval = 5
}
