//
//  PaymentSheetFlowControllerVerticalRevertSelectionTests.swift
//  StripePaymentSheetTests
//

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
@_spi(STP) import StripePaymentsTestUtils
@_spi(STP) import StripeUICore
import XCTest

/// Covers FlowController (vertical layout) cancel behavior headlessly: the selection and locally
/// persisted default revert to their at-presentation values on cancel. Drives the same production
/// code paths as the (slow) selection-revert UI tests via internal seams.
final class PaymentSheetFlowControllerVerticalRevertSelectionTests: XCTestCase {

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
        intentPaymentMethodTypes: [STPPaymentMethodType] = [.card, .cashApp],
        elementsSession: STPElementsSession = ._testValue(paymentMethodTypes: ["card", "cashapp"]),
        savedPaymentMethods: [STPPaymentMethod] = [],
        paymentMethodTypes: [PaymentSheet.PaymentMethodType] = [.stripe(.card), .stripe(.cashApp)]
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

    private func makeConfiguration(customerID: String, isApplePayEnabled: Bool = false) -> PaymentSheet.Configuration {
        var config = PaymentSheet.Configuration._testValue_MostPermissive(isApplePayEnabled: isApplePayEnabled)
        config.customer = .init(id: customerID, ephemeralKeySecret: "ek_test")
        return config
    }

    private func makeFlowController(configuration: PaymentSheet.Configuration, loadResult: PaymentSheetLoader.LoadResult) -> (PaymentSheet.FlowController, PaymentSheetVerticalViewController) {
        let flowController = PaymentSheet.FlowController(configuration: configuration, loadResult: loadResult, analyticsHelper: ._testValue())
        let vc = flowController.viewController as! PaymentSheetVerticalViewController
        vc.loadViewIfNeeded()
        return (flowController, vc)
    }

    /// Presents the sheet headlessly (which captures the selection snapshot) and returns an
    /// expectation that fulfills when the sheet closes.
    private func present(_ flowController: PaymentSheet.FlowController) -> XCTestExpectation {
        let closed = expectation(description: "presentPaymentOptions completion")
        flowController.presentPaymentOptions(from: UIViewController()) {
            closed.fulfill()
        }
        return closed
    }

    private func tapRow(_ type: RowButtonType, in vc: PaymentSheetVerticalViewController) throws {
        let row = try XCTUnwrap(
            vc.paymentMethodListViewController?.rowButtons.first(where: { $0.type == type }),
            "No row button of type \(type)"
        )
        vc.paymentMethodListViewController?.didTap(rowButton: row, selection: row.type)
    }

    private func fillCardForm(in vc: PaymentSheetVerticalViewController, number: String) throws {
        let cardForm = try XCTUnwrap(vc.formCache[.stripe(.card)], "No cached card form")
        cardForm.getTextFieldElement("Card number")?.setText(number)
        cardForm.getTextFieldElement("MM / YY")?.setText("1240")
        cardForm.getTextFieldElement("CVC")?.setText("123")
        cardForm.getTextFieldElement("ZIP")?.setText("65432")
    }

    // MARK: - Tests

