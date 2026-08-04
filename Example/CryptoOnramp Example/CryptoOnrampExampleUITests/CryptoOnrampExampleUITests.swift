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

    private static let euTestAddress = Address(
        city: "Athens",
        country: "GR",
        line1: "1 Fake Street",
        line2: "Apt 2",
        postalCode: "11145",
        state: "Attica"
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

    /// Tests the complete new-user flow, including registration, KYC, identity verification, wallet registration, and card checkout.
    @MainActor
    func testNewUserEndToEnd() throws {
        let phoneNumber = Self.makeRandomUSPhoneNumber()
        let address = Self.testAddress
        let addressLine1 = try XCTUnwrap(address.line1)
        let addressLine2 = try XCTUnwrap(address.line2)
        let city = try XCTUnwrap(address.city)
        let state = try XCTUnwrap(address.state)
        let postalCode = try XCTUnwrap(address.postalCode)

        // Step 1: Create, register, and authenticate a new Link user.
        signUpAndAuthenticateNewUser(
            fullName: "Crypto Onramp UI Tests",
            phoneNumber: phoneNumber,
            countryCode: "US"
        )

        // Step 2: Provide full US KYC information.
        let kycLabel = app.staticTexts["KYC Information"].firstMatch
        XCTAssertTrue(kycLabel.waitForExistence(timeout: .networkTimeout), "KYC screen should appear")
        waitForLoadingToFinish()

        let firstNameField = app.textFields["Enter your first name"].firstMatch
        XCTAssertTrue(firstNameField.waitForExistence(timeout: .animationTimeout), "First name field should exist")
        firstNameField.tap()
        app.typeText("Crypto" + XCUIKeyboardKey.return.rawValue)
        app.typeText("Tester" + XCUIKeyboardKey.return.rawValue)
        app.typeText("000000000" + XCUIKeyboardKey.return.rawValue)

        setDateOfBirth()

        let kycScrollView = app.scrollViews["kyc_form"].firstMatch
        XCTAssertTrue(kycScrollView.waitForExistence(timeout: .animationTimeout), "KYC form should be scrollable")
        kycScrollView.swipeUp()

        let addressLine1Field = app.textFields["Enter your street address"].firstMatch
        addressLine1Field.tap()
        app.typeText(addressLine1 + XCUIKeyboardKey.return.rawValue)
        app.typeText(addressLine2 + XCUIKeyboardKey.return.rawValue)
        app.typeText(city + XCUIKeyboardKey.return.rawValue)
        app.typeText(state + XCUIKeyboardKey.return.rawValue)
        app.typeText(postalCode + XCUIKeyboardKey.return.rawValue)
        app.typeText(XCUIKeyboardKey.return.rawValue)

        let submitKYCButton = app.buttons["Submit"].firstMatch
        XCTAssertTrue(submitKYCButton.isEnabled, "KYC Submit button should be enabled")
        submitKYCButton.tap()

        // Step 3: Complete document verification with the synchronous test-mode success option.
        completeSuccessfulIdentityVerification()

        // Step 4: Register a new Solana wallet.
        addSolanaWallet(address: Self.solanaWalletAddress)

        let nextButton = app.buttons["Next"].firstMatch
        XCTAssertTrue(nextButton.wait(for: \.isEnabled, toEqual: true, timeout: .networkTimeout), "Next button should become enabled")
        nextButton.tap()

        // Step 5: Add a credit card and make a $3 purchase.
        let paymentLabel = app.staticTexts["Payment"].firstMatch
        XCTAssertTrue(paymentLabel.waitForExistence(timeout: .networkTimeout), "Payment screen should appear")
        waitForLoadingToFinish()
        app.buttons["$3"].firstMatch.tap()
        app.buttons["Select a payment method"].firstMatch.tap()

        let addCardOption = app.staticTexts["Add Debit / Credit Card"].firstMatch
        XCTAssertTrue(addCardOption.waitForExistence(timeout: .animationTimeout), "Add card option should appear")
        addCardOption.tap()

        // Dismiss to test cancelation of the UI, before re-presenting and entering details.
        let closeCardCollectionButton = app.buttons["Close"].firstMatch
        XCTAssertTrue(closeCardCollectionButton.waitForExistence(timeout: .animationTimeout), "Card collection sheet should appear")
        closeCardCollectionButton.tap()
        XCTAssertTrue(closeCardCollectionButton.waitForNonExistence(timeout: .animationTimeout), "Card collection sheet should close")
        waitForLoadingToFinish()

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

        // Step 6: Confirm checkout and reach the success screen.
        let reviewLabel = app.staticTexts["Review"].firstMatch
        XCTAssertTrue(reviewLabel.waitForExistence(timeout: .networkTimeout), "Review screen should appear")
        waitForLoadingToFinish()
        app.buttons["Confirm"].firstMatch.tap()

        let successLabel = app.staticTexts["Purchase successful"].firstMatch
        XCTAssertTrue(successLabel.waitForExistence(timeout: .networkTimeout), "Checkout success screen should appear")
        waitForLoadingToFinish()
    }

    /// Tests EU registration and KYC, compliance identifiers, user attestation, identity verification, and wallet verification.
    @MainActor
    func testNewEUUserThroughWalletVerification() throws {
        let phoneNumber = Self.makeRandomGreekPhoneNumber()
        let address = Self.euTestAddress
        let addressLine1 = try XCTUnwrap(address.line1)
        let addressLine2 = try XCTUnwrap(address.line2)
        let city = try XCTUnwrap(address.city)
        let state = try XCTUnwrap(address.state)
        let postalCode = try XCTUnwrap(address.postalCode)
        let country = try XCTUnwrap(address.country)

        // Step 1: Create, register, and authenticate a new Link user in Greece.
        signUpAndAuthenticateNewUser(
            fullName: "Crypto Onramp EU UI Tests",
            phoneNumber: phoneNumber,
            countryCode: country
        )

        // Step 2: Provide full EU KYC information.
        let kycLabel = app.staticTexts["KYC Information"].firstMatch
        XCTAssertTrue(kycLabel.waitForExistence(timeout: .networkTimeout), "KYC screen should appear")
        waitForLoadingToFinish()

        let euResidenceButton = app.segmentedControls.buttons["EU"].firstMatch
        XCTAssertTrue(euResidenceButton.waitForExistence(timeout: .animationTimeout), "EU residence option should exist")
        euResidenceButton.tap()

        let firstNameField = app.textFields["Enter your first name"].firstMatch
        XCTAssertTrue(firstNameField.waitForExistence(timeout: .animationTimeout), "First name field should exist")
        firstNameField.tap()
        app.typeText("Crypto" + XCUIKeyboardKey.return.rawValue)
        app.typeText("Tester" + XCUIKeyboardKey.return.rawValue)

        setDateOfBirth()

        let kycScrollView = app.scrollViews["kyc_form"].firstMatch
        kycScrollView.swipeUp()

        let birthCountryField = app.textFields["Country code"].firstMatch
        XCTAssertTrue(birthCountryField.waitForExistence(timeout: .animationTimeout), "Birth country field should exist")
        birthCountryField.tap()
        app.typeText(country + XCUIKeyboardKey.return.rawValue)
        app.typeText(city + XCUIKeyboardKey.return.rawValue)
        app.typeText("GR, MT" + XCUIKeyboardKey.return.rawValue)
        app.typeText(addressLine1 + XCUIKeyboardKey.return.rawValue)
        app.typeText(addressLine2 + XCUIKeyboardKey.return.rawValue)
        app.typeText(city + XCUIKeyboardKey.return.rawValue)
        app.typeText(state + XCUIKeyboardKey.return.rawValue)
        app.typeText(postalCode + XCUIKeyboardKey.return.rawValue)
        app.typeText(country + XCUIKeyboardKey.return.rawValue)

        let submitKYCButton = app.buttons["Submit"].firstMatch
        XCTAssertTrue(submitKYCButton.isEnabled, "KYC Submit button should be enabled")
        submitKYCButton.tap()

        // Step 3: Submit an appropriately formatted value for the compliance identifier requested by the backend.
        let identifiersLabel = app.staticTexts["Add identifiers"].firstMatch
        XCTAssertTrue(identifiersLabel.waitForExistence(timeout: .networkTimeout), "Compliance identifiers screen should appear")
        waitForLoadingToFinish()

        enterText("1234567M", in: app.textFields.firstMatch)
        dismissKeyboard()

        let submitIdentifiersButton = app.buttons["Submit Identifiers"].firstMatch
        XCTAssertTrue(submitIdentifiersButton.isEnabled, "Submit Identifiers button should be enabled")
        submitIdentifiersButton.tap()

        // Step 4: Cancel user attestation once, then re-present and accept it.
        let userAttestationLabel = app.staticTexts["Accept user attestation"].firstMatch
        XCTAssertTrue(userAttestationLabel.waitForExistence(timeout: .networkTimeout), "User attestation screen should appear")
        waitForLoadingToFinish()

        let reviewAttestationButton = app.buttons["Review Attestation"].firstMatch
        reviewAttestationButton.tap()

        let declarationsLabel = app.staticTexts["Declarations"].firstMatch
        XCTAssertTrue(declarationsLabel.waitForExistence(timeout: .networkTimeout), "User attestation sheet should appear")
        app.buttons["Close"].firstMatch.tap()
        XCTAssertTrue(declarationsLabel.waitForNonExistence(timeout: .animationTimeout), "User attestation sheet should close")

        reviewAttestationButton.tap()
        XCTAssertTrue(declarationsLabel.waitForExistence(timeout: .networkTimeout), "User attestation sheet should appear again")

        let attestationScrollView = app.scrollViews.firstMatch
        XCTAssertTrue(attestationScrollView.waitForExistence(timeout: .animationTimeout), "User attestation content should be scrollable")
        attestationScrollView.swipeUp(velocity: .fast)
        app.buttons["Accept"].firstMatch.tap()

        // Step 5: Complete document verification with the synchronous test-mode success option.
        completeSuccessfulIdentityVerification()

        // Step 6: Register and verify a Solana wallet.
        addSolanaWallet(address: Self.solanaWalletAddress)

        let verifyOwnershipButton = app.buttons["Verify Ownership"].firstMatch
        XCTAssertTrue(verifyOwnershipButton.waitForExistence(timeout: .animationTimeout), "Verify Ownership button should appear")
        verifyOwnershipButton.tap()
        XCTAssertTrue(app.staticTexts["Verified"].firstMatch.waitForExistence(timeout: .networkTimeout), "The wallet should become verified")
    }

    /// Tests stepping a US customer up from KYC level 0 to level 1 while completing a bank account purchase.
    @MainActor
    func testKYCLevelStepUpToLevel1AndCheckout() throws {
        let phoneNumber = Self.makeRandomUSPhoneNumber()
        let address = Self.testAddress
        let addressLine1 = try XCTUnwrap(address.line1)
        let addressLine2 = try XCTUnwrap(address.line2)
        let city = try XCTUnwrap(address.city)
        let state = try XCTUnwrap(address.state)
        let postalCode = try XCTUnwrap(address.postalCode)

        // Step 1: Enable L0 KYC mode, then create, register, and authenticate a new Link user.
        waitForLoadingToFinish()

        let settingsButton = app.images["gearshape"].firstMatch
        XCTAssertTrue(settingsButton.waitForExistence(timeout: .animationTimeout), "Settings button should exist")
        settingsButton.tap()

        let l0ModeButton = app.buttons["L0 KYC Mode"].firstMatch
        XCTAssertTrue(l0ModeButton.waitForExistence(timeout: .animationTimeout), "L0 KYC Mode menu item should exist")
        l0ModeButton.tap()

        signUpAndAuthenticateNewUser(
            fullName: "Crypto Onramp L0 UI Tests",
            phoneNumber: phoneNumber,
            countryCode: "US"
        )

        // Step 2: Provide only the required US level 0 KYC information.
        let kycLabel = app.staticTexts["KYC Information"].firstMatch
        XCTAssertTrue(kycLabel.waitForExistence(timeout: .networkTimeout), "KYC screen should appear")
        waitForLoadingToFinish()

        let firstNameField = app.textFields["Enter your first name"].firstMatch
        XCTAssertTrue(firstNameField.waitForExistence(timeout: .animationTimeout), "First name field should exist")
        firstNameField.tap()
        app.typeText("Crypto" + XCUIKeyboardKey.return.rawValue)
        app.typeText("Tester" + XCUIKeyboardKey.return.rawValue)
        dismissKeyboard()

        let kycScrollView = app.scrollViews["kyc_form"].firstMatch
        XCTAssertTrue(kycScrollView.waitForExistence(timeout: .animationTimeout), "KYC form should be scrollable")
        kycScrollView.swipeUp()

        let addressLine1Field = app.textFields["Enter your street address"].firstMatch
        XCTAssertTrue(addressLine1Field.waitForExistence(timeout: .animationTimeout), "Address line 1 field should exist")
        addressLine1Field.tap()
        app.typeText(addressLine1 + XCUIKeyboardKey.return.rawValue)
        app.typeText(addressLine2 + XCUIKeyboardKey.return.rawValue)
        app.typeText(city + XCUIKeyboardKey.return.rawValue)
        app.typeText(state + XCUIKeyboardKey.return.rawValue)
        app.typeText(postalCode + XCUIKeyboardKey.return.rawValue)
        app.typeText(XCUIKeyboardKey.return.rawValue)

        let submitKYCButton = app.buttons["Submit"].firstMatch
        XCTAssertTrue(submitKYCButton.isEnabled, "KYC Submit button should be enabled")
        submitKYCButton.tap()

        // Step 3: Add a Solana wallet and continue to payment.
        addSolanaWallet(address: Self.solanaWalletAddress)

        let nextButton = app.buttons["Next"].firstMatch
        XCTAssertTrue(nextButton.wait(for: \.isEnabled, toEqual: true, timeout: .networkTimeout), "Next button should become enabled")
        nextButton.tap()

        // Step 4: Add a test bank account and attempt a $75 purchase.
        let paymentLabel = app.staticTexts["Payment"].firstMatch
        XCTAssertTrue(paymentLabel.waitForExistence(timeout: .networkTimeout), "Payment screen should appear")
        waitForLoadingToFinish()

        app.buttons["Select a payment method"].firstMatch.tap()

        let addBankAccountOption = app.staticTexts["Add Bank Account"].firstMatch
        XCTAssertTrue(addBankAccountOption.waitForExistence(timeout: .animationTimeout), "Add Bank Account option should appear")
        addBankAccountOption.tap()

        let agreeAndContinueButton = app.buttons["consent_agree_button"].firstMatch
        XCTAssertTrue(agreeAndContinueButton.waitForExistence(timeout: .networkTimeout), "Financial Connections consent screen should appear")
        agreeAndContinueButton.tap()

        let successBank = app.tables.cells.staticTexts["Success"].firstMatch
        XCTAssertTrue(successBank.waitForExistence(timeout: .networkTimeout), "Success test bank should appear")
        successBank.tap()

        let connectAccountsButton = app.buttons["connect_accounts_button"].firstMatch
        XCTAssertTrue(connectAccountsButton.waitForExistence(timeout: .networkTimeout), "Connect accounts button should appear")
        connectAccountsButton.tap()

        let bankSuccessDoneButton = app.buttons["success_done_button"].firstMatch
        XCTAssertTrue(bankSuccessDoneButton.waitForExistence(timeout: .networkTimeout), "Bank account success screen should appear")
        bankSuccessDoneButton.tap()
        XCTAssertTrue(bankSuccessDoneButton.waitForNonExistence(timeout: .networkTimeout), "Bank account success screen should close")

        let linkSheet = app.otherElements["Stripe.Link.PayWithLinkViewController"].firstMatch
        let linkBankContinueButton = linkSheet.buttons["Continue"].firstMatch
        XCTAssertTrue(linkBankContinueButton.waitForExistence(timeout: .networkTimeout), "Link bank account Continue button should appear")
        linkBankContinueButton.tap()

        let confirmPaymentDetailsLabel = linkSheet.staticTexts["Confirm payment details"].firstMatch
        XCTAssertTrue(confirmPaymentDetailsLabel.waitForExistence(timeout: .networkTimeout), "Bank billing details form should appear")
        enterText("Crypto Onramp L0 UI Tests", in: linkSheet.textFields["Full name"].firstMatch)
        enterText(postalCode, in: linkSheet.textFields["ZIP"].firstMatch)
        dismissKeyboard()

        let billingDetailsContinueButton = linkSheet.buttons["Continue"].firstMatch
        XCTAssertTrue(
            billingDetailsContinueButton.wait(for: \.isEnabled, toEqual: true, timeout: .animationTimeout),
            "Bank billing details Continue button should become enabled"
        )
        billingDetailsContinueButton.tap()
        XCTAssertTrue(linkSheet.waitForNonExistence(timeout: .networkTimeout), "Link bank account sheet should close")
        waitForLoadingToFinish()

        let standardACHButton = app.segmentedControls.buttons["Standard"].firstMatch
        XCTAssertTrue(standardACHButton.waitForExistence(timeout: .animationTimeout), "Standard ACH option should appear")
        if !standardACHButton.isSelected {
            standardACHButton.tap()
        }
        XCTAssertTrue(standardACHButton.isSelected, "Standard ACH should be selected")

        for digit in ["7", "5"] {
            app.buttons[digit].firstMatch.tap()
        }
        XCTAssertTrue(app.staticTexts["$75"].firstMatch.exists, "Purchase amount should be $75")

        let paymentContinueButton = app.buttons["Continue"].firstMatch
        XCTAssertTrue(paymentContinueButton.isEnabled, "Payment Continue button should be enabled")
        paymentContinueButton.tap()
        waitForLoadingToFinish()

        // Step 5: Complete the required level 1 step-up with SSN and date of birth, then retry the transaction.
        XCTAssertTrue(kycLabel.waitForExistence(timeout: .networkTimeout), "Level 1 KYC step-up should appear")
        waitForLoadingToFinish()
        enterText("000000000", in: app.textFields["Enter your SSN"].firstMatch)
        dismissKeyboard()
        setDateOfBirth()

        let submitLevel1Button = app.buttons["Submit"].firstMatch
        XCTAssertTrue(submitLevel1Button.isEnabled, "Level 1 Submit button should be enabled")
        submitLevel1Button.tap()

        XCTAssertTrue(kycLabel.waitForNonExistence(timeout: .networkTimeout), "Level 1 KYC step-up should finish")
        let level1CompleteAlert = app.alerts["Verification complete"].firstMatch
        XCTAssertTrue(level1CompleteAlert.waitForExistence(timeout: .networkTimeout), "Level 1 completion alert should appear")
        XCTAssertTrue(level1CompleteAlert.staticTexts["Please try the transaction again."].exists, "Level 1 completion alert should request a retry")
        level1CompleteAlert.buttons["OK"].tap()

        XCTAssertTrue(paymentLabel.waitForExistence(timeout: .animationTimeout), "Payment screen should reappear")
        waitForLoadingToFinish()
        paymentContinueButton.tap()
        XCTAssertTrue(
            app.staticTexts["Loading…"].firstMatch.waitForExistence(timeout: .animationTimeout),
            "The second transaction attempt should start"
        )
        waitForLoadingToFinish()

        // Step 6: Confirm the retried transaction and reach checkout success.
        let reviewLabel = app.staticTexts["Review"].firstMatch
        XCTAssertTrue(reviewLabel.waitForExistence(timeout: .networkTimeout), "Review screen should appear")
        waitForLoadingToFinish()

        let confirmButton = app.buttons["Confirm"].firstMatch
        XCTAssertTrue(confirmButton.exists, "Confirm button should exist")
        confirmButton.tap()

        let successLabel = app.staticTexts["Purchase successful"].firstMatch
        XCTAssertTrue(successLabel.waitForExistence(timeout: .networkTimeout), "Checkout success screen should appear")
        waitForLoadingToFinish()
    }

    private func setDateOfBirth(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let kycScrollView = app.scrollViews["kyc_form"].firstMatch
        XCTAssertTrue(
            kycScrollView.waitForExistence(timeout: .animationTimeout),
            "KYC form should be scrollable",
            file: file,
            line: line
        )
        kycScrollView.swipeUp()

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
}
