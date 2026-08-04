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

    private static let refreshedTestAddress = Address(
        city: "Jersey City",
        country: "US",
        line1: "456 Fake St.",
        line2: "Apartment 2B",
        postalCode: "07302",
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
        let postalCode = try XCTUnwrap(address.postalCode)

        // Step 1: Create, register, and authenticate a new Link user.
        signUpAndAuthenticateNewUser(
            fullName: "Crypto Onramp UI Tests",
            phoneNumber: phoneNumber,
            countryCode: "US"
        )

        // Step 2: Provide full US KYC information.
        try completeFullUSKYC(address: address)

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
    }

    /// Tests a complete new-user checkout using a refreshed KYC address and a standard ACH bank payment.
    @MainActor
    func testNewUserStandardACHCheckoutAfterKYCRefresh() throws {
        let phoneNumber = Self.makeRandomUSPhoneNumber()
        let refreshedAddress = Self.refreshedTestAddress
        let refreshedAddressLine1 = try XCTUnwrap(refreshedAddress.line1)
        let refreshedAddressLine2 = try XCTUnwrap(refreshedAddress.line2)
        let refreshedCity = try XCTUnwrap(refreshedAddress.city)
        let refreshedState = try XCTUnwrap(refreshedAddress.state)
        let refreshedPostalCode = try XCTUnwrap(refreshedAddress.postalCode)
        let refreshedCountry = try XCTUnwrap(refreshedAddress.country)
        let refreshedFormattedAddress = [
            refreshedAddressLine1,
            refreshedAddressLine2,
            refreshedCity,
            refreshedState,
            refreshedCountry,
            refreshedPostalCode,
        ].joined(separator: ", ")

        // Step 1: Create, register, and authenticate a new Link user.
        signUpAndAuthenticateNewUser(
            fullName: "Crypto Onramp ACH UI Tests",
            phoneNumber: phoneNumber,
            countryCode: "US"
        )

        // Step 2: Provide full US KYC information.
        try completeFullUSKYC(address: Self.testAddress)

        // Step 3: Complete document verification with the synchronous test-mode success option.
        completeSuccessfulIdentityVerification()

        // Step 4: Register a new Solana wallet and continue to payment.
        addSolanaWallet(address: Self.solanaWalletAddress)

        let nextButton = app.buttons["Next"].firstMatch
        XCTAssertTrue(nextButton.wait(for: \.isEnabled, toEqual: true, timeout: .networkTimeout), "Next button should become enabled")
        nextButton.tap()

        let paymentLabel = app.staticTexts["Payment"].firstMatch
        XCTAssertTrue(paymentLabel.waitForExistence(timeout: .networkTimeout), "Payment screen should appear")
        waitForLoadingToFinish()

        // Step 5: Refresh the customer's KYC address from the authenticated-user toolbar.
        let userButton = app.images["person.fill"].firstMatch
        XCTAssertTrue(userButton.exists, "User toolbar button should exist")
        userButton.tap()

        let verifyKYCMenuItem = app.buttons["Verify KYC Info…"].firstMatch
        XCTAssertTrue(verifyKYCMenuItem.waitForExistence(timeout: .animationTimeout), "Verify KYC menu item should exist")
        verifyKYCMenuItem.tap()

        let confirmInformationLabel = app.staticTexts["Confirm your information"].firstMatch
        XCTAssertTrue(confirmInformationLabel.waitForExistence(timeout: .networkTimeout), "KYC confirmation sheet should appear")

        let editAddressButton = app.buttons["Edit address"].firstMatch
        XCTAssertTrue(editAddressButton.waitForExistence(timeout: .animationTimeout), "Edit address button should appear")
        editAddressButton.tap()

        let updateAddressNavigationBar = app.navigationBars["Update Address"].firstMatch
        XCTAssertTrue(updateAddressNavigationBar.waitForExistence(timeout: .animationTimeout), "Update Address screen should appear")

        let addressLine1Field = app.textFields["Enter your street address"].firstMatch
        enterText(refreshedAddressLine1 + XCUIKeyboardKey.return.rawValue, in: addressLine1Field)
        app.typeText(refreshedAddressLine2 + XCUIKeyboardKey.return.rawValue)
        app.typeText(refreshedCity + XCUIKeyboardKey.return.rawValue)
        app.typeText(refreshedState + XCUIKeyboardKey.return.rawValue)
        app.typeText(refreshedPostalCode)
        dismissKeyboard()

        let submitAddressButton = app.buttons["Submit"].firstMatch
        XCTAssertTrue(submitAddressButton.isEnabled, "Updated address Submit button should be enabled")
        submitAddressButton.tap()

        XCTAssertTrue(confirmInformationLabel.waitForExistence(timeout: .networkTimeout), "Updated KYC confirmation sheet should appear")
        XCTAssertTrue(app.staticTexts[refreshedFormattedAddress].firstMatch.exists, "Updated KYC confirmation should show the new address")

        let confirmKYCButton = app.buttons["Confirm"].firstMatch
        XCTAssertTrue(confirmKYCButton.isEnabled, "KYC Confirm button should be enabled")
        confirmKYCButton.tap()

        let successAlert = app.alerts["Success"].firstMatch
        XCTAssertTrue(successAlert.waitForExistence(timeout: .networkTimeout), "KYC refresh success alert should appear")
        XCTAssertTrue(successAlert.staticTexts["KYC information confirmed."].exists, "KYC refresh should be confirmed")
        successAlert.buttons["OK"].tap()

        // Step 6: Add the Success test bank account and select standard ACH.
        app.buttons["$3"].firstMatch.tap()
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
        enterText("Crypto Onramp ACH UI Tests", in: linkSheet.textFields["Full name"].firstMatch)
        enterText(refreshedPostalCode, in: linkSheet.textFields["ZIP"].firstMatch)
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
        standardACHButton.tap()
        XCTAssertTrue(standardACHButton.isSelected, "Standard ACH should be selected")

        let paymentContinueButton = app.buttons["Continue"].firstMatch
        XCTAssertTrue(
            paymentContinueButton.wait(for: \.isEnabled, toEqual: true, timeout: .networkTimeout),
            "Payment Continue button should become enabled"
        )
        paymentContinueButton.tap()

        // Step 7: Confirm checkout and reach the success screen.
        let reviewLabel = app.staticTexts["Review"].firstMatch
        XCTAssertTrue(reviewLabel.waitForExistence(timeout: .networkTimeout), "Review screen should appear")
        waitForLoadingToFinish()
        app.buttons["Confirm"].firstMatch.tap()

        let purchaseSuccessLabel = app.staticTexts["Purchase successful"].firstMatch
        XCTAssertTrue(purchaseSuccessLabel.waitForExistence(timeout: .networkTimeout), "Checkout success screen should appear")
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

        let birthCountryField = app.textFields["Country code"].firstMatch
        XCTAssertTrue(birthCountryField.waitForExistence(timeout: .animationTimeout), "Birth country field should exist")
        birthCountryField.typeText(country + XCUIKeyboardKey.return.rawValue)
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
}
