//
//  PaymentMethodFormViewControllerTest.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 5/24/24.
//

@_spi(InternalOnlyAPI) @testable import StripeCore
import StripeCoreTestUtils
@_spi(InternalOnlyAPI) @testable import StripePaymentSheet
@_spi(InternalOnlyAPI) @testable import StripeUICore
import XCTest

@MainActor
final class PaymentMethodFormViewControllerTest: XCTestCase {
    var didUpdateDelegateMethodCalled: Bool = false
    override func setUp() {
        let expectation = expectation(description: "Load address specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testUpdatesFormWithLatestShippingDetails() {
        // Given a Configuration w/ shipping details...
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive()
        var shippingDetails: AddressViewController.AddressDetails?
        configuration.shippingDetails = {
            return shippingDetails
        }
        // ...and collects billing address...
        configuration.billingDetailsCollectionConfiguration = .init(address: .full)
        // ...and no default billing address...
        XCTAssertEqual(configuration.defaultBillingDetails, PaymentSheet.Configuration().defaultBillingDetails)
        // ...PaymentMethodFormVC...
        let sut = PaymentMethodFormViewController(type: .stripe(.card), intent: ._testPaymentIntent(paymentMethodTypes: [.card]), elementsSession: ._testCardValue(), previousCustomerInput: nil, formCache: .init(), configuration: configuration, paymentMethodOrientation: .vertical, headerView: nil, analyticsHelper: ._testValue(), delegate: self)

        // ...should fill its address fields with the shipping address
        sut.beginAppearanceTransition(true, animated: false)
        sut.endAppearanceTransition()
        // ...should show the "autocomplete" line until we have pre-filled address from the shippingDetails
        XCTAssertNil(sut.form.getTextFieldElement("Address line 1"))

        // ...and updating the shipping address...
        shippingDetails = AddressViewController.AddressDetails(address: .init(country: "US", line1: "Updated line1"))

        // ...and simulating a re-display of the form...
        sut.beginAppearanceTransition(true, animated: false)
        sut.endAppearanceTransition()

        // ...should update its address fields with the shipping address
        XCTAssertEqual(sut.form.getTextFieldElement("Address line 1").text, "Updated line1")
    }

    func testHandlesViewDidAppear() {
        // Given a PaymentMethodFormViewController...
        let sut = PaymentMethodFormViewController(
            // ..using cash app as an example b/c it contains a SimpleMandateTextView that we can inspect to test behavior below...
            type: .stripe(.cashApp),
            intent: ._testPaymentIntent(paymentMethodTypes: [.cashApp], setupFutureUsage: .offSession),
            elementsSession: ._testValue(paymentMethodTypes: ["cashapp"]),
            previousCustomerInput: nil,
            formCache: .init(),
            configuration: PaymentSheet.Configuration._testValue_MostPermissive(),
            paymentMethodOrientation: .vertical,
            headerView: nil,
            analyticsHelper: ._testValue(),
            delegate: self
        )
        // ...when viewDidAppear is called...
        let mandate = sut.form.getMandateElement()!
        XCTAssertFalse(mandate.mandateTextView.viewDidAppear)
        XCTAssertFalse(didUpdateDelegateMethodCalled)
        sut.viewDidAppear(true)
        // ...sut should notify the form...
        XCTAssertTrue(mandate.mandateTextView.viewDidAppear)
        // ...and notify the delegate
        XCTAssertTrue(didUpdateDelegateMethodCalled)
    }

    func testFormCache() {
        let formCache = PaymentMethodFormCache()
        let firstSUT = PaymentMethodFormViewController(
            type: .stripe(.card),
            intent: ._testPaymentIntent(paymentMethodTypes: [.card], setupFutureUsage: .offSession),
            elementsSession: ._testValue(paymentMethodTypes: ["cashapp"]),
            previousCustomerInput: nil,
            formCache: formCache,
            configuration: PaymentSheet.Configuration._testValue_MostPermissive(),
            paymentMethodOrientation: .vertical,
            headerView: nil,
            analyticsHelper: ._testValue(),
            delegate: self
        )
        firstSUT.form.getTextFieldElement("ZIP").setText("12345")

        let secondSUT = PaymentMethodFormViewController(
            type: .stripe(.card),
            intent: ._testPaymentIntent(paymentMethodTypes: [.card], setupFutureUsage: .offSession),
            elementsSession: ._testValue(paymentMethodTypes: ["cashapp"]),
            previousCustomerInput: nil,
            formCache: formCache,
            configuration: PaymentSheet.Configuration._testValue_MostPermissive(),
            paymentMethodOrientation: .vertical,
            headerView: nil,
            analyticsHelper: ._testValue(),
            delegate: self
        )
        XCTAssertEqual(secondSUT.form.getTextFieldElement("ZIP").text, "12345")
    }

    func testCheckoutBankCollectionIncludesClientAttributionMetadata() throws {
        // Given a bank-account form in Checkout's Payment Element
        let session = CheckoutTestHelpers.makeSession([
            "checkout_session_config_id": "config_checkout",
        ]).makePublicSession()
        let configuration = PaymentSheet.Configuration()
        let sut = PaymentMethodFormViewController(
            type: .stripe(.USBankAccount),
            intent: .checkout(session),
            elementsSession: session.elementsSession,
            previousCustomerInput: nil,
            formCache: .init(),
            configuration: configuration,
            paymentMethodOrientation: .vertical,
            headerView: nil,
            analyticsHelper: PaymentSheetAnalyticsHelper(
                integrationShape: .embedded,
                configuration: configuration,
                checkoutAttribution: .init(confirmingElement: .paymentElement, configuredElements: [.paymentElement, .shippingAddressElement])
            ),
            delegate: self
        )

        // When building the context passed to bank collection
        let metadata = try XCTUnwrap(sut.elementsSessionContext.clientAttributionMetadata)

        // Then collection receives Checkout attribution before confirmation
        XCTAssertEqual(metadata.merchantIntegrationSource, "mobile-checkout")
        XCTAssertEqual(metadata.merchantIntegrationSubtype, "mobile-payment-element")
        XCTAssertEqual(metadata.checkoutSessionId, session.id)
        XCTAssertEqual(metadata.checkoutConfigId, "config_checkout")
        XCTAssertEqual(metadata.merchantIntegrationAdditionalElements, ["mobile-payment-element", "mobile-shipping-address-element"])
    }

    func testRebuiltCardFormKeepsDeclinedLinkInlineSignup() throws {
        // Given a US card form that offers Link inline signup with the box pre-checked (default opt-in)
        let elementsSession = makeLinkElementsSession()
        // ...for a customer without a Link account, in test mode so inline signup shows even if Link was used before
        let originalLinkAccount = LinkAccountContext.shared.account
        LinkAccountContext.shared.account = nil
        defer { LinkAccountContext.shared.account = originalLinkAccount }
        let firstForm = makeCardForm(elementsSession: elementsSession, previousCustomerInput: nil)
        let firstSignup = try XCTUnwrap(linkSignup(in: firstForm))
        XCTAssertEqual(firstSignup.viewModel.mode, .checkboxWithDefaultOptIn)
        XCTAssertTrue(firstSignup.isChecked)

        // When the customer enters a card and unchecks the box
        enterCard(in: firstForm)
        firstSignup.viewModel.saveCheckboxChecked = false
        guard case .new(let confirmParams) = firstForm.paymentOption else {
            return XCTFail("Expected a new card, got \(String(describing: firstForm.paymentOption))")
        }
        XCTAssertTrue(confirmParams.didDeclineLinkInlineSignup)

        // ...and the form is rebuilt from that input, as it is after a session update
        let rebuiltForm = makeCardForm(elementsSession: elementsSession, previousCustomerInput: confirmParams)

        // Then the box stays unchecked, so the card alone still completes the form
        XCTAssertFalse(try XCTUnwrap(linkSignup(in: rebuiltForm)).isChecked)
        guard case .new(let rebuiltConfirmParams) = rebuiltForm.paymentOption else {
            return XCTFail("Expected the card to still be selected, got \(String(describing: rebuiltForm.paymentOption))")
        }
        // ...and the decline carries over to the next rebuild
        XCTAssertTrue(rebuiltConfirmParams.didDeclineLinkInlineSignup)
    }

    func testRebuiltCardFormKeepsDeclinedLinkSignupOptInAndMandate() throws {
        // Given a card form in the signup opt-in mode, pre-checked, with the mandate that says the customer will be signed up for Link
        let elementsSession = makeLinkElementsSession(
            flags: ["elements_mobile_force_setup_future_use_behavior_and_new_mandate_text": true],
            linkSettings: [
                "link_sign_up_opt_in_feature_enabled": true,
                "link_sign_up_opt_in_initial_value": true,
            ]
        )
        // ...for a customer whose email is known but who doesn't have a Link account
        let originalLinkAccount = LinkAccountContext.shared.account
        LinkAccountContext.shared.account = ._testValue(email: "user@example.com", isRegistered: false)
        defer { LinkAccountContext.shared.account = originalLinkAccount }
        func mandateText(_ shouldSignUpToLink: Bool) -> String {
            PaymentSheetFormFactory.makeMandateText(variant: .updated(shouldSignUpToLink: shouldSignUpToLink), merchantName: PaymentSheet.Configuration().merchantDisplayName).string
        }
        let firstForm = makeCardForm(elementsSession: elementsSession, previousCustomerInput: nil)
        let firstSignup = try XCTUnwrap(linkSignup(in: firstForm))
        XCTAssertEqual(firstSignup.viewModel.mode, .signupOptIn)
        XCTAssertTrue(firstSignup.isChecked)
        XCTAssertEqual(firstForm.form.getMandateElement()?.mandateTextView.attributedText?.string, mandateText(true))

        // When the customer enters a card, unchecks the box, and the form is rebuilt from that input
        enterCard(in: firstForm)
        firstSignup.viewModel.saveCheckboxChecked = false
        firstForm.viewDidAppear(false) // Marks the mandate as displayed, which the form requires
        let confirmParams = try XCTUnwrap(firstForm.paymentOption?.newConfirmParams)
        let rebuiltForm = makeCardForm(elementsSession: elementsSession, previousCustomerInput: confirmParams)

        // Then the box stays unchecked, and the mandate no longer says they'll be signed up for Link
        XCTAssertFalse(try XCTUnwrap(linkSignup(in: rebuiltForm)).isChecked)
        XCTAssertEqual(rebuiltForm.form.getMandateElement()?.mandateTextView.attributedText?.string, mandateText(false))
    }

    // MARK: - Link inline signup helpers

    private func makeLinkElementsSession(flags: [String: Bool] = [:], linkSettings: [String: Any] = [:]) -> STPElementsSession {
        STPElementsSession.decodedObject(fromAPIResponse: [
            "payment_method_preference": ["ordered_payment_method_types": ["card", "link"], "country_code": "US"],
            "session_id": "123",
            "config_id": "123",
            "flags": flags,
            "link_settings": linkSettings.merging(["link_funding_sources": ["CARD"]]) { current, _ in current },
        ])!
    }

    private func makeCardForm(elementsSession: STPElementsSession, previousCustomerInput: IntentConfirmParams?) -> PaymentMethodFormViewController {
        var configuration = PaymentSheet.Configuration()
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        let intent: Intent = ._testPaymentIntent(paymentMethodTypes: [.card, .link])
        return PaymentMethodFormViewController(type: .stripe(.card), intent: intent, elementsSession: elementsSession, previousCustomerInput: previousCustomerInput, formCache: .init(), configuration: configuration, paymentMethodOrientation: .vertical, headerView: nil, analyticsHelper: ._testValue(), delegate: self)
    }

    private func linkSignup(in formViewController: PaymentMethodFormViewController) -> LinkInlineSignupElement? {
        formViewController.form.getAllUnwrappedSubElements().compactMap { $0 as? LinkInlineSignupElement }.first
    }

    private func enterCard(in formViewController: PaymentMethodFormViewController) {
        formViewController.form.getTextFieldElement("Card number").setText("4242424242424242")
        formViewController.form.getTextFieldElement("MM / YY").setText("1240")
        formViewController.form.getTextFieldElement("CVC").setText("123")
        formViewController.form.getTextFieldElement("ZIP").setText("65432")
    }

    // MARK: - logBillingAddressCompletionIfNeeded

    func testLogBillingAddressCompletionIfNeeded_withoutAutocomplete() {
        STPAnalyticsClient.sharedClient._testLogHistory = []
        defer { STPAnalyticsClient.sharedClient._testLogHistory = [] }

        var configuration = PaymentSheet.Configuration._testValue_MostPermissive()
        configuration.billingDetailsCollectionConfiguration = .init(address: .full)
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_123")

        let sut = PaymentMethodFormViewController(
            type: .stripe(.card),
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testCardValue(),
            previousCustomerInput: nil,
            formCache: .init(),
            configuration: configuration,
            paymentMethodOrientation: .vertical,
            headerView: nil,
            analyticsHelper: PaymentSheetAnalyticsHelper(
                integrationShape: .flowController,
                configuration: configuration,
                checkoutSessionID: "cs_test_123"
            ),
            delegate: self
        )

        sut.logBillingAddressCompletionIfNeeded()

        let event = STPAnalyticsClient.sharedClient._testLogHistory.first(where: {
            $0["event"] as? String == "mc_billing_address_completed"
        })
        XCTAssertNotNil(event)
        XCTAssertEqual(event?["checkout_session_id"] as? String, "cs_test_123")
        let blob = event?["address_data_blob"] as? [String: Any?]
        XCTAssertEqual(blob?["auto_complete_result_selected"] as? Bool, false)
        XCTAssertNil(blob?["edit_distance"] as? Int)
    }

}

extension PaymentMethodFormViewControllerTest: PaymentMethodFormViewControllerDelegate {
    func didUpdate(_ viewController: StripePaymentSheet.PaymentMethodFormViewController) {
        didUpdateDelegateMethodCalled = true
    }

    func updateErrorLabel(for error: (any Error)?) {

    }
}
