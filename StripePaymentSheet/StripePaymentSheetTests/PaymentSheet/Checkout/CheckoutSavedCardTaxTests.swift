//
//  CheckoutSavedCardTaxTests.swift
//  StripePaymentSheetTests
//
//  Created by George Birch on 11/13/26.
//

import OHHTTPStubs
@testable @_spi(InternalOnlyAPI) import StripeCore
@testable @_spi(InternalOnlyAPI) import StripeCoreTestUtils
@testable @_spi(InternalOnlyAPI) import StripePayments
@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
@testable @_spi(InternalOnlyAPI) import StripePaymentsTestUtils
@testable @_spi(InternalOnlyAPI) import StripeUICore
import UIKit
import XCTest

extension CheckoutTests {

    func testLiveEditingSelectedSavedCardBillingAddressUpdatesCheckoutTax() async throws {
        // Given a live session that calculates tax from the billing address, with a saved South San Francisco card
        HTTPStubs.removeAllStubs()
        let checkout = try await makeSavedCardTaxCheckout(savedCards: [
            (cardNumber: "4242424242424242", billingAddress: savedCardTaxSouthSanFranciscoAddress),
        ])
        let embedded = checkout.getPaymentElement().embeddedPaymentElement
        XCTAssertTrue(checkout.session.collectsTaxFromBillingAddress, "The session must calculate tax from the billing address")
        let card = try XCTUnwrap(embedded.savedPaymentMethods.first, "The Customer's saved card must load")
        guard case .saved(let selectedCard, _) = embedded._paymentOption, selectedCard.stripeId == card.stripeId else {
            return XCTFail("The saved card must be selected after load")
        }
        // ...and the initial load already synced that card's address, so tax was calculated for South San Francisco
        XCTAssertEqual(checkout.session.paymentOption?.billingDetails?.address?.postalCode, "94080")
        XCTAssertEqual(checkout.session.tax?.status, .ready, "Tax must be calculated before the edit")
        let totalBeforeEdit = checkout.session.totals.total.minorUnitsAmount
        XCTAssertGreaterThan(
            totalBeforeEdit,
            checkout.session.totals.subtotal.minorUnitsAmount,
            "The initial total must include tax for the saved card's address"
        )
        // ...and the backend calculates a different total for the address the customer is about to enter
        let expectedTotal = try await savedCardTaxReferenceTotal(for: .init(
            country: "US",
            line1: "510 Townsend St",
            city: "San Francisco",
            state: "CA",
            postalCode: "94103"
        ))
        XCTAssertNotEqual(expectedTotal, totalBeforeEdit, "The repro needs two addresses with different tax")

        // When the customer taps Edit on the selected saved card row
        let (presenter, window) = try makeSavedCardTaxPresenter()
        defer {
            presenter.dismiss(animated: false)
            window.isHidden = true
        }
        embedded.presentingViewController = presenter
        embedded.embeddedPaymentMethodsView.didTapViewMoreSavedPaymentMethods()
        let editor = try XCTUnwrap(
            presenter.presentedViewController?.bottomSheetController?.contentStack
                .compactMap { $0 as? UpdatePaymentMethodViewController }.first,
            "Tapping Edit on the only saved card must open the card editor"
        )
        // ...enters a new street, city, and ZIP
        XCTAssertTrue(enterSavedCardEditorText("510 Townsend St", intoFieldWithIdentifier: "Address line 1", in: editor.view))
        XCTAssertTrue(enterSavedCardEditorText("San Francisco", intoFieldWithIdentifier: "City", in: editor.view))
        XCTAssertTrue(enterSavedCardEditorText("94103", intoFieldWithIdentifier: "ZIP", in: editor.view))
        // ...and taps Save
        let saveButton = try XCTUnwrap(savedCardTaxSubviews(of: ConfirmButton.self, in: editor.view).first)
        XCTAssertEqual(saveButton.status, .enabled, "Save must be enabled after editing the billing address")
        saveButton.sendActions(for: .touchUpInside)
        // ...and the live backend saves the new billing address on the card
        let didSaveAddress = try await waitForSavedCardTaxCondition {
            embedded.savedPaymentMethods.first?.billingDetails?.address?.postalCode == "94103"
        }
        XCTAssertTrue(didSaveAddress, "The live backend must save the edited billing address")
        guard didSaveAddress else { return }
        // ...and Checkout has time to finish any update the edit starts
        _ = try await waitForSavedCardTaxCondition(timeout: 10) {
            checkout.session.paymentOption?.billingDetails?.address?.postalCode == "94103"
                && checkout.session.totals.total.minorUnitsAmount == expectedTotal
                && !checkout.isUpdating
        }
        try await checkout.awaitPendingOperations()

        // Then Checkout reports the edited billing address and the tax for that address
        XCTAssertEqual(checkout.session.paymentOption?.billingDetails?.address?.postalCode, "94103")
        XCTAssertEqual(checkout.session.totals.total.minorUnitsAmount, expectedTotal)
        // ...and confirming at the displayed total succeeds
        await assertSavedCardTaxConfirmCompletes(checkout, from: presenter)
    }

