//
//  EmbeddedPaymentElementSnapshotTests.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 10/16/24.
//

@_spi(STP) @testable import StripeCore
import StripeCoreTestUtils
@_spi(STP) @testable import StripePayments
@testable import StripePaymentSheet
@testable import StripePaymentsTestUtils
@_spi(STP) @testable import StripeUICore
import XCTest

class EmbeddedPaymentElementSnapshotTests: STPSnapshotTestCase, EmbeddedPaymentElementDelegate {
    var delegateDidUpdateHeightCalled: Bool = false
    var delegateDidUpdatePaymentOptionCalled: Bool = false
    func embeddedPaymentElementDidUpdateHeight(embeddedPaymentElement: StripePaymentSheet.EmbeddedPaymentElement) {
        self.delegateDidUpdateHeightCalled = true
    }

    func embeddedPaymentElementDidUpdatePaymentOption(embeddedPaymentElement: StripePaymentSheet.EmbeddedPaymentElement) {
        self.delegateDidUpdatePaymentOptionCalled = true
    }

    lazy var configuration: EmbeddedPaymentElement.Configuration = {
        var config = EmbeddedPaymentElement.Configuration._testValue_MostPermissive(isApplePayEnabled: false)
        config.apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        return config
    }()
    let paymentIntentConfig = EmbeddedPaymentElement.IntentConfiguration(mode: .payment(amount: 1000, currency: "USD"), paymentMethodTypes: ["card"]) { _, _ in
        // These tests don't confirm, so this is unused
        return ""
    }
    let setupIntentConfig = EmbeddedPaymentElement.IntentConfiguration(mode: .setup(setupFutureUsage: .offSession), paymentMethodTypes: ["card", "us_bank_account"]) { _, _ in
        // These tests don't confirm, so this is unused
        return ""
    }

    override func setUp() async throws {
        await AddressSpecProvider.shared.loadAddressSpecs()
        await FormSpecProvider.shared.load()
    }

    func testUpdateFromCardToCardAndUSBankAccount() async throws {
        // Given a EmbeddedPaymentElement instance...
        let sut = try await EmbeddedPaymentElement.create(intentConfiguration: paymentIntentConfig, configuration: configuration)
        sut.delegate = self
        sut.presentingViewController = UIViewController()
        sut.view.autosizeHeight(width: 300)

        let loadResult = await sut.update(intentConfiguration: setupIntentConfig)
        XCTAssertEqual(loadResult, .succeeded)
        sut.view.autosizeHeight(width: 300)

        STPSnapshotVerifyView(sut.view) // Should show US Bank and card
        XCTAssertTrue(delegateDidUpdateHeightCalled)
        XCTAssertFalse(delegateDidUpdatePaymentOptionCalled)
    }

    func testMarginsAreZero() async throws {
        let sut = try await EmbeddedPaymentElement.create(intentConfiguration: paymentIntentConfig, configuration: configuration)
        sut.delegate = self
        sut.presentingViewController = UIViewController()
        sut.view.autosizeHeight(width: 300)

        XCTAssertEqual(sut.view.directionalLayoutMargins, .zero)
        XCTAssertFalse(sut.view.hasAmbiguousLayout)
    }

    // MARK: - 'Change >' button and sublabel (eg Visa 4242)

    func testShowsChangeButton_flatRadio() async throws {
        await _testShowsChangeButton(rowStyle: .flatWithRadio)
    }

    func testShowsChangeButton_floatingButton() async throws {
        await _testShowsChangeButton(rowStyle: .floatingButton)

    }

    func testShowsChangeButton_flatCheckmark() async throws {
        await _testShowsChangeButton(rowStyle: .flatWithCheckmark)
    }

    func testShowsChangeButton_flatDisclosure() async throws {
        await _testShowsChangeButton(rowStyle: .flatWithDisclosure)
    }

