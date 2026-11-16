//
//  CheckoutPaymentPreferenceTests.swift
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

    func testLiveNewlySavedCardIsPreselectedInSameCustomersNextSession() async throws {
        // Given a disposable customer with one saved Visa on the real playground backend
        HTTPStubs.removeAllStubs()
        let firstCheckout = try await makeCustomerLogicCheckout(withSavedCard: true)
        let customerID = try XCTUnwrap(firstCheckout.session.customerId, "The session must be attached to a Customer")
        // Payment preferences live in UserDefaults and outlive this test, so always clear this customer's entry
        defer { CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID) }
        XCTAssertNil(
            CustomerPaymentOption.localDefaultPaymentMethod(for: customerID),
            "A brand new customer must start without a local payment preference"
        )
        XCTAssertEqual(firstCheckout.session.savedPaymentMethodsOfferSave?.enabled, true, "The session must offer saving new cards")
        let firstEmbedded = firstCheckout.getPaymentElement().embeddedPaymentElement
        let presentingViewController = UIViewController()
        firstEmbedded.presentingViewController = presentingViewController
        XCTAssertEqual(firstEmbedded.savedPaymentMethods.count, 1, "The customer must start with exactly one saved card")
        let existingCard = try XCTUnwrap(firstEmbedded.savedPaymentMethods.first)
        XCTAssertEqual(existingCard.card?.last4, "4242")

        // ...who last selected that existing card on this device
        let existingCardRow = try XCTUnwrap(firstEmbedded.embeddedPaymentMethodsView.rowButtons.first {
            $0.type.savedPaymentMethod?.stripeId == existingCard.stripeId
        }, "The existing saved card must have a row")
        firstEmbedded.embeddedPaymentMethodsView.didTap(rowButton: existingCardRow)
        // Checkout finishes saved-row selection after an async billing sync, so wait for the SDK's own write
        let didPersistExistingCard = await waitForPaymentPreferenceCondition {
            CustomerPaymentOption.localDefaultPaymentMethod(for: customerID) == .stripeId(existingCard.stripeId)
        }
        XCTAssertTrue(didPersistExistingCard, "Tapping the saved card row should persist it as the local preference")
        guard didPersistExistingCard else { return }

        // When the customer pays with a new Mastercard and checks the box to save it
        let cardRow = try XCTUnwrap(firstEmbedded.embeddedPaymentMethodsView.rowButtons.first {
            $0.type == .new(paymentMethodType: .stripe(.card))
        }, "The new card row must be shown")
        firstEmbedded.embeddedPaymentMethodsView.didTap(rowButton: cardRow)
        let form = try XCTUnwrap(firstEmbedded.formCache[.stripe(.card)], "Tapping the card row should build the card form")
        let cardDetails = [
            ("Card number", "5555555555554444"),
            ("MM / YY", "1240"),
            ("CVC", "123"),
            ("ZIP", "94107"),
        ]
        for (label, text) in cardDetails {
            let field: TextFieldElement? = form.getTextFieldElement(label)
            try XCTUnwrap(field, "The card form is missing its \(label) field").setText(text)
        }
        let saveCheckbox = try XCTUnwrap(
            form.getCheckboxElement(startingWith: "Save"),
            "The card form must show the save checkbox"
        )
        saveCheckbox.isSelected = true
        XCTAssertTrue(form.validationState.isValid, "The completed card form should be valid")
        guard form.validationState.isValid else { return }
        try XCTUnwrap(firstEmbedded.selectedFormViewController).didTapPrimaryButton()
        // ...and waits for Continue to finish its billing sync and hand the new card to Checkout.
        // The existing card has no billing details, so this postal code can only come from the new card.
        let didSelectNewCard = await waitForPaymentPreferenceCondition {
            firstCheckout.session.paymentOption?.billingDetails?.address?.postalCode == "94107"
        }
        XCTAssertTrue(didSelectNewCard, "Continuing from the card form should make the new card Checkout's payment option")
        guard didSelectNewCard else { return }
        let result = await firstCheckout.confirm(from: presentingViewController)
        guard case .completed = result else {
            return XCTFail("Expected the live confirmation to complete, got \(result)")
        }

        // ...and the same customer later starts another Checkout Session on this device
        let secondSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            customerID: customerID,
            savedPaymentMethodAllowRedisplayFilters: ["always", "limited", "unspecified"]
        )
        var secondConfiguration = CheckoutElementsController.Configuration(
            clientSecret: secondSessionResponse.clientSecret,
            returnURL: "stripe-ios-test://checkout-return"
        )
        secondConfiguration.apiClient = STPAPIClient(publishableKey: secondSessionResponse.publishableKey)
        secondConfiguration.paymentElement = .init()
        let secondCheckout = try await CheckoutElementsController(configuration: secondConfiguration)
        XCTAssertEqual(secondCheckout.session.customerId, customerID, "The second session must belong to the same Customer")
        // Only the local preference can pick the default here; there is no server-side default for Checkout
        XCTAssertFalse(secondCheckout.session.elementsSession.paymentMethodSetAsDefaultForPaymentSheet)
        let secondSessionPaymentMethods = secondCheckout.session.customer?.paymentMethods ?? []
        XCTAssertTrue(
            secondSessionPaymentMethods.contains { $0.stripeId == existingCard.stripeId },
            "The existing card must still be saved to the customer"
        )
        let newlySavedCard = try XCTUnwrap(
            secondSessionPaymentMethods.first { $0.card?.last4 == "4444" },
            "The live backend must have saved the new card to the customer"
        )

        // Then Payment Element preselects the card saved by the last successful payment, as PaymentSheet does
        let secondEmbedded = secondCheckout.getPaymentElement().embeddedPaymentElement
        XCTAssertEqual(
            secondEmbedded.embeddedPaymentMethodsView.selectedRowButton?.type.savedPaymentMethod?.stripeId,
            newlySavedCard.stripeId,
            "Expected the newly saved card to be preselected, but the stored preference is still "
                + String(describing: CustomerPaymentOption.localDefaultPaymentMethod(for: customerID))
                + " (existing card: \(existingCard.stripeId))"
        )
    }

    /// Polls `condition` on the main actor until it passes or `timeout` elapses.
    private func waitForPaymentPreferenceCondition(
        timeout: TimeInterval = 15,
        _ condition: () -> Bool
    ) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            guard Date() < deadline else {
                return false
            }
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        return true
    }
}
