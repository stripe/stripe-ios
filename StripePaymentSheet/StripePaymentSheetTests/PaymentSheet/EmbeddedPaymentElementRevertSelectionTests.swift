//
//  EmbeddedPaymentElementRevertSelectionTests.swift
//  StripePaymentSheetTests
//

@_spi(STP) import StripeCore
import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
@_spi(STP) import StripePaymentsTestUtils
@_spi(STP) import StripeUICore
import XCTest

/// Covers EmbeddedPaymentElement cancel behavior headlessly: cancelling a form sheet restores the
/// previously committed selection (row and form state), including after `update()` and for
/// external payment methods. Drives the same production code paths as the (slow) selection-revert
/// UI tests via internal seams.
@MainActor
final class EmbeddedPaymentElementRevertSelectionTests: XCTestCase {

    private final class Delegate: EmbeddedPaymentElementDelegate {
        func embeddedPaymentElementDidUpdateHeight(embeddedPaymentElement: EmbeddedPaymentElement) {}
        func embeddedPaymentElementWillPresent(embeddedPaymentElement: EmbeddedPaymentElement) {}
        func embeddedPaymentElementDidUpdatePaymentOption(embeddedPaymentElement: EmbeddedPaymentElement) {}
    }

    private let delegate = Delegate()

    override func setUp() async throws {
        try await super.setUp()
        await AddressSpecProvider.shared.loadAddressSpecs()
        await FormSpecProvider.shared.load()
    }

    // MARK: - Helpers