    func _testShowsChangeButton(rowStyle: PaymentSheet.Appearance.EmbeddedPaymentElement.Row.Style) async {
        var configuration = configuration
        configuration.defaultBillingDetails = PaymentSheet.BillingDetails(
            address: PaymentSheet.Address(
                city: "South San Francisco",
                country: "US",
                line1: "354 Oyster Point Blvd",
                line2: "Apt 123",
                postalCode: "94080",
                state: "CA"
            ),
            email: "foo@bar.com",
            name: "Jane Doe",
            phone: "+15551234567"
        )
        configuration.appearance.embeddedPaymentElement.row.style = rowStyle
        var paymentIntentConfig = paymentIntentConfig
        paymentIntentConfig.paymentMethodTypes = ["card", "us_bank_account", "afterpay_clearpay"]
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: .deferredIntent(intentConfig: paymentIntentConfig),
            elementsSession: ._testValue(paymentMethodTypes: ["card", "us_bank_account", "afterpay_clearpay"]),
            savedPaymentMethods: [],
            paymentMethodTypes: [.stripe(.card), .stripe(.USBankAccount), .stripe(.afterpayClearpay)]
        )
        let sut = EmbeddedPaymentElement(
            configuration: configuration,
            loadResult: loadResult,
            analyticsHelper: ._testValue()
        )
        sut.view.autosizeHeight(width: 300)
        sut.delegate = self
        sut.presentingViewController = UIViewController()
        // There are 3 variations of adding a 'Change >' button and sublabel to a selected row
        // 1️⃣
        // ...tapping card and filling out the form...
        sut.embeddedPaymentMethodsView.getRowButton(accessibilityIdentifier: "Card").handleTap()
        let cardForm = sut.formCache[.stripe(.card)]!
        cardForm.getTextFieldElement("Card number")?.setText("4242424242424242")
        cardForm.getTextFieldElement("MM / YY").setText("1232")
        cardForm.getTextFieldElement("CVC").setText("123")
        cardForm.getTextFieldElement("ZIP").setText("65432")
        sut.selectedFormViewController?.didTapPrimaryButton()

        // ...should show the card row w/ the 'Change >' + "Visa 4242"
        sut.view.setNeedsLayout()
        sut.view.layoutIfNeeded()
        STPSnapshotVerifyView(sut.view, identifier: "card")

        // 2️⃣
        // Tapping US Bank Account...
        sut.embeddedPaymentMethodsView.getRowButton(accessibilityIdentifier: "US bank account").handleTap()
        // ...and backing out...
        sut.embeddedFormViewControllerDidCancel(sut.selectedFormViewController!)
        // ...should keep the card row selected...
        // (this tests that setting the selection back to the previous works)
        STPSnapshotVerifyView(sut.view, identifier: "us_bank_account_canceled")

        // Filling out US Bank account...
        sut.embeddedPaymentMethodsView.getRowButton(accessibilityIdentifier: "US bank account").handleTap()
        let bankForm = sut.formCache[.stripe(.USBankAccount)] as! USBankAccountPaymentMethodElement
        bankForm.getTextFieldElement("Full name").setText("Name")
        bankForm.getTextFieldElement("Email").setText("foo@bar.com")
        bankForm.linkedBank = FinancialConnectionsLinkedBank(sessionId: "123", accountId: "123", displayName: "Success", bankName: "StripeBank", last4: "6789", instantlyVerified: true)
        sut.selectedFormViewController?.didTapPrimaryButton()
        // ...should show the row w/ 'Change >' + "6789" (the last bank 4)
        sut.view.setNeedsLayout()
        sut.view.layoutIfNeeded()
        STPSnapshotVerifyView(sut.view, identifier: "us_bank_account_continue")

        // 3️⃣
        // Tapping Afterpay and filling out the form...
        sut.embeddedPaymentMethodsView.getRowButton(accessibilityIdentifier: "Afterpay").handleTap()
        let afterpayForm = sut.formCache[.stripe(.afterpayClearpay)]!
        afterpayForm.getTextFieldElement("Full name")?.setText("Tester")
        afterpayForm.getTextFieldElement("Email")?.setText("f@z.c")
        sut.selectedFormViewController?.didTapPrimaryButton()

        // ...should show the row w/ 'Change >'
        sut.view.setNeedsLayout()
        sut.view.layoutIfNeeded()
        STPSnapshotVerifyView(sut.view, identifier: "afterpay")
    }

    func testRetainsChangeButtonAcrossUpdate() async throws {
        let sut = try await EmbeddedPaymentElement.create(intentConfiguration: paymentIntentConfig, configuration: configuration)
        sut.view.autosizeHeight(width: 300)
        sut.delegate = self
        sut.presentingViewController = UIViewController()
        // Tapping card and filling out the form...
        sut.embeddedPaymentMethodsView.getRowButton(accessibilityIdentifier: "Card").handleTap()
        let cardForm = sut.formCache[.stripe(.card)]!
        cardForm.getTextFieldElement("Card number")?.setText("4242424242424242")
        cardForm.getTextFieldElement("MM / YY").setText("1232")
        cardForm.getTextFieldElement("CVC").setText("123")
        cardForm.getTextFieldElement("ZIP").setText("65432")
        sut.selectedFormViewController?.didTapPrimaryButton()

        // ...and updating the amount...
        var updatedIntentConfig = paymentIntentConfig
        updatedIntentConfig.mode = .payment(amount: 1234, currency: "USD")
        let result = await sut.update(intentConfiguration: updatedIntentConfig)
        guard case .succeeded = result else {
            XCTFail()
            return
        }
        // ...should keep the card row selected w/ 'Change >' and 'Visa 4242' displayed
        STPSnapshotVerifyView(sut.view)
    }
}
