//
//  PaymentSheetFlowControllerHorizontalRevertSelectionTests.swift
//  StripePaymentSheetTests
//

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
@_spi(STP) import StripePaymentsTestUtils
@_spi(STP) import StripeUICore
import XCTest

/// Covers FlowController (horizontal layout) cancel behavior headlessly: the selection and locally
/// persisted default revert to their at-presentation values on cancel. Drives the same production
/// code paths as the (slow) selection-revert UI tests via internal seams.
final class PaymentSheetFlowControllerHorizontalRevertSelectionTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        let expectation = expectation(description: "specs loaded")
        AddressSpecProvider.shared.loadAddressSpecs {
            FormSpecProvider.shared.load { _ in
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
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
            paymentMethodOrientation: .horizontal
        )
    }

    private func makeConfiguration(customerID: String, isApplePayEnabled: Bool = false) -> PaymentSheet.Configuration {
        var config = PaymentSheet.Configuration._testValue_MostPermissive(isApplePayEnabled: isApplePayEnabled)
        config.customer = .init(id: customerID, ephemeralKeySecret: "ek_test")
        return config
    }

    private func makeFlowController(configuration: PaymentSheet.Configuration, loadResult: PaymentSheetLoader.LoadResult) -> (PaymentSheet.FlowController, PaymentSheetFlowControllerViewController) {
        let flowController = PaymentSheet.FlowController(configuration: configuration, loadResult: loadResult, analyticsHelper: ._testValue())
        let vc = flowController.viewController as! PaymentSheetFlowControllerViewController
        vc.loadViewIfNeeded()
        return (flowController, vc)
    }

    private func present(_ flowController: PaymentSheet.FlowController) -> XCTestExpectation {
        let closed = expectation(description: "presentPaymentOptions completion")
        flowController.presentPaymentOptions(from: UIViewController()) {
            closed.fulfill()
        }
        return closed
    }

    /// Simulates tapping the tile for the given selection in the saved-PM carousel.
    private func tapTile(_ target: CustomerPaymentOption, in vc: PaymentSheetFlowControllerViewController) throws {
        let savedOptions = vc.savedPaymentOptionsViewController
        savedOptions.loadViewIfNeeded()
        let index = try XCTUnwrap(savedOptions.viewModels.firstIndex(where: { $0 == target }), "No tile for \(target)")
        let dummyCollectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        savedOptions.collectionView(dummyCollectionView, didSelectItemAt: IndexPath(item: index, section: 0))
    }

    private func fillCardForm(in vc: PaymentSheetFlowControllerViewController, number: String) {
        let form = vc.addPaymentMethodViewController.paymentMethodFormViewController.form
        form.getTextFieldElement("Card number")?.setText(number)
        form.getTextFieldElement("MM / YY")?.setText("1240")
        form.getTextFieldElement("CVC")?.setText("123")
        form.getTextFieldElement("ZIP")?.setText("65432")
    }

    private func cardFormNumberText(in vc: PaymentSheetFlowControllerViewController) -> String? {
        return vc.addPaymentMethodViewController.paymentMethodFormViewController.form.getTextFieldElement("Card number")?.text
    }

    // MARK: - Tests

    func testCancelRevertsToSavedPM_memoryAndPersistence() throws {
        // Given a saved card is the selection and persisted default at presentation
        let customerID = "cus_fch_saved"
        defer { CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID) }
        let cardA = STPPaymentMethod._testCard()
        let bank = STPPaymentMethod._testUSBankAccount()
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(cardA.stripeId), forCustomer: customerID)
        let config = makeConfiguration(customerID: customerID)
        let loadResult = makeLoadResult(savedPaymentMethods: [cardA, bank])
        let (flowController, vc) = makeFlowController(configuration: config, loadResult: loadResult)
        XCTAssertEqual(flowController.paymentOption?.label, "•••• 4242")

        // When the user selects the bank tile (mandate keeps the sheet open) and cancels
        let closed = present(flowController)
        try tapTile(.stripeId(bank.stripeId), in: vc)
        XCTAssertEqual(CustomerPaymentOption.localDefaultPaymentMethod(for: customerID), .stripeId(bank.stripeId))
        vc.didTapOrSwipeToDismiss()
        wait(for: [closed], timeout: 2)

        // Then the selection and persisted default revert to the saved card
        XCTAssertEqual(flowController.paymentOption?.label, "•••• 4242")
        XCTAssertEqual(CustomerPaymentOption.localDefaultPaymentMethod(for: customerID), .stripeId(cardA.stripeId))

        // And a fresh controller from the same state (a "reload") derives the same selection
        let (freshFlowController, _) = makeFlowController(configuration: config, loadResult: loadResult)
        XCTAssertEqual(freshFlowController.paymentOption?.label, "•••• 4242")
    }

    func testCancel_preservesPersistedDefaultFilteredOutOfThisSheet() throws {
        // Given the persisted default references a saved payment method that still exists but is
        // filtered out of this sheet's display (e.g. a bank account with delayed PMs disabled)
        let customerID = "cus_fch_filtered_default"
        defer { CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID) }
        let cardA = STPPaymentMethod._testCard()
        let hiddenBank = STPPaymentMethod._testUSBankAccount()
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(hiddenBank.stripeId), forCustomer: customerID)
        let config = makeConfiguration(customerID: customerID)
        let loadResult = makeLoadResult(savedPaymentMethods: [cardA]) // The bank is filtered out
        let (flowController, vc) = makeFlowController(configuration: config, loadResult: loadResult)

        // When the user presents the sheet and immediately cancels
        let closed = present(flowController)
        vc.didTapOrSwipeToDismiss()
        wait(for: [closed], timeout: 2)

        // Then the valid persisted default must not be erased — it wasn't deleted, just not shown
        XCTAssertEqual(CustomerPaymentOption.localDefaultPaymentMethod(for: customerID), .stripeId(hiddenBank.stripeId))
    }

    func testCancelAfterFilledAddForm_revertsToSavedTile() throws {
        // Given a saved card is selected at presentation
        let customerID = "cus_fch_add_form"
        defer { CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID) }
        let cardA = STPPaymentMethod._testCard()
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(cardA.stripeId), forCustomer: customerID)
        let config = makeConfiguration(customerID: customerID)
        let loadResult = makeLoadResult(savedPaymentMethods: [cardA])
        let (flowController, vc) = makeFlowController(configuration: config, loadResult: loadResult)

        // When the user goes to the add screen, fills the card form, and cancels
        let closed = present(flowController)
        vc.didUpdateSelection(viewController: vc.savedPaymentOptionsViewController, paymentMethodSelection: .add)
        XCTAssertEqual(vc.mode, .addingNew)
        fillCardForm(in: vc, number: "5555555555554444")
        vc.didTapOrSwipeToDismiss()
        wait(for: [closed], timeout: 2)

        // Then the selection reverts to the saved card tile
        XCTAssertEqual(flowController.paymentOption?.label, "•••• 4242")
        XCTAssertEqual(vc.mode, .selectingSaved)
    }

    func testCancelAfterEditingCommittedForm_restoresCommittedCard() throws {
        // Given a completed card form was committed via Continue (no saved PMs/wallets → add screen)
        let customerID = "cus_fch_edit_committed"
        defer { CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID) }
        let config = makeConfiguration(customerID: customerID)
        let loadResult = makeLoadResult()
        let (flowController, vc) = makeFlowController(configuration: config, loadResult: loadResult)

        let firstClose = present(flowController)
        fillCardForm(in: vc, number: "4242424242424242")
        flowController.flowControllerViewControllerShouldClose(vc, didCancel: false)
        wait(for: [firstClose], timeout: 2)
        XCTAssertEqual(flowController.paymentOption?.label, "•••• 4242")

        // When the user re-opens, edits the committed form, and cancels
        let secondClose = present(flowController)
        vc.addPaymentMethodViewController.paymentMethodFormViewController.form.getTextFieldElement("Card number")?.setText("5555555555554444")
        vc.didTapOrSwipeToDismiss()
        wait(for: [secondClose], timeout: 2)

        // Then the committed card is restored, including the form contents
        XCTAssertEqual(flowController.paymentOption?.label, "•••• 4242")
        XCTAssertEqual(cardFormNumberText(in: vc), "4242424242424242")
    }

    func testCancelAfterSwitchingFormType_restoresCardForm() throws {
        // Given a completed card form was committed via Continue
        let customerID = "cus_fch_switch_type"
        defer { CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID) }
        let config = makeConfiguration(customerID: customerID)
        let loadResult = makeLoadResult(
            intentPaymentMethodTypes: [.card, .klarna],
            elementsSession: ._testValue(paymentMethodTypes: ["card", "klarna"]),
            paymentMethodTypes: [.stripe(.card), .stripe(.klarna)]
        )
        let (flowController, vc) = makeFlowController(configuration: config, loadResult: loadResult)

        let firstClose = present(flowController)
        fillCardForm(in: vc, number: "4242424242424242")
        flowController.flowControllerViewControllerShouldClose(vc, didCancel: false)
        wait(for: [firstClose], timeout: 2)
        XCTAssertEqual(flowController.paymentOption?.label, "•••• 4242")

        // When the user re-opens, switches the form to another payment method type, and cancels
        let secondClose = present(flowController)
        vc.addPaymentMethodViewController.paymentMethodTypesView.select(.stripe(.klarna))
        XCTAssertEqual(vc.addPaymentMethodViewController.paymentMethodFormViewController.paymentMethodType, .stripe(.klarna))
        vc.didTapOrSwipeToDismiss()
        wait(for: [secondClose], timeout: 2)

        // Then the committed card is restored, including the displayed form type and contents
        XCTAssertEqual(flowController.paymentOption?.label, "•••• 4242")
        XCTAssertEqual(vc.addPaymentMethodViewController.paymentMethodFormViewController.paymentMethodType, .stripe(.card))
        XCTAssertEqual(vc.addPaymentMethodViewController.paymentMethodTypesView.selected, .stripe(.card))
        XCTAssertEqual(cardFormNumberText(in: vc), "4242424242424242")
    }

    func testServerDefault_cancelRevertsToSnapshotNotServerDefault() throws {
        // Given the server-side default feature is enabled and the server default is the bank...
        let customerID = "cus_fch_server_default"
        defer { CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID) }
        let cardA = STPPaymentMethod._testCard()
        let bank = STPPaymentMethod._testUSBankAccount()
        let config = makeConfiguration(customerID: customerID, isApplePayEnabled: true)
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            defaultPaymentMethod: bank.stripeId,
            paymentMethods: [cardA.allResponseFields, bank.allResponseFields],
            allowsSetAsDefaultPM: true
        )
        let loadResult = makeLoadResult(elementsSession: elementsSession, savedPaymentMethods: [cardA, bank])
        let (flowController, vc) = makeFlowController(configuration: config, loadResult: loadResult)

        // ...and Apple Pay was committed (tapping its tile commits and closes)
        let firstClose = present(flowController)
        try tapTile(.applePay, in: vc)
        wait(for: [firstClose], timeout: 2)
        XCTAssertEqual(flowController.paymentOption?.label, "Apple Pay")

        // When the user re-opens, selects the bank tile, then cancels
        let secondClose = present(flowController)
        try tapTile(.stripeId(bank.stripeId), in: vc)
        vc.didTapOrSwipeToDismiss()
        wait(for: [secondClose], timeout: 2)

        // Then the snapshotted Apple Pay selection is restored — not the server-side default
        XCTAssertEqual(flowController.paymentOption?.label, "Apple Pay")
    }

    func testCancelAfterFillingFormWithNoneSelected_revertsToNone() throws {
        // Given nothing is selected at presentation (no saved PMs or wallets → add screen)
        let customerID = "cus_fch_none"
        defer { CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID) }
        let config = makeConfiguration(customerID: customerID)
        let loadResult = makeLoadResult()
        let (flowController, vc) = makeFlowController(configuration: config, loadResult: loadResult)
        XCTAssertNil(flowController.paymentOption)

        // When the user fills out the card form completely and cancels
        let closed = present(flowController)
        fillCardForm(in: vc, number: "4242424242424242")
        XCTAssertNotNil(vc.selectedPaymentOption) // flowController.paymentOption only refreshes at close
        vc.didTapOrSwipeToDismiss()
        wait(for: [closed], timeout: 2)

        // Then the abandoned form entry is not returned as the selection
        XCTAssertNil(flowController.paymentOption)
    }

    func testRevertSelectionToLinkedBank_restoresFormNotCarousel() throws {
        // Given a controller offering card + Instant Debits, and a snapshotted linked-bank selection
        // (Instant Debits forms create their payment method in the bank-auth flow and return it as
        // `.saved` — it's form-backed, not a carousel tile)
        let customerID = "cus_fch_linked_bank"
        defer { CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID) }
        var config = makeConfiguration(customerID: customerID)
        config.defaultBillingDetails.email = "test@example.com" // The Instant Debits form requires an email
        let loadResult = makeLoadResult(
            elementsSession: ._testValue(paymentMethodTypes: ["card"], isLinkPassthroughModeEnabled: true),
            paymentMethodTypes: [.stripe(.card), .instantDebits]
        )
        let (_, vc) = makeFlowController(configuration: config, loadResult: loadResult)
        let paymentMethod = STPPaymentMethod._testUSBankAccount()
        // Give the linked-bank payment method real response fields so it can be re-decoded when the
        // form is rebuilt, like a payment method created by the real bank-auth flow
        var linkBankPaymentMethod = LinkBankPaymentMethod(id: paymentMethod.stripeId)
        linkBankPaymentMethod._allResponseFieldsStorage = NonEncodableParameters(storage: paymentMethod.allResponseFields as? [String: Any] ?? [:])
        let confirmParams = IntentConfirmParams(type: .instantDebits)
        confirmParams.instantDebitsLinkedBank = InstantDebitsLinkedBank(
            paymentMethod: linkBankPaymentMethod,
            bankName: "StripeBank",
            last4: "6789",
            linkMode: .linkPaymentMethod,
            incentiveEligible: false,
            linkAccountSessionId: "fcsess_123"
        )

        // When reverting to it (e.g. the user cancels after abandoning a different selection)
        vc.revertSelection(to: .saved(paymentMethod: paymentMethod, confirmParams: confirmParams))

        // Then the linked-bank form is restored — not a saved-PM carousel selection
        XCTAssertEqual(vc.mode, .addingNew)
        XCTAssertEqual(vc.addPaymentMethodViewController.paymentMethodFormViewController.paymentMethodType, .instantDebits)
        guard case .saved(let restored, _) = vc.selectedPaymentOption else {
            return XCTFail("Expected the linked-bank selection to be restored, got \(String(describing: vc.selectedPaymentOption))")
        }
        XCTAssertEqual(restored.stripeId, paymentMethod.stripeId)
    }

    func testRecreatedViewController_opensFormBackedSelectionInRestoredForm() throws {
        // Pins a deliberate behavior change: when the view controller is re-created with a
        // form-backed previous selection (as FlowController.update() does), it opens in the restored
        // form (.addingNew) rather than the saved list — the list has no tile for these selections
        // and previously dropped them silently.
        let customerID = "cus_fch_update_form_backed"
        defer { CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID) }
        let config = makeConfiguration(customerID: customerID)
        let loadResult = makeLoadResult(
            elementsSession: ._testValue(paymentMethodTypes: ["card"], isLinkPassthroughModeEnabled: true),
            savedPaymentMethods: [STPPaymentMethod._testCard()] // Saved PMs exist, so the old code chose .selectingSaved
        )
        let confirmParams = IntentConfirmParams(type: .stripe(.card))
        confirmParams.paymentMethodParams.card = STPPaymentMethodCardParams()
        confirmParams.paymentMethodParams.card?.number = "4242424242424242"
        confirmParams.paymentMethodParams.card?.expMonth = 12
        confirmParams.paymentMethodParams.card?.expYear = 40
        confirmParams.paymentMethodParams.card?.cvc = "123"
        confirmParams.setDefaultBillingDetailsIfNecessary(for: config)
        let signupOption = PaymentSheet.LinkConfirmOption.signUp(
            brand: .link,
            account: PaymentSheetLinkAccount(
                email: "user@example.com",
                session: LinkStubs.consumerSession(),
                publishableKey: nil,
                displayablePaymentDetails: nil,
                apiClient: STPAPIClient(publishableKey: STPTestingDefaultPublishableKey),
                useMobileEndpoints: false,
                canSyncAttestationState: false
            ),
            phoneNumber: nil,
            consentAction: .checkbox_v0,
            legalName: nil,
            intentConfirmParams: confirmParams
        )

        // When the VC is re-created with the committed inline Link signup as the previous option
        let vc = PaymentSheetFlowControllerViewController(
            configuration: config,
            loadResult: loadResult,
            analyticsHelper: ._testValue(),
            previousPaymentOption: .link(option: signupOption)
        )
        vc.loadViewIfNeeded()

        // Then it opens on the restored form, not the saved list
        XCTAssertEqual(vc.mode, .addingNew)
        XCTAssertEqual(cardFormNumberText(in: vc), "4242424242424242")
    }

    func testCancelRevertsLinkTileSelection() throws {
        // Given Link was committed (tapping its tile commits and closes)
        let customerID = "cus_fch_link"
        defer { CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID) }
        let cardA = STPPaymentMethod._testCard()
        let bank = STPPaymentMethod._testUSBankAccount()
        let config = makeConfiguration(customerID: customerID)
        let loadResult = makeLoadResult(
            elementsSession: ._testValue(paymentMethodTypes: ["card"], isLinkPassthroughModeEnabled: true),
            savedPaymentMethods: [cardA, bank]
        )
        let (flowController, vc) = makeFlowController(configuration: config, loadResult: loadResult)

        let firstClose = present(flowController)
        try tapTile(.link, in: vc)
        wait(for: [firstClose], timeout: 2)
        XCTAssertEqual(flowController.paymentOption?.label, "Link")

        // When the user re-opens, selects the bank tile, then cancels
        let secondClose = present(flowController)
        try tapTile(.stripeId(bank.stripeId), in: vc)
        vc.didTapOrSwipeToDismiss()
        wait(for: [secondClose], timeout: 2)

        // Then Link is restored, in memory and persistence
        XCTAssertEqual(flowController.paymentOption?.label, "Link")
        XCTAssertEqual(CustomerPaymentOption.localDefaultPaymentMethod(for: customerID), .link)
    }
}