    func testLiveRemovingSelectedSavedCardUpdatesTaxForAutomaticallySelectedCard() async throws {
        // Given a live session that calculates tax from the billing address, with saved cards in California and Oregon
        HTTPStubs.removeAllStubs()
        // Checkout lists only one saved card per card number, so the second card uses a different test number
        let checkout = try await makeSavedCardTaxCheckout(savedCards: [
            (cardNumber: "4242424242424242", billingAddress: savedCardTaxSouthSanFranciscoAddress),
            (
                cardNumber: "5555555555554444",
                billingAddress: .init(country: "US", line1: "1221 SW 4th Ave", city: "Portland", state: "OR", postalCode: "97204")
            ),
        ])
        let embedded = checkout.getPaymentElement().embeddedPaymentElement
        XCTAssertTrue(checkout.session.collectsTaxFromBillingAddress, "The session must calculate tax from the billing address")
        XCTAssertEqual(embedded.savedPaymentMethods.count, 2, "Both saved cards must load")
        guard case .saved(let selectedCard, _) = embedded._paymentOption else {
            return XCTFail("A saved card must be selected after load")
        }
        // ...and the initial load already synced the selected card's address
        XCTAssertEqual(
            checkout.session.paymentOption?.billingDetails?.address?.postalCode,
            selectedCard.billingDetails?.address?.postalCode
        )
        XCTAssertEqual(checkout.session.tax?.status, .ready, "Tax must be calculated before the removal")
        let replacementCard = try XCTUnwrap(embedded.savedPaymentMethods.first { $0.stripeId != selectedCard.stripeId })
        let replacementAddress = try XCTUnwrap(replacementCard.billingDetails?.address?.checkoutAddress)
        // ...and the backend calculates a different total for the card that will be selected automatically
        let expectedTotal = try await savedCardTaxReferenceTotal(for: replacementAddress)
        XCTAssertNotEqual(
            expectedTotal,
            checkout.session.totals.total.minorUnitsAmount,
            "The repro needs two cards with different tax"
        )

        // When the customer opens the saved card list and taps Edit
        let (presenter, window) = try makeSavedCardTaxPresenter()
        defer {
            presenter.dismiss(animated: false)
            window.isHidden = true
        }
        embedded.presentingViewController = presenter
        embedded.embeddedPaymentMethodsView.didTapViewMoreSavedPaymentMethods()
        let manageScreen = try XCTUnwrap(
            presenter.presentedViewController?.bottomSheetController?.contentStack
                .compactMap { $0 as? VerticalSavedPaymentMethodsViewController }.first,
            "Tapping View more must open the saved card list"
        )
        manageScreen.didSelectEditSavedPaymentMethodsButton()
        // ...opens the selected card's editor
        let selectedRow = try XCTUnwrap(
            savedCardTaxSubviews(of: SavedPaymentMethodRowButton.self, in: manageScreen.view)
                .first { $0.paymentMethod.stripeId == selectedCard.stripeId }
        )
        selectedRow.delegate?.didSelectUpdateButton(selectedRow, with: selectedRow.paymentMethod)
        let editor = try XCTUnwrap(
            manageScreen.bottomSheetController?.contentStack
                .compactMap { $0 as? UpdatePaymentMethodViewController }.first,
            "Tapping the selected card's edit button must open its editor"
        )
        // ...and confirms removal, which is the delegate call the Remove alert makes
        editor.delegate?.didRemove(viewController: editor, paymentMethod: selectedCard)
        XCTAssertTrue(manageScreen.canRemoveOrEdit, "The list must stay in edit mode so the customer can tap Done")
        // ...and taps Done, which selects the remaining card and closes the list
        manageScreen.didSelectEditSavedPaymentMethodsButton()
        let didSelectReplacement = try await waitForSavedCardTaxCondition {
            checkout.session.paymentOption?.billingDetails?.address?.postalCode == replacementAddress.postalCode
        }
        XCTAssertTrue(didSelectReplacement, "Checkout must report the automatically selected card")
        guard didSelectReplacement else { return }
        // ...and Checkout has time to finish any update the new selection starts
        _ = try await waitForSavedCardTaxCondition(timeout: 10) {
            checkout.session.totals.total.minorUnitsAmount == expectedTotal && !checkout.isUpdating
        }
        try await checkout.awaitPendingOperations()

        // Then Checkout's tax reflects the automatically selected card's billing address
        XCTAssertEqual(checkout.session.totals.total.minorUnitsAmount, expectedTotal)
        // ...and confirming at the displayed total succeeds
        await assertSavedCardTaxConfirmCompletes(checkout, from: presenter)
    }

