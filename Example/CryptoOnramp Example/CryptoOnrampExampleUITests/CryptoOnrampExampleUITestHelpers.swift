//
//  CryptoOnrampExampleUITestHelpers.swift
//  CryptoOnrampExampleUITests
//
//  Created by Michael Liberatore on 7/30/26.
//

import Foundation

@_spi(CryptoOnrampAlpha)
import StripeCryptoOnramp

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
        enterText(email, inTextField: "Enter email address", file: file, line: line)
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
        enterText(fullName, inTextField: "Enter your full name", file: file, line: line)
        enterText(phoneNumber, inTextField: "Enter phone number (e.g., +12125551234)", file: file, line: line)

        if countryCode != "US" {
            // Replace the default "US" value with the test country's code.
            enterText(countryCode, inTextField: "Country code", replacingExistingText: true, file: file, line: line)
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

    func completeFullUSKYC(
        address: Address,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let addressLine1 = try XCTUnwrap(address.line1, file: file, line: line)
        let addressLine2 = try XCTUnwrap(address.line2, file: file, line: line)
        let city = try XCTUnwrap(address.city, file: file, line: line)
        let state = try XCTUnwrap(address.state, file: file, line: line)
        let postalCode = try XCTUnwrap(address.postalCode, file: file, line: line)

        let kycLabel = app.staticTexts["KYC Information"].firstMatch
        XCTAssertTrue(
            kycLabel.waitForExistence(timeout: .networkTimeout),
            "KYC screen should appear",
            file: file,
            line: line
        )
        waitForLoadingToFinish(file: file, line: line)

        enterText("Crypto", inTextField: "Enter your first name", advancingToNextField: true, file: file, line: line)
        enterText("Tester", inTextField: "Enter your last name", advancingToNextField: true, file: file, line: line)
        enterText("000000000", inTextField: "Enter your SSN", file: file, line: line)

        setDateOfBirth(file: file, line: line)

        app.typeText(XCUIKeyboardKey.return.rawValue)
        enterText(addressLine1, inTextField: "Enter your street address", advancingToNextField: true, file: file, line: line)
        enterText(addressLine2, inTextField: "Apartment, suite, etc.", advancingToNextField: true, file: file, line: line)
        enterText(city, inTextField: "Enter your city", advancingToNextField: true, file: file, line: line)
        enterText(state, inTextField: "Enter your state or province", advancingToNextField: true, file: file, line: line)
        enterText(postalCode, inTextField: "Enter your postal code", advancingToNextField: true, file: file, line: line)
        app.typeText(XCUIKeyboardKey.return.rawValue)

        let submitButton = app.buttons["Submit"].firstMatch
        XCTAssertTrue(submitButton.isEnabled, "KYC Submit button should be enabled", file: file, line: line)
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

        enterText(address, inTextField: "Enter wallet address", file: file, line: line)
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
        inTextField identifier: String,
        replacingExistingText: Bool = false,
        advancingToNextField: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        enterText(text, in: app.textFields[identifier].firstMatch, replacingExistingText: replacingExistingText, advancingToNextField: advancingToNextField, file: file, line: line)
    }

    func enterText(
        _ text: String,
        in element: XCUIElement,
        replacingExistingText: Bool = false,
        advancingToNextField: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(element.waitForExistence(timeout: .animationTimeout), "Text field should exist", file: file, line: line)
        element.tap()

        // Password and OTP elements also use this helper, but their accessibility values aren't suitable for plaintext comparison.
        let shouldVerifyValue = element.elementType == .textField
        let maximumAttempts = shouldVerifyValue ? 2 : 1
        var valueMatches = !shouldVerifyValue

        for attempt in 0..<maximumAttempts {
            if replacingExistingText || attempt > 0 {
                replaceExistingText(with: text, in: element)
            } else {
                element.typeText(text)
            }

            valueMatches = !shouldVerifyValue || textFieldValueMatches(element, expectedText: text)
            if valueMatches {
                break
            }
        }

        if shouldVerifyValue {
            let actualValue = element.value as? String ?? "nil"
            XCTAssertTrue(valueMatches, "Text field value should match \(text); found \(actualValue)", file: file, line: line)

            guard valueMatches else {
                return
            }
        }

        if advancingToNextField {
            element.typeText(XCUIKeyboardKey.return.rawValue)
        }
    }

    private func replaceExistingText(with text: String, in element: XCUIElement) {
        let existingText = element.value as? String ?? ""

        // A double-tap selects an entire alphanumeric token.
        // Values with separators (e.g. @, ., -, and other punctuation) expose Select All after a long press.
        if existingText.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) == nil {
            element.doubleTap()
        } else {
            element.press(forDuration: 1)
        }

        let selectAll = app.descendants(matching: .any).matching(identifier: "Select All").firstMatch
        if selectAll.waitForExistence(timeout: 1) {
            selectAll.tap()
        }

        element.typeText(text)
    }

    private func textFieldValueMatches(_ element: XCUIElement, expectedText: String) -> Bool {
        guard let actualText = element.value as? String else {
            return false
        }

        return normalizedText(actualText) == normalizedText(expectedText)
    }

    private func normalizedText(_ text: String) -> String {
        text.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
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

    func setDateOfBirth(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let pickerWheels = app.pickerWheels
        let values = ["January", "1", "1990"]
        let firstWheel = pickerWheels.element(boundBy: 0)
        XCTAssertTrue(
            firstWheel.waitForExistence(timeout: .animationTimeout),
            "Date of birth picker should exist",
            file: file,
            line: line
        )
        XCTAssertEqual(
            pickerWheels.count,
            values.count,
            "Date of birth picker should contain month, day, and year wheels",
            file: file,
            line: line
        )

        // XCTest exposes wheel-style date pickers as separate month, day, and year elements.
        for (index, value) in values.enumerated() {
            pickerWheels.element(boundBy: index).adjust(toPickerWheelValue: value)
        }
    }

    static func makeRandomUSPhoneNumber() -> String {
        "+1212\(String(format: "%03d%04d", Int.random(in: 200...999), Int.random(in: 0...9999)))"
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