    private func makeLoadResult(
        intentPaymentMethodTypes: [STPPaymentMethodType] = [.card],
        elementsSession: STPElementsSession = ._testValue(paymentMethodTypes: ["card"]),
        savedPaymentMethods: [STPPaymentMethod] = [],
        paymentMethodTypes: [PaymentSheet.PaymentMethodType] = [.stripe(.card)]
    ) -> PaymentSheetLoader.LoadResult {
        return PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: intentPaymentMethodTypes),
            elementsSession: elementsSession,
            savedPaymentMethods: savedPaymentMethods,
            paymentMethodTypes: paymentMethodTypes,
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: .vertical
        )
    }

    private func makeEmbeddedPaymentElement(
        configuration: EmbeddedPaymentElement.Configuration,
        loadResult: PaymentSheetLoader.LoadResult
    ) -> EmbeddedPaymentElement {
        let sut = EmbeddedPaymentElement(configuration: configuration, loadResult: loadResult, analyticsHelper: ._testValue())
        sut.delegate = delegate
        sut.presentingViewController = UIViewController()
        sut.view.autosizeHeight(width: 320)
        return sut
    }

    private func makeConfiguration(customerID: String? = nil, isApplePayEnabled: Bool = false) -> EmbeddedPaymentElement.Configuration {
        var config = EmbeddedPaymentElement.Configuration._testValue_MostPermissive(isApplePayEnabled: isApplePayEnabled)
        config.formSheetAction = .continue
        if let customerID {
            config.customer = .init(id: customerID, ephemeralKeySecret: "ek_test")
        }
        return config
    }

    private func fillCardForm(in sut: EmbeddedPaymentElement, number: String) throws {
        let cardForm = try XCTUnwrap(sut.formCache[.stripe(.card)], "No cached card form")
        cardForm.getTextFieldElement("Card number")?.setText(number)
        cardForm.getTextFieldElement("MM / YY")?.setText("1240")
        cardForm.getTextFieldElement("CVC")?.setText("123")
        cardForm.getTextFieldElement("ZIP")?.setText("65432")
    }

    // MARK: - Tests

    func testCrossRowFormCancel_revertsToCommittedRow_persistenceConsistent() throws {
        // Given Apple Pay is the committed selection and persisted default
        let customerID = "cus_epe_cross_row"
        defer { CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID) }
        let config = makeConfiguration(customerID: customerID, isApplePayEnabled: true)
        let loadResult = makeLoadResult(savedPaymentMethods: [._testCard()])
        let sut = makeEmbeddedPaymentElement(configuration: config, loadResult: loadResult)
        // handleTap runs the row's real tap closure, which also persists the default
        sut.embeddedPaymentMethodsView.getRowButton(accessibilityIdentifier: "Apple Pay").handleTap()
        XCTAssertEqual(sut.paymentOption?.label, "Apple Pay")
        XCTAssertEqual(CustomerPaymentOption.localDefaultPaymentMethod(for: customerID), .applePay)

        // When the user opens a different row's form, fills it, then cancels
        sut.embeddedPaymentMethodsView.didTap(rowButton: sut.embeddedPaymentMethodsView.getRowButton(accessibilityIdentifier: "New card"))
        try fillCardForm(in: sut, number: "5555555555554444")
        sut.embeddedFormViewControllerDidCancel(try XCTUnwrap(sut.selectedFormViewController))

        // Then the committed Apple Pay selection is restored, in memory and persistence
        XCTAssertEqual(sut.paymentOption?.label, "Apple Pay")
        XCTAssertEqual(CustomerPaymentOption.localDefaultPaymentMethod(for: customerID), .applePay)

        // And a fresh element from the same state (a "reload") derives the same selection
        let freshSut = makeEmbeddedPaymentElement(configuration: config, loadResult: loadResult)
        XCTAssertEqual(freshSut.paymentOption?.label, "Apple Pay")
    }

    func testSameRowFormCancel_afterEditingConfirmationOnlyFields_restoresCommittedInput() throws {
        // Given a completed card form was committed via Continue
        let config = makeConfiguration()
        let loadResult = makeLoadResult()
        let sut = makeEmbeddedPaymentElement(configuration: config, loadResult: loadResult)
        sut.embeddedPaymentMethodsView.didTap(rowButton: sut.embeddedPaymentMethodsView.getRowButton(accessibilityIdentifier: "Card"))
        try fillCardForm(in: sut, number: "4242424242424242")
        try XCTUnwrap(sut.selectedFormViewController).didTapPrimaryButton()
        XCTAssertEqual(sut.paymentOption?.label, "•••• 4242")

        // When the user re-opens the same row's form and edits only confirmation-only fields —
        // valid changes that don't alter the displayed payment option — then cancels
        sut.embeddedPaymentMethodsView.didTap(rowButton: sut.embeddedPaymentMethodsView.getRowButton(accessibilityIdentifier: "Card"))
        let editedForm = try XCTUnwrap(sut.formCache[.stripe(.card)])
        editedForm.getTextFieldElement("CVC")?.setText("999")
        editedForm.getTextFieldElement("MM / YY")?.setText("1141")
        sut.embeddedFormViewControllerDidCancel(try XCTUnwrap(sut.selectedFormViewController))

        // Then the committed input is restored — a later confirmation must not use the edits
        guard case .new(let confirmParams) = try XCTUnwrap(sut.selectedFormViewController).selectedPaymentOption else {
            return XCTFail("Expected the committed card to back the selection after cancel")
        }
        XCTAssertEqual(confirmParams.paymentMethodParams.card?.cvc, "123")
        XCTAssertEqual(confirmParams.paymentMethodParams.card?.expMonth, 12)
        let restoredForm = try XCTUnwrap(sut.formCache[.stripe(.card)])
        XCTAssertEqual(restoredForm.getTextFieldElement("CVC")?.text, "123")
    }

    func testSameRowFormCancel_externalPM_restoresBillingDetails() throws {
        // Given an external PM with collected billing details was committed via Continue
        let externalPaymentMethod = ExternalPaymentMethod(
            type: "external_paypal",
            label: "PayPal",
            lightImageUrl: URL(string: "https://example.com/paypal.png")!,
            darkImageUrl: nil
        )
        let externalConfig = PaymentSheet.ExternalPaymentMethodConfiguration(
            externalPaymentMethods: ["external_paypal"],
            externalPaymentMethodConfirmHandler: { _, _ in .completed }
        )
        let externalPaymentOption = try XCTUnwrap(ExternalPaymentOption.from(externalPaymentMethod, configuration: externalConfig))
        var config = makeConfiguration()
        config.externalPaymentMethodConfiguration = externalConfig
        config.billingDetailsCollectionConfiguration.name = .always
        let loadResult = makeLoadResult(
            elementsSession: ._testValue(paymentMethodTypes: ["card"], externalPaymentMethodTypes: ["external_paypal"]),
            paymentMethodTypes: [.stripe(.card), .external(externalPaymentOption)]
        )
        let sut = makeEmbeddedPaymentElement(configuration: config, loadResult: loadResult)
        sut.embeddedPaymentMethodsView.didTap(rowButton: sut.embeddedPaymentMethodsView.getRowButton(accessibilityIdentifier: "PayPal"))
        let externalForm = try XCTUnwrap(sut.formCache[.external(externalPaymentOption)])
        externalForm.getTextFieldElement("Full name")?.setText("Jane Doe")
        try XCTUnwrap(sut.selectedFormViewController).didTapPrimaryButton()
        XCTAssertEqual(sut.paymentOption?.label, "PayPal")
        XCTAssertEqual(sut.paymentOption?.billingDetails?.name, "Jane Doe")

        // When the user re-opens the same row's form, edits the name, then cancels
        sut.embeddedPaymentMethodsView.didTap(rowButton: sut.embeddedPaymentMethodsView.getRowButton(accessibilityIdentifier: "PayPal"))
        let editedForm = try XCTUnwrap(sut.formCache[.external(externalPaymentOption)])
        editedForm.getTextFieldElement("Full name")?.setText("John Smith")
        sut.embeddedFormViewControllerDidCancel(try XCTUnwrap(sut.selectedFormViewController))

        // Then the committed external PM is restored, billing details included
        XCTAssertEqual(sut.paymentOption?.label, "PayPal")
        XCTAssertEqual(sut.paymentOption?.billingDetails?.name, "Jane Doe")
        XCTAssertTrue(sut.embeddedPaymentMethodsView.getRowButton(accessibilityIdentifier: "PayPal").isSelected)
        let restoredForm = try XCTUnwrap(sut.formCache[.external(externalPaymentOption)])
        XCTAssertEqual(restoredForm.getTextFieldElement("Full name")?.text, "Jane Doe")
    }

    func testSameRowFormCancel_afterUpdate_restoresCommittedCard() async throws {
        // Given a completed card form was committed via Continue (network-backed, matching this
        // file's sibling update() tests — update() reloads via PaymentSheetLoader)
        var config = makeConfiguration()
        config.apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let intentConfig = EmbeddedPaymentElement.IntentConfiguration(mode: .payment(amount: 1000, currency: "USD"), paymentMethodTypes: ["card"]) { _, _ in
            XCTFail("Confirm handler should not be called.")
            return ""
        }
        let sut = try await EmbeddedPaymentElement.create(intentConfiguration: intentConfig, configuration: config)
        sut.delegate = delegate
        sut.presentingViewController = UIViewController()
        sut.view.autosizeHeight(width: 320)
        sut.embeddedPaymentMethodsView.didTap(rowButton: sut.embeddedPaymentMethodsView.getRowButton(accessibilityIdentifier: "Card"))
        try fillCardForm(in: sut, number: "4242424242424242")
        try XCTUnwrap(sut.selectedFormViewController).didTapPrimaryButton()
        XCTAssertEqual(sut.paymentOption?.label, "•••• 4242")

        // When update() succeeds (same form shape, so the committed card stays selected)...
        let updatedIntentConfig = EmbeddedPaymentElement.IntentConfiguration(mode: .payment(amount: 2000, currency: "USD"), paymentMethodTypes: ["card"]) { _, _ in
            XCTFail("Confirm handler should not be called.")
            return ""
        }
        let result = await sut.update(intentConfiguration: updatedIntentConfig)
        guard case .succeeded = result else {
            return XCTFail("Update failed: \(result)")
        }
        XCTAssertEqual(sut.paymentOption?.label, "•••• 4242")

        // ...and the user then edits the restored form and cancels
        sut.embeddedPaymentMethodsView.didTap(rowButton: sut.embeddedPaymentMethodsView.getRowButton(accessibilityIdentifier: "Card"))
        let editedForm = try XCTUnwrap(sut.formCache[.stripe(.card)])
        editedForm.getTextFieldElement("Card number")?.setText("5555555555554444")
        sut.embeddedFormViewControllerDidCancel(try XCTUnwrap(sut.selectedFormViewController))

        // Then the committed card is restored, not cleared
        XCTAssertEqual(sut.paymentOption?.label, "•••• 4242")
        XCTAssertTrue(sut.embeddedPaymentMethodsView.getRowButton(accessibilityIdentifier: "Card").isSelected)
    }

}
