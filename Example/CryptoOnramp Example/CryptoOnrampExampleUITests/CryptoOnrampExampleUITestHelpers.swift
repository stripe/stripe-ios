//
//  CryptoOnrampExampleUITestHelpers.swift
//  CryptoOnrampExampleUITests
//
//  Created by Michael Liberatore on 7/30/26.
//

import Foundation
import XCTest

extension CryptoOnrampExampleUITests {
    @MainActor
    func signUpAndAuthenticateNewUser(
        fullName: String,
        phoneNumber: String,
        countryCode: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let email = "crypto-onramp-ui-tests-\(UUID().uuidString.lowercased())@stripe.com"
        waitForLoadingToFinish(file: file, line: line)
        enterText(email, in: app.textFields["Enter email address"].firstMatch, file: file, line: line)
        enterText("testing1234", in: app.secureTextFields["Enter password"].firstMatch, file: file, line: line)
        app.buttons["Sign Up"].firstMatch.tap()

        let registrationLabel = app.staticTexts["Registration"].firstMatch
        XCTAssertTrue(
            registrationLabel.waitForExistence(timeout: .networkTimeout),
            "Registration screen should appear",
            file: file,
            line: line
        )
        waitForLoadingToFinish(file: file, line: line)
        dismissSavePasswordPromptIfPresent()
        enterText(fullName, in: app.textFields["Enter your full name"].firstMatch, file: file, line: line)
        enterText(phoneNumber, in: app.textFields["Enter phone number (e.g., +12125551234)"].firstMatch, file: file, line: line)

        if countryCode != "US" {
            let countryField = app.textFields["Country code"].firstMatch
            XCTAssertTrue(
                countryField.waitForExistence(timeout: .animationTimeout),
                "Registration country field should exist",
                file: file,
                line: line
            )
            countryField.tap()

            // Remove the default "US" value before entering the test country's code.
            countryField.typeText(
                String(repeating: XCUIKeyboardKey.delete.rawValue, count: 2) + countryCode
            )
        }
        dismissKeyboard()

        let registerButton = app.buttons["Register"].firstMatch
        XCTAssertTrue(registerButton.isEnabled, "Register button should be enabled", file: file, line: line)
        registerButton.tap()

        let authenticateButton = app.buttons["Authenticate"].firstMatch
        XCTAssertTrue(
            authenticateButton.waitForExistence(timeout: .networkTimeout),
            "Authenticate button should appear after registration",
            file: file,
            line: line
        )
        authenticateButton.tap()

        enterText("000000", in: app.textViews["Code field"].firstMatch, file: file, line: line)
    }

    func completeSuccessfulIdentityVerification(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let verifyIdentityButton = app.buttons["Verify Identity"].firstMatch
        XCTAssertTrue(
            verifyIdentityButton.waitForExistence(timeout: .networkTimeout),
            "Identity verification screen should appear",
            file: file,
            line: line
        )
        waitForLoadingToFinish(file: file, line: line)
        verifyIdentityButton.tap()

        let successOption = app.staticTexts["Verification success"].firstMatch
        XCTAssertTrue(
            successOption.waitForExistence(timeout: .networkTimeout),
            "Identity test-mode options should appear",
            file: file,
            line: line
        )
        successOption.tap()

        let submitButton = app.buttons["Submit"].firstMatch
        XCTAssertTrue(
            submitButton.isEnabled,
            "Identity verification Submit button should be enabled",
            file: file,
            line: line
        )
        submitButton.tap()
    }

    func addSolanaWallet(
        address: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let walletsLabel = app.staticTexts["Wallets"].firstMatch
        XCTAssertTrue(
            walletsLabel.waitForExistence(timeout: .networkTimeout),
            "Wallet selection screen should appear after successful identity verification",
            file: file,
            line: line
        )
        waitForLoadingToFinish(file: file, line: line)

        let addWalletButton = app.buttons["Add Wallet…"].firstMatch
        XCTAssertTrue(
            addWalletButton.waitForExistence(timeout: .animationTimeout),
            "Add Wallet button should appear for a new user",
            file: file,
            line: line
        )
        addWalletButton.tap()

        enterText(address, in: app.textFields["Enter wallet address"].firstMatch, file: file, line: line)
        let submitButton = app.buttons["Submit"].firstMatch
        XCTAssertTrue(submitButton.isEnabled, "Wallet Submit button should be enabled", file: file, line: line)
        submitButton.tap()

        XCTAssertTrue(
            app.staticTexts[address].firstMatch.waitForExistence(timeout: .networkTimeout),
            "The Solana wallet should appear",
            file: file,
            line: line
        )
    }

    func enterText(
        _ text: String,
        in element: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(element.waitForExistence(timeout: .animationTimeout), "Text field should exist", file: file, line: line)
        element.tap()
        element.typeText(text)
    }

    func waitForLoadingToFinish(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let loadingLabel = app.staticTexts["Loading…"].firstMatch
        XCTAssertTrue(
            loadingLabel.waitForNonExistence(timeout: .networkTimeout),
            "Loading indicator should disappear",
            file: file,
            line: line
        )
    }

    @MainActor
    func dismissSavePasswordPromptIfPresent() {
        // The prompt is owned by AuthenticationServicesAgent, so it must be handled as a system interruption.
        let interruptionMonitor = addUIInterruptionMonitor(withDescription: "Save Password") { alert in
            let notNowButton = alert.buttons["Not Now"].firstMatch
            guard notNowButton.exists else {
                return false
            }

            notNowButton.tap()
            return true
        }

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
        removeUIInterruptionMonitor(interruptionMonitor)
    }

    func dismissKeyboard() {
        let doneButton = app.toolbars.buttons["Done"].firstMatch
        if doneButton.waitForExistence(timeout: 1) {
            doneButton.tap()
        }
    }

    static func makeRandomUSPhoneNumber() -> String {
        "+1212555\(String(format: "%04d", Int.random(in: 0...9999)))"
    }

    static func makeRandomGreekPhoneNumber() -> String {
        "+3069\(String(format: "%08d", Int.random(in: 0...99_999_999)))"
    }
}

extension TimeInterval {

    /// Rough timeout value to use when awaiting an operation that relies on networking.
    static let networkTimeout: TimeInterval = 60

    /// Rough timeout value to use when awaiting an operation that performs an animation or transition.
    static let animationTimeout: TimeInterval = 5
}