    func testLiveSavedCardCountryChangeToUSKeepsCardAvailableForBillingTax() async throws {
        // Given a live session that calculates tax from an automatically collected billing address,
        // for a Customer whose saved card has only a UK country and postal code
        HTTPStubs.removeAllStubs()
        let checkout = try await makeSavedCardTaxCheckout(
            savedCards: [(cardNumber: "4242424242424242", billingAddress: .init(country: "GB", postalCode: "SW1A 1AA"))],
            billingAddressCollection: nil
        )
        let embedded = checkout.getPaymentElement().embeddedPaymentElement
        XCTAssertTrue(checkout.session.collectsTaxFromBillingAddress, "The session must calculate tax from the billing address")
        XCTAssertEqual(
            checkout.session.billingAddressCollection,
            .automatic,
            "The session must collect the billing address automatically, so the editor starts from the country alone"
        )
        let customerID = try XCTUnwrap(checkout.session.customerId, "The session must belong to the Customer")
        // ...and Payment Element lists the card, because a UK postal code is enough to calculate tax
        let card = try XCTUnwrap(embedded.savedPaymentMethods.first, "The Customer's UK saved card must load")
        XCTAssertEqual(card.billingDetails?.address?.country, "GB")
        XCTAssertNil(card.billingDetails?.address?.line1, "The repro needs a saved address without a street")

        // When the customer taps Edit on the saved card row
        let (presenter, window) = try makeSavedCardTaxPresenter()
        defer {
            presenter.dismiss(animated: false)
            window.isHidden = true
        }
        embedded.presentingViewController = presenter
        embedded.embeddedPaymentMethodsView.didTapViewMoreSavedPaymentMethods()
        let editor = try XCTUnwrap(
            presenter.presentedViewController?.bottomSheetController?.contentStack
                .compactMap { $0 as? UpdatePaymentMethodViewController }.first,
            "Tapping Edit on the only saved card must open the card editor"
        )
        // ...picks the US in the billing country dropdown, as the picker's Done button does
        let countryDropdown = try XCTUnwrap(
            savedCardTaxDropdown(containingAll: ["US", "GB"], in: editor.view),
            "The card editor must show a billing country dropdown"
        )
        XCTAssertEqual(countryDropdown.selectedItem.rawData, "GB", "The editor must start from the card's saved country")
        let unitedStatesIndex = try XCTUnwrap(countryDropdown.items.firstIndex { $0.rawData == "US" })
        countryDropdown.select(index: unitedStatesIndex)
        // ...fills in every address field the editor now shows
        let editorAskedForStreetAddress = enterSavedCardEditorText(
            "510 Townsend St",
            intoFieldWithIdentifier: "Address line 1",
            in: editor.view
        )
        _ = enterSavedCardEditorText("San Francisco", intoFieldWithIdentifier: "City", in: editor.view)
        // US states use a dropdown; the country dropdown has no "NY" item, so this only matches the state field
        if let stateDropdown = savedCardTaxDropdown(containingAll: ["CA", "NY"], in: editor.view),
           let californiaIndex = stateDropdown.items.firstIndex(where: { $0.rawData == "CA" }) {
            stateDropdown.select(index: californiaIndex)
        }
        XCTAssertTrue(
            enterSavedCardEditorText("94103", intoFieldWithIdentifier: "ZIP", in: editor.view),
            "The editor must ask for a ZIP code for a US billing address"
        )
        // ...and taps Save
        let saveButton = try XCTUnwrap(savedCardTaxSubviews(of: ConfirmButton.self, in: editor.view).first)
        XCTAssertEqual(saveButton.status, .enabled, "Save must be enabled once every field the editor shows is filled in")
        saveButton.sendActions(for: .touchUpInside)
        // ...and the live backend saves the US billing address on the card
        let didSaveAddress = try await waitForSavedCardTaxCondition {
            embedded.savedPaymentMethods.first?.billingDetails?.address?.country == "US"
        }
        XCTAssertTrue(didSaveAddress, "The live backend must save the edited billing address")
        guard didSaveAddress else { return }
        let savedAddress = embedded.savedPaymentMethods.first?.billingDetails?.address
        // ...and the customer later starts another Checkout with the same billing tax setup
        let nextCheckout = try await loadSavedCardTaxCheckout(
            customerID: customerID,
            apiClient: checkout.apiClient,
            billingAddressCollection: nil
        )
        XCTAssertTrue(nextCheckout.session.collectsTaxFromBillingAddress, "The next session must also calculate tax from the billing address")
        let backendCard = nextCheckout.session.customer?.paymentMethods.first { $0.stripeId == card.stripeId }
        XCTAssertEqual(
            backendCard?.billingDetails?.address?.country,
            "US",
            "The backend must still return the edited card for the Customer"
        )

        // Then the editor asked for the street address that automatic tax needs for a US card
        XCTAssertTrue(
            editorAskedForStreetAddress,
            "After switching to the US, the editor must ask for the street, city, and state that automatic tax requires"
        )
        // ...and the card the customer just saved is still available to pay with
        let nextEmbedded = nextCheckout.getPaymentElement().embeddedPaymentElement
        XCTAssertTrue(
            nextEmbedded.savedPaymentMethods.contains { $0.stripeId == card.stripeId },
            "The edited card must still be listed, but Payment Element filtered it out with the saved address "
                + "line1=\(savedAddress?.line1 ?? "nil"), city=\(savedAddress?.city ?? "nil"), "
                + "state=\(savedAddress?.state ?? "nil"), postal=\(savedAddress?.postalCode ?? "nil")"
        )
    }

