//
//  FlowControllerSelectionRestorationTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 7/23/26.
//

@testable @_spi(STP) import StripeCore
import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
@_spi(STP) import StripePaymentsTestUtils
@_spi(STP) import StripeUICore
import XCTest

@MainActor
final class FlowControllerSelectionRestorationTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: nil)
        await AddressSpecProvider.shared.loadAddressSpecs()
        await FormSpecProvider.shared.load()
    }

    override func tearDown() {
        CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: nil)
        super.tearDown()
    }

    func testCancelingPaymentOptionsRestoresPreviousSavedPaymentMethod() {
        assertCancelingPaymentOptionsRestoresPreviousSavedPaymentMethod(orientation: .vertical)
    }

    func testCancelingHorizontalPaymentOptionsRestoresPreviousSavedPaymentMethod() {
        assertCancelingPaymentOptionsRestoresPreviousSavedPaymentMethod(orientation: .horizontal)
    }

    func testExternalRestorationParamsPreserveBillingDetails() throws {
        let externalPaymentMethod = ExternalPaymentMethod(
            type: "external_paypal",
            label: "PayPal",
            lightImageUrl: URL(string: "https://example.com/paypal.png")!,
            darkImageUrl: nil
        )
        let externalConfiguration = PaymentSheet.ExternalPaymentMethodConfiguration(
            externalPaymentMethods: ["external_paypal"],
            externalPaymentMethodConfirmHandler: { _, _ in .completed }
        )
        let externalPaymentOption = try XCTUnwrap(
            ExternalPaymentOption.from(externalPaymentMethod, configuration: externalConfiguration)
        )
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jane Doe"
        let paymentOption = PaymentOption.external(
            paymentMethod: externalPaymentOption,
            billingDetails: billingDetails
        )

        let confirmParams = try XCTUnwrap(
            paymentOption.formConfirmParamsForCancellationRestoration
        )
        XCTAssertEqual(confirmParams.paymentMethodParams.billingDetails?.name, "Jane Doe")
        XCTAssertEqual(
            confirmParams.paymentMethodType,
            .external(externalPaymentOption)
        )
    }

    func testCancelingPaymentOptionsDoesNotRestoreDeletedSavedPaymentMethod() {
        // Given a FlowController with a selected saved payment method
        let deletedPaymentMethod = STPPaymentMethod._testCard(id: "pm_deleted")
        let remainingPaymentMethod = STPPaymentMethod._testCard(id: "pm_remaining")
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(deletedPaymentMethod.stripeId), forCustomer: nil)
        let flowController = makeFlowController(savedPaymentMethods: [deletedPaymentMethod, remainingPaymentMethod])
        let completion = present(flowController, expectedDidCancel: true)

        // When the selected method is deleted while the sheet is open
        let presentedViewController = flowController.viewController as! PaymentSheetVerticalViewController
        selectSavedPaymentMethod(
            remainingPaymentMethod,
            from: [remainingPaymentMethod],
            in: presentedViewController
        )
        flowController.flowControllerViewControllerShouldClose(presentedViewController, didCancel: true)
        wait(for: [completion], timeout: 2)

        // Then the deleted method is not restored
        XCTAssertEqual(flowController.viewController.savedPaymentMethods.map(\.stripeId), [remainingPaymentMethod.stripeId])
        XCTAssertEqual(
            savedPaymentMethodID(flowController.viewController.selectedPaymentOption),
            remainingPaymentMethod.stripeId
        )
        XCTAssertEqual(CustomerPaymentOption.localDefaultPaymentMethod(for: nil), .stripeId(remainingPaymentMethod.stripeId))
    }

    func testCancelAfterReplacingLinkedBankRestoresSelectedBank() throws {
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

        let firstClose = present(flowController, expectedDidCancel: false)
        try tapRow(.new(paymentMethodType: .instantDebits), in: viewController)
        let linkedBank = makeLinkedBank()
        let bankForm = try XCTUnwrap(viewController.formCache[.instantDebits] as? InstantDebitsPaymentMethodElement)
        bankForm.setLinkedBank(linkedBank)
        flowController.flowControllerViewControllerShouldClose(viewController, didCancel: false)
        wait(for: [firstClose], timeout: 2)
        XCTAssertEqual(flowController.paymentOption?.labels.sublabel, "••••6789")

        // When the user replaces it with Card, backs out to the list, and cancels
        let secondClose = present(flowController, expectedDidCancel: true)
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

    func testHorizontalRebuildRestoresSelectedBank() throws {
        // Given a completed Instant Debits selection that must be restored
        let linkedBank = makeLinkedBank()
        let confirmParams = IntentConfirmParams(type: .instantDebits)
        confirmParams.instantDebitsLinkedBank = linkedBank
        let paymentMethod = try XCTUnwrap(linkedBank.paymentMethod.decode())
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive(isApplePayEnabled: false)
        configuration.defaultBillingDetails.email = "test@example.com"

        // When the horizontal controller is rebuilt after cancellation
        let viewController = PaymentSheetFlowControllerViewController(
            configuration: configuration,
            loadResult: makeLoadResult(orientation: .horizontal),
            analyticsHelper: ._testValue(),
            initialState: .restoringAfterCancellation(
                .init(
                    paymentOption: .saved(paymentMethod: paymentMethod, confirmParams: confirmParams),
                    formConfirmParams: confirmParams
                )
            )
        )

        // Then it reconstructs the selected bank through its form
        guard case let .saved(restoredPaymentMethod, restoredConfirmParams) = viewController.selectedPaymentOption else {
            return XCTFail("Expected the linked bank to be restored")
        }
        XCTAssertEqual(restoredPaymentMethod.stripeId, paymentMethod.stripeId)
        XCTAssertEqual(restoredConfirmParams?.instantDebitsLinkedBank?.last4, "6789")
    }

    private func makeFlowController(
        savedPaymentMethods: [STPPaymentMethod],
        orientation: PaymentSheet.PaymentMethodLayout.ResolvedLayout = .vertical
    ) -> PaymentSheet.FlowController {
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testCardValue(),
            savedPaymentMethods: savedPaymentMethods,
            paymentMethodTypes: [.stripe(.card)],
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: orientation
        )
        return PaymentSheet.FlowController(
            configuration: PaymentSheet.Configuration(),
            loadResult: loadResult,
            analyticsHelper: ._testValue()
        )
    }

    private func savedPaymentMethodID(_ paymentOption: PaymentOption?) -> String? {
        guard case let .saved(paymentMethod, _) = paymentOption else {
            return nil
        }
        return paymentMethod.stripeId
    }

    private func selectSavedPaymentMethod(
        _ paymentMethod: STPPaymentMethod,
        from paymentMethods: [STPPaymentMethod],
        in viewController: PaymentSheetVerticalViewController
    ) {
        let reorderedPaymentMethods = [paymentMethod] + paymentMethods.filter { $0.stripeId != paymentMethod.stripeId }
        let manageViewController = VerticalSavedPaymentMethodsViewController(
            configuration: viewController.configuration,
            intent: viewController.intent,
            selectedPaymentMethod: paymentMethod,
            paymentMethods: reorderedPaymentMethods,
            elementsSession: viewController.elementsSession,
            analyticsHelper: viewController.analyticsHelper,
            defaultPaymentMethod: nil
        )
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(paymentMethod.stripeId), forCustomer: nil)
        viewController.didComplete(
            viewController: manageViewController,
            with: paymentMethod,
            latestPaymentMethods: reorderedPaymentMethods,
            didTapToDismiss: false,
            defaultPaymentMethod: nil
        )
    }

    private func assertCancelingPaymentOptionsRestoresPreviousSavedPaymentMethod(
        orientation: PaymentSheet.PaymentMethodLayout.ResolvedLayout
    ) {
        // Given a FlowController with a selected saved payment method
        let firstPaymentMethod = STPPaymentMethod._testCard(id: "pm_first")
        let secondPaymentMethod = STPPaymentMethod._testCard(id: "pm_second")
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(firstPaymentMethod.stripeId), forCustomer: nil)
        let flowController = makeFlowController(
            savedPaymentMethods: [firstPaymentMethod, secondPaymentMethod],
            orientation: orientation
        )
        XCTAssertEqual(savedPaymentMethodID(flowController.viewController.selectedPaymentOption), firstPaymentMethod.stripeId)
        let completion = present(flowController, expectedDidCancel: true)

        // When a different saved payment method is selected and the sheet is canceled
        switch orientation {
        case .horizontal:
            CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(secondPaymentMethod.stripeId), forCustomer: nil)
            flowController.updateForWalletButtonsView()
        case .vertical:
            selectSavedPaymentMethod(
                secondPaymentMethod,
                from: [firstPaymentMethod, secondPaymentMethod],
                in: flowController.viewController as! PaymentSheetVerticalViewController
            )
        }
        XCTAssertEqual(savedPaymentMethodID(flowController.viewController.selectedPaymentOption), secondPaymentMethod.stripeId)
        flowController.flowControllerViewControllerShouldClose(flowController.viewController, didCancel: true)
        wait(for: [completion], timeout: 2)

        // Then the previous payment option and persisted selection are restored
        XCTAssertEqual(savedPaymentMethodID(flowController.viewController.selectedPaymentOption), firstPaymentMethod.stripeId)
        XCTAssertEqual(CustomerPaymentOption.localDefaultPaymentMethod(for: nil), .stripeId(firstPaymentMethod.stripeId))
    }

    private func makeLoadResult(
        orientation: PaymentSheet.PaymentMethodLayout.ResolvedLayout = .vertical
    ) -> PaymentSheetLoader.LoadResult {
        return PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testValue(paymentMethodTypes: ["card"], isLinkPassthroughModeEnabled: true),
            savedPaymentMethods: [],
            paymentMethodTypes: [.stripe(.card), .instantDebits],
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: orientation
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

    private func present(
        _ flowController: PaymentSheet.FlowController,
        expectedDidCancel: Bool
    ) -> XCTestExpectation {
        let closed = expectation(description: "presentPaymentOptions completion")
        flowController.presentPaymentOptions(from: UIViewController()) { didCancel in
            XCTAssertEqual(didCancel, expectedDidCancel)
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
