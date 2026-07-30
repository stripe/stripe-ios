//
//  CryptoOnrampExampleUITests.swift
//  CryptoOnrampExampleUITests
//
//  Created by Michael Liberatore on 12/1/25.
//

import Foundation

@_spi(CryptoOnrampAlpha)
import StripeCryptoOnramp

import XCTest

final class CryptoOnrampExampleUITests: XCTestCase {

    private static let testAddress = Address(
        city: "Hoboken",
        country: "US",
        line1: "123 Fake St.",
        line2: "Apartment 1A",
        postalCode: "07030",
        state: "NJ"
    )

    private static let solanaWalletAddress = "DBhBRyb9y6xyAbhdgpPKqQG2CfXmwHiaKvmzVjDCguXq"

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchEnvironment = ["UITesting": "true"]
        app.launch()
    }

    /// Tests a happy-path flow from log in (existing account) to successful checkout, followed by re-authentication using seamless sign-in.
    @MainActor
    func testExistingUserEndToEnd() throws {
        // Step 1: Enter email and password
        waitForLoadingToFinish()

        let emailField = app.textFields["Enter email address"].firstMatch
        enterText("onramptest2@stripe.com", in: emailField)

        let passwordField = app.secureTextFields["Enter password"].firstMatch
        enterText("testing1234", in: passwordField)

        // Step 2: Tap Log In button
        let logInButton = app.buttons["Log In"].firstMatch
        XCTAssertTrue(logInButton.exists)
        logInButton.tap()

        // Step 3: Wait for OTP field and enter 000000. It will auto-submit.
        let otpField = app.textViews["Code field"].firstMatch
        enterText("000000", in: otpField)

        // Step 4: Wait for wallet selection screen and tap the Next button.
        // The Next button will be enabled once the user's wallets load and we auto-select the first wallet.
        let walletsLabel = app.staticTexts["Wallets"].firstMatch
        XCTAssertTrue(walletsLabel.waitForExistence(timeout: .networkTimeout), "Wallet selection screen should appear")
        waitForLoadingToFinish()

        let nextButton = app.buttons["Next"].firstMatch
        XCTAssertTrue(nextButton.wait(for: \.isEnabled, toEqual: true, timeout: .networkTimeout), "Next button should become enabled.")
        nextButton.tap()

        // Step 5: Wait for the payment screen, select the $3 button, and the most recent payment method, then tap Next.
        let paymentLabel = app.staticTexts["Payment"].firstMatch
        XCTAssertTrue(paymentLabel.waitForExistence(timeout: .networkTimeout), "Payment screen should appear")
        waitForLoadingToFinish()

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
        waitForLoadingToFinish()

        let confirmButton = app.buttons["Confirm"].firstMatch
        XCTAssertTrue(confirmButton.exists, "Confirm button should exist")
        confirmButton.tap()

        // Step 7: Wait for the Success screen, then log out.
        let successLabel = app.staticTexts["Purchase successful"].firstMatch
        XCTAssertTrue(successLabel.waitForExistence(timeout: .networkTimeout), "Success screen should appear")
        waitForLoadingToFinish()

        let userButton = app.images["person.fill"].firstMatch
        XCTAssertTrue(userButton.exists, "User toolbar button should exist")
        userButton.tap()

        let logOutMenuItem = app.buttons["Log out"].firstMatch
        XCTAssertTrue(logOutMenuItem.waitForExistence(timeout: .animationTimeout), "Log out menu item should exist")
        logOutMenuItem.tap()

        // Step 8: Authenticate again using seamless sign-in (no OTP, stored auth token from prior login).
        let seamlessSignInLabel = app.staticTexts["Continue as onramptest2@stripe.com?"]
        XCTAssertTrue(seamlessSignInLabel.waitForExistence(timeout: .networkTimeout), "Seamless sign-in label should exist")
        waitForLoadingToFinish()

        let seamlessSignInButton = app.buttons["Continue"].firstMatch
        XCTAssertTrue(seamlessSignInButton.exists, "Seamless sign-in (Continue) button should exist")
        seamlessSignInButton.tap()

        // Step 9: We should skip right to the wallet selection screen without the need to enter an OTP code.
        let walletsLabel2 = app.staticTexts["Wallets"].firstMatch
        XCTAssertTrue(walletsLabel2.waitForExistence(timeout: .networkTimeout), "Wallet selection screen should appear")
    }

    /// Tests the complete new-user flow, including registration, KYC, identity and wallet verification, and card checkout.
    @MainActor
    func testNewUserEndToEnd() throws {
        let email = "crypto-onramp-ui-tests-\(UUID().uuidString.lowercased())@stripe.com"
        let phoneNumber = Self.makeRandomUSPhoneNumber()
        let address = Self.testAddress
        let addressLine1 = try XCTUnwrap(address.line1)
        let addressLine2 = try XCTUnwrap(address.line2)
        let city = try XCTUnwrap(address.city)
        let state = try XCTUnwrap(address.state)
        let postalCode = try XCTUnwrap(address.postalCode)

        // Step 1: Create a new account with unique credentials.
        waitForLoadingToFinish()

        let emailField = app.textFields["Enter email address"].firstMatch
        enterText(email, in: emailField)
        enterText("testing1234", in: app.secureTextFields["Enter password"].firstMatch)
        app.buttons["Sign Up"].firstMatch.tap()

        // Step 2: Register the new Link user with a unique US phone number.
        let registrationLabel = app.staticTexts["Registration"].firstMatch
        XCTAssertTrue(registrationLabel.waitForExistence(timeout: .networkTimeout), "Registration screen should appear")
        dismissSavePasswordPromptIfPresent()
        waitForLoadingToFinish()
        enterText("Crypto Onramp UI Tests", in: app.textFields["Enter your full name"].firstMatch)
        enterText(phoneNumber, in: app.textFields["Enter phone number (e.g., +12125551234)"].firstMatch)
        dismissKeyboard()

        let registerButton = app.buttons["Register"].firstMatch
        XCTAssertTrue(registerButton.isHittable, "Register button should be hittable")
        XCTAssertTrue(registerButton.isEnabled, "Register button should be enabled")
        registerButton.tap()

        let authenticateButton = app.buttons["Authenticate"].firstMatch
        XCTAssertTrue(authenticateButton.waitForExistence(timeout: .networkTimeout), "Authenticate button should appear after registration")
        authenticateButton.tap()

        // Step 3: Complete Link authentication using the test-mode OTP.
        let otpField = app.textViews["Code field"].firstMatch
        enterText("000000", in: otpField)

        // Step 4: Provide full US KYC information.
        let kycLabel = app.staticTexts["KYC Information"].firstMatch
        XCTAssertTrue(kycLabel.waitForExistence(timeout: .networkTimeout), "KYC screen should appear")
        waitForLoadingToFinish()

        let firstNameField = app.textFields["Enter your first name"].firstMatch
        XCTAssertTrue(firstNameField.waitForExistence(timeout: .animationTimeout), "First name field should exist")
        XCTAssertTrue(firstNameField.isHittable, "First name field should be hittable")
        firstNameField.tap()
        app.typeText("Crypto" + XCUIKeyboardKey.return.rawValue)
        app.typeText("Tester" + XCUIKeyboardKey.return.rawValue)
        app.typeText("000000000" + XCUIKeyboardKey.return.rawValue)

        setDateOfBirth()

        let kycScrollView = app.scrollViews["kyc_form"].firstMatch
        XCTAssertTrue(kycScrollView.waitForExistence(timeout: .animationTimeout), "KYC form should be scrollable")
        kycScrollView.swipeUp()

        let addressLine1Field = app.textFields["Enter your street address"].firstMatch
        XCTAssertTrue(addressLine1Field.isHittable, "Address line 1 field should be hittable")
        addressLine1Field.tap()
        app.typeText(addressLine1 + XCUIKeyboardKey.return.rawValue)
        app.typeText(addressLine2 + XCUIKeyboardKey.return.rawValue)
        app.typeText(city + XCUIKeyboardKey.return.rawValue)
        app.typeText(state + XCUIKeyboardKey.return.rawValue)
        app.typeText(postalCode + XCUIKeyboardKey.return.rawValue)
        app.typeText(XCUIKeyboardKey.return.rawValue)

        let submitKYCButton = app.buttons["Submit"].firstMatch
        XCTAssertTrue(submitKYCButton.isHittable, "KYC Submit button should be hittable")
        XCTAssertTrue(submitKYCButton.isEnabled, "KYC Submit button should be enabled")
        submitKYCButton.tap()

        // Step 5: Complete document verification with the synchronous test-mode success option.
        let verifyIdentityButton = app.buttons["Verify Identity"].firstMatch
        XCTAssertTrue(verifyIdentityButton.waitForExistence(timeout: .networkTimeout), "Identity verification screen should appear")
        waitForLoadingToFinish()
        verifyIdentityButton.tap()

        let verificationSuccessOption = app.staticTexts["Verification success"].firstMatch
        XCTAssertTrue(verificationSuccessOption.waitForExistence(timeout: .networkTimeout), "Identity test-mode options should appear")
        verificationSuccessOption.tap()

        let submitVerificationButton = app.buttons["Submit"].firstMatch
        XCTAssertTrue(submitVerificationButton.isEnabled, "Identity verification Submit button should be enabled")
        submitVerificationButton.tap()

        // Step 6: Register and verify a new Solana wallet.
        let walletsLabel = app.staticTexts["Wallets"].firstMatch
        XCTAssertTrue(walletsLabel.waitForExistence(timeout: .networkTimeout), "Wallet selection screen should appear after successful identity verification")
        waitForLoadingToFinish()

        let addWalletButton = app.buttons["Add Wallet…"].firstMatch
        XCTAssertTrue(addWalletButton.waitForExistence(timeout: .animationTimeout), "Add Wallet button should appear for a new user")
        addWalletButton.tap()

        enterText(Self.solanaWalletAddress, in: app.textFields["Enter wallet address"].firstMatch)
        let submitWalletButton = app.buttons["Submit"].firstMatch
        XCTAssertTrue(submitWalletButton.isEnabled, "Wallet Submit button should be enabled")
        submitWalletButton.tap()

        XCTAssertTrue(app.staticTexts[Self.solanaWalletAddress].firstMatch.waitForExistence(timeout: .networkTimeout), "The new Solana wallet should appear")

        // The example’s wallet ownership verifier submits the test signature "abcd".
        let verifyOwnershipButton = app.buttons["Verify Ownership"].firstMatch
        XCTAssertTrue(verifyOwnershipButton.waitForExistence(timeout: .animationTimeout), "Verify Ownership button should appear")
        verifyOwnershipButton.tap()
        XCTAssertTrue(app.staticTexts["Verified"].firstMatch.waitForExistence(timeout: .networkTimeout), "The wallet should become verified")

        let nextButton = app.buttons["Next"].firstMatch
        XCTAssertTrue(nextButton.wait(for: \.isEnabled, toEqual: true, timeout: .networkTimeout), "Next button should become enabled")
        nextButton.tap()

        // Step 7: Add a credit card and make a $3 purchase.
        let paymentLabel = app.staticTexts["Payment"].firstMatch
        XCTAssertTrue(paymentLabel.waitForExistence(timeout: .networkTimeout), "Payment screen should appear")
        waitForLoadingToFinish()
        app.buttons["$3"].firstMatch.tap()
        app.buttons["Select a payment method"].firstMatch.tap()

        let addCardOption = app.staticTexts["Add Debit / Credit Card"].firstMatch
        XCTAssertTrue(addCardOption.waitForExistence(timeout: .animationTimeout), "Add card option should appear")
        addCardOption.tap()

        let addPaymentMethodButton = app.buttons["Add a payment method"].firstMatch
        XCTAssertTrue(addPaymentMethodButton.waitForExistence(timeout: .networkTimeout), "Add payment method button should appear")
        addPaymentMethodButton.tap()

        let cardNumberField = app.textFields["Card number"].firstMatch
        enterText("4242424242424242", in: cardNumberField)
        enterText("1249", in: app.textFields["expiration date"].firstMatch)
        enterText("123", in: app.textFields["CVC"].firstMatch)

        let zipField = app.textFields["ZIP"].firstMatch
        if zipField.exists {
            enterText(postalCode, in: zipField)
        }

        dismissKeyboard()

        let linkContinueButton = app.buttons["Continue"].firstMatch
        XCTAssertTrue(linkContinueButton.isHittable, "Link Continue button should be hittable")
        XCTAssertTrue(linkContinueButton.isEnabled, "Link Continue button should be enabled")
        linkContinueButton.tap()

        XCTAssertTrue(
            cardNumberField.waitForNonExistence(timeout: .networkTimeout),
            "Card collection should finish"
        )
        waitForLoadingToFinish()

        let continueButton = app.buttons["Continue"].firstMatch
        XCTAssertTrue(
            continueButton.wait(for: \.isEnabled, toEqual: true, timeout: .networkTimeout),
            "Continue button should become enabled"
        )
        continueButton.tap()

        // Step 8: Confirm checkout and reach the success screen.
        let reviewLabel = app.staticTexts["Review"].firstMatch
        XCTAssertTrue(reviewLabel.waitForExistence(timeout: .networkTimeout), "Review screen should appear")
        waitForLoadingToFinish()
        app.buttons["Confirm"].firstMatch.tap()

        let successLabel = app.staticTexts["Purchase successful"].firstMatch
        XCTAssertTrue(successLabel.waitForExistence(timeout: .networkTimeout), "Checkout success screen should appear")
        waitForLoadingToFinish()
    }

    @MainActor
    private func enterText(
        _ text: String,
        in element: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(element.waitForExistence(timeout: .animationTimeout), "Text field should exist", file: file, line: line)
        XCTAssertTrue(element.isHittable, "Text field should be hittable", file: file, line: line)
        element.tap()
        element.typeText(text)
    }

    @MainActor
    private func setDateOfBirth() {
        let kycScrollView = app.scrollViews["kyc_form"].firstMatch
        XCTAssertTrue(kycScrollView.waitForExistence(timeout: .animationTimeout), "KYC form should be scrollable")
        kycScrollView.swipeUp()

        let pickerWheels = app.pickerWheels
        let values = ["January", "1", "1990"]
        let firstWheel = pickerWheels.element(boundBy: 0)
        XCTAssertTrue(firstWheel.waitForExistence(timeout: .animationTimeout), "Date of birth picker should exist")
        XCTAssertEqual(pickerWheels.count, values.count, "Date of birth picker should contain month, day, and year wheels")

        // XCTest exposes wheel-style date pickers as separate month, day, and year elements.
        for (index, value) in values.enumerated() {
            pickerWheels.element(boundBy: index).adjust(toPickerWheelValue: value)
        }
    }

    @MainActor
    private func waitForLoadingToFinish(
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
    private func dismissSavePasswordPromptIfPresent() {
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

    @MainActor
    private func dismissKeyboard() {
        let doneButton = app.toolbars.buttons["Done"].firstMatch
        if doneButton.waitForExistence(timeout: 1) {
            doneButton.tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).tap()
        }
    }

    private static func makeRandomUSPhoneNumber() -> String {
        "+1212555\(String(format: "%04d", Int.random(in: 0...9999)))"
    }
}

private extension TimeInterval {
    /// Rough timeout value to use when awaiting an operation that relies on networking.
    static let networkTimeout: TimeInterval = 60

    /// Rough timeout value to use when awaiting an operation that performs an animation or transition.
    static let animationTimeout: TimeInterval = 5
}