    /// The billing address the Checkout Playground uses for its returning Customer's saved card.
    private var savedCardTaxSouthSanFranciscoAddress: CheckoutElementsController.Address {
        .init(country: "US", line1: "354 Oyster Point Blvd", city: "South San Francisco", state: "CA", postalCode: "94080")
    }

    /// Creates a live Checkout whose automatic tax uses the billing address, for a Customer with the given saved cards.
    /// Pass `nil` for `billingAddressCollection` to leave it unset, which the backend treats as `auto`.
    private func makeSavedCardTaxCheckout(
        savedCards: [(cardNumber: String, billingAddress: CheckoutElementsController.Address)],
        billingAddressCollection: String? = "required"
    ) async throws -> CheckoutElementsController {
        let keyResponse = try await customerLogicBackendRequest(endpoint: "publishable_key?merchant=us_tax")
        let apiClient = STPAPIClient(publishableKey: try XCTUnwrap(keyResponse["publishable_key"] as? String))
        let customerID = try await STPTestingAPIClient.shared.createCheckoutCustomer(
            email: "customer@example.com",
            merchantCountry: "us_tax"
        )
        for (cardNumber, address) in savedCards {
            let card = STPPaymentMethodCardParams()
            card.number = cardNumber
            card.expMonth = 12
            card.expYear = 2040
            card.cvc = "123"
            let billingAddress = STPPaymentMethodAddress()
            billingAddress.line1 = address.line1
            billingAddress.city = address.city
            billingAddress.state = address.state
            billingAddress.postalCode = address.postalCode
            billingAddress.country = address.country
            let billingDetails = STPPaymentMethodBillingDetails()
            billingDetails.name = "Jenny Rosen"
            billingDetails.address = billingAddress
            let paymentMethod = try await apiClient.createPaymentMethod(with: .init(
                card: card,
                billingDetails: billingDetails,
                allowRedisplay: .always,
                metadata: nil
            ))
            _ = try await customerLogicBackendRequest(endpoint: "attach_payment_method", parameters: [
                "merchant": "us_tax",
                "payment_method_id": paymentMethod.stripeId,
                "request_params": ["customer": customerID],
            ])
        }
        return try await loadSavedCardTaxCheckout(
            customerID: customerID,
            apiClient: apiClient,
            billingAddressCollection: billingAddressCollection
        )
    }