    func testCancelRevertsToSavedPM_memoryAndPersistence() throws {
        // Given a saved card is the selection and persisted default at presentation
        let customerID = "cus_fcv_saved"
        defer { CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID) }
        let cardA = STPPaymentMethod._testCard()
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(cardA.stripeId), forCustomer: customerID)
        let config = makeConfiguration(customerID: customerID)
        let loadResult = makeLoadResult(savedPaymentMethods: [cardA])
        let (flowController, vc) = makeFlowController(configuration: config, loadResult: loadResult)
        XCTAssertEqual(flowController.paymentOption?.label, "•••• 4242")

        // When the user selects Cash App Pay and cancels
        let closed = present(flowController)
        try tapRow(.new(paymentMethodType: .stripe(.cashApp)), in: vc)
        vc.didTapOrSwipeToDismiss()
        wait(for: [closed], timeout: 2)

        // Then the selection and persisted default revert to the saved card
        XCTAssertEqual(flowController.paymentOption?.label, "•••• 4242")
        XCTAssertEqual(CustomerPaymentOption.localDefaultPaymentMethod(for: customerID), .stripeId(cardA.stripeId))
        guard case .saved(let selected) = vc.paymentMethodListViewController?.currentSelection else {
            return XCTFail("Expected the saved card to be selected after cancel")
        }
        XCTAssertEqual(selected.stripeId, cardA.stripeId)

        // And a fresh controller from the same state (a "reload") derives the same selection
        let (freshFlowController, _) = makeFlowController(configuration: config, loadResult: loadResult)
        XCTAssertEqual(freshFlowController.paymentOption?.label, "•••• 4242")
    }

    func testCancelAfterFillingNewCardForm_revertsToSavedPM_formDraftPreserved() throws {
        // Given a saved card is selected at presentation
        let customerID = "cus_fcv_form_draft"
        defer { CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID) }
        let cardA = STPPaymentMethod._testCard()
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(cardA.stripeId), forCustomer: customerID)
        let config = makeConfiguration(customerID: customerID)
        let loadResult = makeLoadResult(savedPaymentMethods: [cardA])
        let (flowController, vc) = makeFlowController(configuration: config, loadResult: loadResult)

        // When the user opens the new-card form, fills it, and cancels
        let closed = present(flowController)
        try tapRow(.new(paymentMethodType: .stripe(.card)), in: vc)
        try fillCardForm(in: vc, number: "5555555555554444")
        vc.didTapOrSwipeToDismiss()
        wait(for: [closed], timeout: 2)

        // Then the selection reverts to the saved card...
        XCTAssertEqual(flowController.paymentOption?.label, "•••• 4242")
        // ...but the in-progress draft is preserved for if the user returns
        let cardForm = try XCTUnwrap(vc.formCache[.stripe(.card)])
        XCTAssertEqual(cardForm.getTextFieldElement("Card number")?.text, "5555555555554444")
    }

    func testCancelAfterEditingCommittedForm_restoresCommittedCard() throws {
        // Given a completed card form was committed via Continue
        let customerID = "cus_fcv_edit_committed"
        defer { CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID) }
        let config = makeConfiguration(customerID: customerID)
        let loadResult = makeLoadResult()
        let (flowController, vc) = makeFlowController(configuration: config, loadResult: loadResult)

        let firstClose = present(flowController)
        try tapRow(.new(paymentMethodType: .stripe(.card)), in: vc)
        try fillCardForm(in: vc, number: "4242424242424242")
        flowController.flowControllerViewControllerShouldClose(vc, didCancel: false)
        wait(for: [firstClose], timeout: 2)
        XCTAssertEqual(flowController.paymentOption?.label, "•••• 4242")

        // When the user re-opens, edits the committed form, and cancels
        let secondClose = present(flowController)
        let cardForm = try XCTUnwrap(vc.formCache[.stripe(.card)])
        cardForm.getTextFieldElement("Card number")?.setText("5555555555554444")
        vc.didTapOrSwipeToDismiss()
        wait(for: [secondClose], timeout: 2)

        // Then the committed card is restored, including the form contents
        XCTAssertEqual(flowController.paymentOption?.label, "•••• 4242")
        let restoredForm = try XCTUnwrap(vc.formCache[.stripe(.card)])
        XCTAssertEqual(restoredForm.getTextFieldElement("Card number")?.text, "4242424242424242")
    }

    func testCancelAfterBackingOutOfExternalForm_restoresBillingDetails() throws {
        // Given an external PM with collected billing details was committed via Continue
        let customerID = "cus_fcv_external"
        defer { CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID) }
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
        var config = makeConfiguration(customerID: customerID)
        config.externalPaymentMethodConfiguration = externalConfig
        config.billingDetailsCollectionConfiguration.name = .always
        let loadResult = makeLoadResult(
            intentPaymentMethodTypes: [.card],
            elementsSession: ._testValue(paymentMethodTypes: ["card"], externalPaymentMethodTypes: ["external_paypal"]),
            paymentMethodTypes: [.stripe(.card), .external(externalPaymentOption)]
        )
        let (flowController, vc) = makeFlowController(configuration: config, loadResult: loadResult)

        let firstClose = present(flowController)
        try tapRow(.new(paymentMethodType: .external(externalPaymentOption)), in: vc)
        let externalForm = try XCTUnwrap(vc.formCache[.external(externalPaymentOption)])
        externalForm.getTextFieldElement("Full name")?.setText("Jane Doe")
        flowController.flowControllerViewControllerShouldClose(vc, didCancel: false)
        wait(for: [firstClose], timeout: 2)
        guard case .external(_, let committedBilling) = vc.selectedPaymentOption else {
            return XCTFail("Expected an external payment option, got \(String(describing: vc.selectedPaymentOption))")
        }
        XCTAssertEqual(committedBilling.name, "Jane Doe")

        // When the user re-opens, backs out of the form to the list (which downgrades the
        // selection to the row without its collected billing details), and cancels
        let secondClose = present(flowController)
        vc.sheetNavigationBarDidBack(vc.navigationBar)
        vc.didTapOrSwipeToDismiss()
        wait(for: [secondClose], timeout: 2)

        // Then the restored selection is equivalent to the committed one, billing details included
        guard case .external(_, let restoredBilling) = vc.selectedPaymentOption else {
            return XCTFail("Expected an external payment option after cancel, got \(String(describing: vc.selectedPaymentOption))")
        }
        XCTAssertEqual(restoredBilling.name, "Jane Doe")
    }

    func testRevertSelectionToLinkedBank_restoresFormOverList() throws {
        // Given a controller offering card + Instant Debits with Link enabled, and a snapshotted
        // linked-bank selection (created by the bank-auth flow, so not in savedPaymentMethods)
        let customerID = "cus_fcv_linked_bank"
        defer { CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID) }
        var config = makeConfiguration(customerID: customerID)
        config.defaultBillingDetails.email = "test@example.com" // The Instant Debits form requires an email
        let loadResult = makeLoadResult(
            intentPaymentMethodTypes: [.card],
            elementsSession: ._testValue(paymentMethodTypes: ["card"], isLinkPassthroughModeEnabled: true),
            paymentMethodTypes: [.stripe(.card), .instantDebits]
        )
        let (_, vc) = makeFlowController(configuration: config, loadResult: loadResult)
        let paymentMethod = STPPaymentMethod._testUSBankAccount()
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

        // When reverting to it after the user backed out to the list and cancelled
        vc.revertSelection(to: .saved(paymentMethod: paymentMethod, confirmParams: confirmParams))

        // Then the linked-bank form is restored and returned as the selection
        guard case .saved(let restored, _) = vc.selectedPaymentOption else {
            return XCTFail("Expected the linked-bank selection to be restored, got \(String(describing: vc.selectedPaymentOption))")
        }
        XCTAssertEqual(restored.stripeId, paymentMethod.stripeId)
    }

    func testRevertSelectionToInlineLinkSignup_discardsEditedFormCache() throws {
        // Given a committed inline Link signup (card A + signup) and a form cache holding edits (card B)
        let customerID = "cus_fcv_link_signup"
        defer { CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID) }
        let config = makeConfiguration(customerID: customerID)
        let loadResult = makeLoadResult(
            intentPaymentMethodTypes: [.card],
            elementsSession: ._testValue(paymentMethodTypes: ["card"], isLinkPassthroughModeEnabled: true),
            paymentMethodTypes: [.stripe(.card)]
        )
        let (flowController, vc) = makeFlowController(configuration: config, loadResult: loadResult)
        _ = flowController // keep alive
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
        // The user edited the (form-only) card form to card B before cancelling
        try fillCardForm(in: vc, number: "5555555555554444")

        // When reverting to the committed signup selection
        vc.revertSelection(to: .link(option: signupOption))

        // Then the edits are discarded and the form is rebuilt from the committed input
        let restoredForm = try XCTUnwrap(vc.formCache[.stripe(.card)])
        XCTAssertEqual(restoredForm.getTextFieldElement("Card number")?.text, "4242424242424242")
    }

    func testFormOnly_cancelAfterFillingForm_revertsToNone() throws {
        // Given a single-LPM configuration where the form is the only content
        let customerID = "cus_fcv_form_only"
        defer { CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID) }
        let config = makeConfiguration(customerID: customerID)
        let loadResult = makeLoadResult(
            intentPaymentMethodTypes: [.card],
            elementsSession: ._testValue(paymentMethodTypes: ["card"]),
            paymentMethodTypes: [.stripe(.card)]
        )
        let (flowController, vc) = makeFlowController(configuration: config, loadResult: loadResult)
        XCTAssertNil(flowController.paymentOption)

        // When the user fills out the card form completely and cancels
        let closed = present(flowController)
        try fillCardForm(in: vc, number: "4242424242424242")
        XCTAssertNotNil(vc.selectedPaymentOption) // flowController.paymentOption only refreshes at close
        vc.didTapOrSwipeToDismiss()
        wait(for: [closed], timeout: 2)

        // Then the abandoned form entry is not returned as the selection
        XCTAssertNil(flowController.paymentOption)
    }

    @MainActor
    func testCancelAfterEditingCoBrandedCardBrand_stillRestoresSavedCard() throws {
        // Given a co-branded saved card (displaying Visa) is the selection and persisted default
        let customerID = "cus_fcv_cbc_edit"
        defer { CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID) }
        let cardDisplayingVisa = STPPaymentMethod._testCardCoBranded(displayBrand: "visa", networks: ["visa", "cartes_bancaires"])
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(cardDisplayingVisa.stripeId), forCustomer: customerID)
        let config = makeConfiguration(customerID: customerID)
        let loadResult = makeLoadResult(savedPaymentMethods: [cardDisplayingVisa])
        let (flowController, vc) = makeFlowController(configuration: config, loadResult: loadResult)
        XCTAssertEqual(flowController.paymentOption?.label, "•••• 4242")

        // When the user edits the card's preferred network while the sheet is presented...
        let closed = present(flowController)
        let cardDisplayingCartesBancaires = STPPaymentMethod._testCardCoBranded(displayBrand: "cartes_bancaires", networks: ["visa", "cartes_bancaires"])
        let manageVC = VerticalSavedPaymentMethodsViewController(
            configuration: config,
            intent: ._testValue(),
            selectedPaymentMethod: cardDisplayingCartesBancaires,
            paymentMethods: [cardDisplayingCartesBancaires],
            elementsSession: ._testCardValue(),
            analyticsHelper: ._testValue(),
            defaultPaymentMethod: nil
        )
        vc.didComplete(viewController: manageVC, with: cardDisplayingCartesBancaires, latestPaymentMethods: [cardDisplayingCartesBancaires], didTapToDismiss: false, defaultPaymentMethod: nil)

        // ...then changes the selection and cancels
        try tapRow(.new(paymentMethodType: .stripe(.cashApp)), in: vc)
        vc.didTapOrSwipeToDismiss()
        wait(for: [closed], timeout: 2)

        // Then the saved card is restored using its up-to-date object — not dropped to nil
        XCTAssertEqual(flowController.paymentOption?.label, "•••• 4242")
        guard case .saved(let restored) = vc.paymentMethodListViewController?.currentSelection else {
            return XCTFail("Expected the edited saved card to be selected after cancel, got \(String(describing: vc.paymentMethodListViewController?.currentSelection))")
        }
        XCTAssertEqual(restored.stripeId, cardDisplayingVisa.stripeId)
        XCTAssertEqual(restored.calculateCardBrandToDisplay(), .cartesBancaires)
    }

    @MainActor
    func testDeleteSelectedPM_thenCancel_keepsFallbackSelection() throws {
        // Given the selected/persisted saved card is deleted while the sheet is presented
        let customerID = "cus_fcv_delete_selected"
        defer { CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID) }
        let cardA = STPPaymentMethod._testCard()
        let bank = STPPaymentMethod._testUSBankAccount()
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(cardA.stripeId), forCustomer: customerID)
        let config = makeConfiguration(customerID: customerID)
        let loadResult = makeLoadResult(savedPaymentMethods: [cardA, bank])
        let (flowController, vc) = makeFlowController(configuration: config, loadResult: loadResult)
        XCTAssertEqual(flowController.paymentOption?.label, "•••• 4242")

        let closed = present(flowController)
        let manageVC = VerticalSavedPaymentMethodsViewController(
            configuration: config,
            intent: ._testValue(),
            selectedPaymentMethod: cardA,
            paymentMethods: [cardA, bank],
            elementsSession: ._testCardValue(),
            analyticsHelper: ._testValue(),
            defaultPaymentMethod: nil
        )
        vc.didComplete(viewController: manageVC, with: bank, latestPaymentMethods: [bank], didTapToDismiss: false, defaultPaymentMethod: nil)

        // When the user cancels
        vc.didTapOrSwipeToDismiss()
        wait(for: [closed], timeout: 2)

        // Then the deleted card is not resurrected — the sheet's fallback selection is kept
        XCTAssertNotEqual(flowController.paymentOption?.label, "•••• 4242")
        XCTAssertNotEqual(CustomerPaymentOption.localDefaultPaymentMethod(for: customerID), .stripeId(cardA.stripeId))
    }

}
