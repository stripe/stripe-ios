//
//  FormBackedLinkedBankRevertSelectionTests.swift
//  StripePaymentSheetTests
//  Created by Nick Porter on 7/17/26.
//

@testable @_spi(STP) import StripeCore
import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
@_spi(STP) import StripePaymentsTestUtils
@_spi(STP) import StripeUICore
import XCTest

@MainActor
final class FormBackedLinkedBankRevertSelectionTests: XCTestCase {
    private final class EmbeddedDelegate: EmbeddedPaymentElementDelegate {
        func embeddedPaymentElementDidUpdateHeight(embeddedPaymentElement: EmbeddedPaymentElement) {}
        func embeddedPaymentElementWillPresent(embeddedPaymentElement: EmbeddedPaymentElement) {}
        func embeddedPaymentElementDidUpdatePaymentOption(embeddedPaymentElement: EmbeddedPaymentElement) {}
    }

    private let embeddedDelegate = EmbeddedDelegate()

    override func setUp() async throws {
        try await super.setUp()
        await AddressSpecProvider.shared.loadAddressSpecs()
        await FormSpecProvider.shared.load()
    }

    func testEmbedded_cancelAfterReplacingLinkedBank_restoresSelectedBank() throws {
        // Given a linked bank was selected from the Instant Debits form
        var configuration = EmbeddedPaymentElement.Configuration._testValue_MostPermissive(isApplePayEnabled: false)
        configuration.formSheetAction = .continue
        configuration.defaultBillingDetails.email = "test@example.com"
        let loadResult = makeLoadResult()
        let sut = EmbeddedPaymentElement(
            configuration: configuration,
            loadResult: loadResult,
            analyticsHelper: ._testValue()
        )
        sut.delegate = embeddedDelegate
        sut.presentingViewController = UIViewController()
        sut.view.autosizeHeight(width: 320)

        sut.embeddedPaymentMethodsView.didTap(
            rowButton: sut.embeddedPaymentMethodsView.getRowButton(accessibilityIdentifier: "Bank")
        )
        let linkedBank = makeLinkedBank()
        let bankForm = try XCTUnwrap(sut.formCache[.instantDebits] as? InstantDebitsPaymentMethodElement)
        bankForm.setLinkedBank(linkedBank)
        try XCTUnwrap(sut.selectedFormViewController).didTapPrimaryButton()
        XCTAssertEqual(sut.paymentOption?.label, "••••6789")

        // When the user opens the Card form and cancels it
        sut.embeddedPaymentMethodsView.didTap(
            rowButton: sut.embeddedPaymentMethodsView.getRowButton(accessibilityIdentifier: "Card")
        )
        sut.embeddedFormViewControllerDidCancel(try XCTUnwrap(sut.selectedFormViewController))

        // Then EPE restores both the Bank row and its form-backed payment option
        XCTAssertTrue(sut.embeddedPaymentMethodsView.getRowButton(accessibilityIdentifier: "Bank").isSelected)
        XCTAssertEqual(sut.paymentOption?.label, "••••6789")
    }

    func testFlowController_cancelAfterReplacingLinkedBank_restoresSelectedBank() throws {
        // Given a linked bank was selected from the Instant Debits form
        let customerID = "cus_fc_linked_bank"
        defer { CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID) }
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive(isApplePayEnabled: false)
        configuration.customer = .init(id: customerID, ephemeralKeySecret: "ek_test")
        configuration.defaultBillingDetails.email = "test@example.com"
        let loadResult = makeLoadResult()
        let flowController = PaymentSheet.FlowController(
            configuration: configuration,
            loadResult: loadResult,
            analyticsHelper: ._testValue()
        )
        let viewController = try XCTUnwrap(flowController.viewController as? PaymentSheetVerticalViewController)
        viewController.loadViewIfNeeded()

        let firstClose = present(flowController)
        try tapRow(.new(paymentMethodType: .instantDebits), in: viewController)
        let linkedBank = makeLinkedBank()
        let bankForm = try XCTUnwrap(viewController.formCache[.instantDebits] as? InstantDebitsPaymentMethodElement)
        bankForm.setLinkedBank(linkedBank)
        flowController.flowControllerViewControllerShouldClose(viewController, didCancel: false)
        wait(for: [firstClose], timeout: 2)
        XCTAssertEqual(flowController.paymentOption?.labels.sublabel, "••••6789")

        // When the user replaces it with Card, backs out to the list, and cancels
        let secondClose = present(flowController)
        viewController.sheetNavigationBarDidBack(viewController.navigationBar)
        try tapRow(.new(paymentMethodType: .stripe(.card)), in: viewController)
        viewController.sheetNavigationBarDidBack(viewController.navigationBar)
        viewController.didTapOrSwipeToDismiss()
        wait(for: [secondClose], timeout: 2)

        // Then FlowController restores the selected linked-bank form, not a saved-PM row
        let restoredViewController = try XCTUnwrap(flowController.viewController as? PaymentSheetVerticalViewController)
        XCTAssertEqual(restoredViewController.paymentMethodFormViewController?.paymentMethodType, .instantDebits)
        XCTAssertEqual(flowController.paymentOption?.labels.sublabel, "••••6789")
        XCTAssertNil(CustomerPaymentOption.localDefaultPaymentMethod(for: customerID))
    }

    private func makeLoadResult() -> PaymentSheetLoader.LoadResult {
        return PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testValue(paymentMethodTypes: ["card"], isLinkPassthroughModeEnabled: true),
            savedPaymentMethods: [],
            paymentMethodTypes: [.stripe(.card), .instantDebits],
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: .vertical
        )
    }

    private func makeLinkedBank() -> InstantDebitsLinkedBank {
        let paymentMethod = STPPaymentMethod._testUSBankAccount()
        var linkBankPaymentMethod = LinkBankPaymentMethod(id: paymentMethod.stripeId)
        linkBankPaymentMethod._allResponseFieldsStorage = NonEncodableParameters(
            storage: paymentMethod.allResponseFields as? [String: Any] ?? [:]
        )
        return InstantDebitsLinkedBank(
            paymentMethod: linkBankPaymentMethod,
            bankName: "StripeBank",
            last4: "6789",
            linkMode: .linkPaymentMethod,
            incentiveEligible: false,
            linkAccountSessionId: "fcsess_123"
        )
    }

    private func present(_ flowController: PaymentSheet.FlowController) -> XCTestExpectation {
        let closed = expectation(description: "presentPaymentOptions completion")
        flowController.presentPaymentOptions(from: UIViewController()) {
            closed.fulfill()
        }
        return closed
    }

    private func tapRow(_ type: RowButtonType, in viewController: PaymentSheetVerticalViewController) throws {
        let row = try XCTUnwrap(
            viewController.paymentMethodListViewController?.rowButtons.first(where: { $0.type == type }),
            "No row button of type \(type)"
        )
        viewController.paymentMethodListViewController?.didTap(rowButton: row, selection: row.type)
    }
}