    /// Creates and loads a live Checkout Session for an existing Customer whose automatic tax uses the billing address.
    private func loadSavedCardTaxCheckout(
        customerID: String,
        apiClient: STPAPIClient,
        billingAddressCollection: String?
    ) async throws -> CheckoutElementsController {
        var sessionParameters: [String: Any] = [
            "ui_mode": "mobile_elements",
            "currency": "usd",
            "allowed_payment_method_types": ["card"],
            "items": [
                [
                    "type": "one_time_price",
                    "one_time_price": [
                        "items": [
                            [
                                // Matches STPTestingAPIClient.createCheckoutSession so reference totals are comparable
                                "price_data": [
                                    "currency": "usd",
                                    "unit_amount": 5050,
                                    "product_data": ["name": "Test", "tax_code": "txcd_99999999"],
                                    "tax_behavior": "exclusive",
                                ],
                                "quantity": 1,
                            ],
                        ],
                    ],
                ],
            ],
            "customer": customerID,
            // With an existing Customer, this makes the session's billing address the automatic tax source
            "customer_update": ["address": "auto"],
            "automatic_tax": ["enabled": true],
            "saved_payment_method_options": [
                "payment_method_save": "enabled",
                "payment_method_remove": "enabled",
                "allow_redisplay_filters": ["always", "limited", "unspecified"],
            ],
        ]
        if let billingAddressCollection {
            sessionParameters["billing_address_collection"] = billingAddressCollection
        }
        let response = try await customerLogicBackendRequest(endpoint: "create_checkout_session", parameters: [
            "merchant": "us_tax",
            "stripe_version": STPTestingAPIClient.checkoutMobileElementsAPISettings,
            "request_params": sessionParameters,
        ])
        var configuration = CheckoutElementsController.Configuration(
            clientSecret: try XCTUnwrap(response["client_secret"] as? String),
            returnURL: "stripe-ios-test://checkout-return"
        )
        configuration.apiClient = apiClient
        configuration.paymentElement = .init()
        return try await CheckoutElementsController(configuration: configuration)
    }

    /// Returns the total the backend calculates for `address` on an otherwise identical guest session.
    private func savedCardTaxReferenceTotal(for address: CheckoutElementsController.Address) async throws -> Int {
        let response = try await STPTestingAPIClient.shared.createCheckoutSession(
            amount: 5050,
            merchantCountry: "us_tax",
            collectBillingAddress: true,
            automaticTax: true
        )
        var configuration = CheckoutElementsController.Configuration(
            clientSecret: response.clientSecret,
            returnURL: "stripe-ios-test://checkout-return"
        )
        configuration.apiClient = STPAPIClient(publishableKey: response.publishableKey)
        let referenceCheckout = try await CheckoutElementsController(configuration: configuration)
        try await referenceCheckout.updateBillingTaxRegionIfNecessary(address: address)
        XCTAssertEqual(referenceCheckout.session.tax?.status, .ready, "The reference session must calculate tax")
        return referenceCheckout.session.totals.total.minorUnitsAmount
    }

    /// Shows a presenter in a key window so Payment Element can present its saved card sheets as it does in an app.
    private func makeSavedCardTaxPresenter() throws -> (UIViewController, UIWindow) {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first,
            "The test host must have a window scene"
        )
        let window = UIWindow(windowScene: scene)
        window.frame = scene.coordinateSpace.bounds
        let presenter = UIViewController()
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        return (presenter, window)
    }

    /// Confirms through the public API and fails with the backend's error code if the payment does not complete.
    private func assertSavedCardTaxConfirmCompletes(
        _ checkout: CheckoutElementsController,
        from presenter: UIViewController
    ) async {
        let displayedTotal = checkout.session.totals.total.minorUnitsAmount
        let result = await checkout.confirm(from: presenter)
        switch result {
        case .completed:
            break
        case .canceled:
            XCTFail("Expected confirmation at the displayed total of \(displayedTotal) to complete, but it was canceled")
        case .failed(let error):
            XCTFail(
                "Expected confirmation at the displayed total of \(displayedTotal) to complete, but it failed with "
                    + "\(error._stp_error_code ?? "no error code"): \(error.localizedDescription)"
            )
        }
    }

    /// Polls `condition` until it holds or `timeout` elapses, and returns whether it held.
    private func waitForSavedCardTaxCondition(
        timeout: TimeInterval = 15,
        _ condition: () -> Bool
    ) async throws -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            guard Date() < deadline else { return false }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        return true
    }

    /// Types into the saved card editor field whose placeholder-based accessibility identifier matches, and returns whether it exists.
    private func enterSavedCardEditorText(
        _ text: String,
        intoFieldWithIdentifier identifier: String,
        in rootView: UIView
    ) -> Bool {
        guard let textField = savedCardTaxSubviews(of: UITextField.self, in: rootView)
            .first(where: { $0.accessibilityIdentifier == identifier }) else {
            return false
        }
        textField.text = text
        // This is the control event TextFieldView listens to for typed input
        textField.sendActions(for: .editingChanged)
        return true
    }

    /// Returns the saved card editor dropdown whose items include every raw value in `rawValues`.
    private func savedCardTaxDropdown(containingAll rawValues: [String], in rootView: UIView) -> DropdownFieldElement? {
        // Each dropdown's text field uses its picker as the input view, and the picker's delegate points back to the element
        return savedCardTaxSubviews(of: UITextField.self, in: rootView).lazy
            .compactMap { textField -> DropdownFieldElement? in
                guard let pickerView = textField.inputView as? UIPickerView else { return nil }
                return (pickerView.delegate as? DropdownFieldElement.PickerViewDelegate)?.dropdownFieldElement
            }
            .first { dropdown in
                rawValues.allSatisfy { rawValue in dropdown.items.contains { $0.rawData == rawValue } }
            }
    }

    /// Returns every descendant of `rootView` with the given type, in depth-first order.
    private func savedCardTaxSubviews<T: UIView>(of type: T.Type, in rootView: UIView) -> [T] {
        var matches: [T] = []
        var views = [rootView]
        while let view = views.popLast() {
            if let match = view as? T {
                matches.append(match)
            }
            views.append(contentsOf: view.subviews.reversed())
        }
        return matches
    }
}
