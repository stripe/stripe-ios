//
//  CheckoutTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 2/25/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
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

@MainActor
final class CheckoutTests: STPNetworkStubbingTestCase {

    func testLiveRemovedSavedCardStaysRemovedAfterLocalShippingUpdate() async throws {
        // Given a disposable customer with one saved card on the real playground backend
        HTTPStubs.removeAllStubs()
        let checkout = try await makeCustomerLogicCheckout(withSavedCard: true)
        let embedded = checkout.getPaymentElement().embeddedPaymentElement
        let card = try XCTUnwrap(embedded.savedPaymentMethods.first)
        XCTAssertTrue(checkout.session.canDetachPaymentMethod)
        let updateConfiguration = UpdatePaymentMethodViewController.Configuration(
            paymentMethod: card,
            appearance: embedded.configuration.appearance,
            billingDetailsCollectionConfiguration: embedded.configuration.billingDetailsCollectionConfiguration,
            hostedSurface: .paymentSheet,
            checkoutSessionID: checkout.session.id,
            canRemove: true,
            canUpdate: true,
            isCBCEligible: false
        )
        let updateController = UpdatePaymentMethodViewController(
            removeSavedPaymentMethodMessage: nil,
            configuration: updateConfiguration
        )

        // When the normal removal delegate runs and the backend finishes detaching the card
        embedded.didRemove(viewController: updateController, paymentMethod: card)
        XCTAssertTrue(embedded.savedPaymentMethods.isEmpty)
        let deadline = Date().addingTimeInterval(15)
        var backendRemovedCard = false
        repeat {
            let backendSession = try await checkout.apiClient.initCheckoutSession(
                checkoutSessionId: checkout.session.id,
                clientSecret: checkout.clientSecret,
                adaptivePricingAllowed: false
            )
            backendRemovedCard = backendSession.customer?.paymentMethods.contains {
                $0.stripeId == card.stripeId
            } == false
            if !backendRemovedCard {
                try await Task.sleep(nanoseconds: 100_000_000)
            }
        } while !backendRemovedCard && Date() < deadline
        XCTAssertTrue(backendRemovedCard, "The live backend must confirm removal before the local update")
        guard backendRemovedCard else { return }

        // ...and an unrelated, local-only shipping change rebuilds Payment Element
        try await checkout.updateShippingAddress(
            name: "Jenny Rosen",
            address: .init(country: "US", line1: "354 Oyster Point Blvd")
        )

        // Then the removed card must stay absent from the same embedded presentation.
        XCTAssertFalse(embedded.savedPaymentMethods.contains { $0.stripeId == card.stripeId })
    }

    func testLiveGuestCanOptIntoSavingCardWhenCustomerWillBeCreated() async throws {
        // Given a live guest session explicitly configured to create a customer and offer saving
        HTTPStubs.removeAllStubs()
        let checkout = try await makeCustomerLogicCheckout(withSavedCard: false)
        XCTAssertNil(checkout.session.customerId)
        XCTAssertEqual(checkout.session.savedPaymentMethodsOfferSave?.enabled, true)
        // Exclude the separate Link experiment that intentionally hides this checkbox.
        XCTAssertFalse(checkout.session.elementsSession.linkSignupOptInFeatureEnabled)

        // When the card form is built through the loaded Payment Element
        let embedded = checkout.getPaymentElement().embeddedPaymentElement
        let presentingViewController = UIViewController()
        embedded.presentingViewController = presentingViewController
        let cardRow = try XCTUnwrap(embedded.embeddedPaymentMethodsView.rowButtons.first {
            $0.type == .new(paymentMethodType: .stripe(.card))
        })
        embedded.embeddedPaymentMethodsView.didTap(rowButton: cardRow)
        let form = try XCTUnwrap(embedded.formCache[.stripe(.card)])
        let saveCheckbox = form.getAllUnwrappedSubElements().compactMap { $0 as? CheckboxElement }
            .first { $0.label.hasPrefix("Save") }

        // Then the guest must be able to consent to saving their card for the new customer.
        XCTAssertNotNil(saveCheckbox)
    }

    private func makeCustomerLogicCheckout(withSavedCard: Bool) async throws -> CheckoutElementsController {
        let keyResponse = try await customerLogicBackendRequest(endpoint: "publishable_key?merchant=US")
        let apiClient = STPAPIClient(publishableKey: try XCTUnwrap(keyResponse["publishable_key"] as? String))
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
                                "price_data": [
                                    "currency": "usd",
                                    "unit_amount": 2000,
                                    "product_data": ["name": "Customer logic repro"],
                                ],
                                "quantity": 1,
                            ],
                        ],
                    ],
                ],
            ],
            "saved_payment_method_options": [
                "payment_method_save": "enabled",
                "payment_method_remove": "enabled",
                "allow_redisplay_filters": ["always", "limited", "unspecified"],
            ],
        ]
        if withSavedCard {
            let customerID = try await STPTestingAPIClient.shared.createCheckoutCustomer(email: "customer@example.com")
            let card = STPPaymentMethodCardParams()
            card.number = "4242424242424242"
            card.expMonth = 12
            card.expYear = 2040
            card.cvc = "123"
            let paymentMethod = try await apiClient.createPaymentMethod(with: .init(
                card: card,
                billingDetails: nil,
                allowRedisplay: .always,
                metadata: nil
            ))
            _ = try await customerLogicBackendRequest(endpoint: "attach_payment_method", parameters: [
                "merchant": "US",
                "payment_method_id": paymentMethod.stripeId,
                "request_params": ["customer": customerID],
            ])
            sessionParameters["customer"] = customerID
        } else {
            sessionParameters["customer_creation"] = "always"
        }
        let response = try await customerLogicBackendRequest(endpoint: "create_checkout_session", parameters: [
            "merchant": "US",
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

    private func customerLogicBackendRequest(
        endpoint: String,
        parameters: [String: Any]? = nil
    ) async throws -> [String: Any] {
        let url = try XCTUnwrap(URL(string: STPTestingAPIClient.STPTestingPlaygroundBackendURL + endpoint))
        var request = URLRequest(url: url)
        request.httpMethod = parameters == nil ? "GET" : "POST"
        if let parameters {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertTrue((200..<300).contains(httpResponse.statusCode), "Playground request failed: \(json)")
        return json
    }

    func testLoadCheckoutSession() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession()
        var configuration = CheckoutElementsController.Configuration(clientSecret: checkoutSessionResponse.clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await CheckoutElementsController(configuration: configuration)

        let session = checkout.session
        XCTAssertEqual(session.id, checkoutSessionResponse.id)
        XCTAssertEqual(session.status, .open)
        XCTAssertEqual(session.currency, "usd")
        XCTAssertFalse(session.livemode)
        XCTAssertEqual(session.totals.total.minorUnitsAmount, 2000)
        XCTAssertFalse(checkout.isUpdating)
    }

    func testCheckoutSessionWithEmailOnCustomer() async throws {
        // Given a Checkout Session whose Customer has an email
        let customerID = try await STPTestingAPIClient.shared.createCheckoutCustomer(
            email: "customer@example.com"
        )
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            customerID: customerID
        )
        var configuration = CheckoutElementsController.Configuration(
            clientSecret: checkoutSessionResponse.clientSecret,
            returnURL: "stripe-ios-test://checkout-return"
        )
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)

        // When initializing CheckoutElementsController
        let checkout = try await CheckoutElementsController(configuration: configuration)

        // Then Customer.email becomes the server-backed effective Session email
        XCTAssertEqual(checkout.session.serverEmail, "customer@example.com")
        XCTAssertNil(checkout.session.localState.email)
        XCTAssertEqual(checkout.session.email, "customer@example.com")
    }

    // TODO(porter): unified mode does not yet support promo codes.
    func disabled_testPromotionCodeApplyEmitsSessionUpdates() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            allowPromotionCodes: true
        )
        var configuration = CheckoutElementsController.Configuration(clientSecret: checkoutSessionResponse.clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await CheckoutElementsController(configuration: configuration)

        let recorder = CheckoutEmissionRecorder(checkout)

        try await checkout.applyPromotionCode("SAVE25")

        // Applying the promotion code emits once for the server-backed Checkout session update
        // and once when PaymentElement re-syncs its local payment option.
        XCTAssertEqual(recorder.sessions.count, 2)
        XCTAssertEqual(promotionCode(in: recorder.sessions.last), "SAVE25")
        XCTAssertEqual(recorder.loading, [true, false])
    }

    // TODO(porter): see disabled_testPromotionCodeApplyEmitsSessionUpdates above.
    func disabled_testApplyPromotionCode() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            allowPromotionCodes: true
        )
        var configuration = CheckoutElementsController.Configuration(clientSecret: checkoutSessionResponse.clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await CheckoutElementsController(configuration: configuration)

        XCTAssertTrue(checkout.session.discountAmounts.isEmpty)
        XCTAssertNil(promotionCode(in: checkout.session))
        XCTAssertEqual(2000, checkout.session.totals.total.minorUnitsAmount)

        try await checkout.applyPromotionCode("SAVE25")

        let session = checkout.session
        XCTAssertFalse(session.discountAmounts.isEmpty)
        XCTAssertEqual(promotionCode(in: session), "SAVE25")
        XCTAssertEqual(1500, session.totals.total.minorUnitsAmount)
    }

    // TODO(porter): see disabled_testPromotionCodeApplyEmitsSessionUpdates above.
    func disabled_testRemovePromotionCode() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            allowPromotionCodes: true
        )
        var configuration = CheckoutElementsController.Configuration(clientSecret: checkoutSessionResponse.clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await CheckoutElementsController(configuration: configuration)

        // Apply first
        try await checkout.applyPromotionCode("SAVE25")
        XCTAssertFalse(checkout.session.discountAmounts.isEmpty)
        XCTAssertEqual(promotionCode(in: checkout.session), "SAVE25")
        XCTAssertEqual(1500, checkout.session.totals.total.minorUnitsAmount)

        // Then remove
        try await checkout.removePromotionCode()
        let session = checkout.session
        XCTAssertTrue(session.discountAmounts.isEmpty)
        XCTAssertNil(promotionCode(in: session))
        XCTAssertEqual(2000, session.totals.total.minorUnitsAmount)
    }

    // TODO(porter): see disabled_testPromotionCodeApplyEmitsSessionUpdates above.
    func disabled_testApplyInvalidPromotionCode() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            allowPromotionCodes: true
        )
        var configuration = CheckoutElementsController.Configuration(clientSecret: checkoutSessionResponse.clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await CheckoutElementsController(configuration: configuration)

        do {
            try await checkout.applyPromotionCode("BOGUS_CODE_123")
            XCTFail("Expected CheckoutError.apiError")
        } catch let error as CheckoutError {
            guard case .apiError = error else {
                XCTFail("Expected .apiError, got \(error)")
                return
            }
        }
    }

    func testUpdateBillingTaxRegionIfNecessary() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            amount: 5050,
            merchantCountry: "us_tax",
            collectBillingAddress: true,
            automaticTax: true
        )
        var configuration = CheckoutElementsController.Configuration(clientSecret: checkoutSessionResponse.clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await CheckoutElementsController(configuration: configuration)

        // Pre-tax price, CA sales has not yet been applied
        XCTAssertEqual(checkout.session.totals.subtotal.minorUnitsAmount, 5050)
        XCTAssertEqual(checkout.session.totals.total.minorUnitsAmount, 5050)

        // Update the billing tax region to get tax applied
        try await checkout.updateBillingTaxRegionIfNecessary(
            address: .init(
                country: "US",
                line1: "123 Main St",
                city: "San Francisco",
                state: "CA",
                postalCode: "94105"
            )
        )

        // Session should be refreshed (tax_region was sent to the server)
        XCTAssertEqual(checkout.session.status, .open)

        // Post-tax price, CA sales tax was applied; subtotal unchanged proves the increase is purely tax
        XCTAssertEqual(checkout.session.totals.subtotal.minorUnitsAmount, 5050)
        XCTAssertEqual(checkout.session.totals.total.minorUnitsAmount, 5486)

        // When the billing address is removed, let CheckoutClient resolve the default tax country.
        try await checkout.updateBillingTaxRegionIfNecessary(address: nil)

        // Then the previous street address no longer supplies the tax calculation.
        XCTAssertEqual(checkout.session.status, .open)
        XCTAssertEqual(checkout.session.tax?.status, .requiresBillingAddress)
        XCTAssertEqual(checkout.session.totals.total.minorUnitsAmount, 5050)
    }

    func testLoadUnifiedModeCheckoutSession() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            merchantCountry: "us_tax"
        )
        var configuration = CheckoutElementsController.Configuration(clientSecret: checkoutSessionResponse.clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await CheckoutElementsController(configuration: configuration)

        let session = checkout.session
        XCTAssertEqual(session.id, checkoutSessionResponse.id)
        XCTAssertEqual(session.status, .open)
        XCTAssertEqual(session.totals.total.minorUnitsAmount, 2000)
        XCTAssertEqual(session.amount, 2000)
        XCTAssertEqual(session.orderSummaryItems.count, 1)
        guard case .oneTimePrice(let oneTimePrice) = session.orderSummaryItems.first else {
            return XCTFail("Expected one-time price order summary item")
        }
        XCTAssertFalse(oneTimePrice.key.isEmpty)
        XCTAssertNil(oneTimePrice.description)
        XCTAssertEqual(oneTimePrice.items.count, 1)
        let item = try XCTUnwrap(oneTimePrice.items.first)
        XCTAssertFalse(item.key.isEmpty)
        XCTAssertEqual(item.displayName, "Test")
        XCTAssertEqual(item.images, [])
        XCTAssertEqual(item.unitAmount.minorUnitsAmount, 2000)
        XCTAssertEqual(item.unitAmountDecimal?.minorUnitsAmount, 2000)
        XCTAssertNil(item.unitLabel)
        XCTAssertEqual(item.quantity, 1)
        XCTAssertNil(item.adjustableQuantity)
        XCTAssertEqual(item.amountDetails.subtotal.minorUnitsAmount, 2000)
        XCTAssertEqual(item.amountDetails.total.minorUnitsAmount, 2000)
        XCTAssertNil(item.amountDetails.taxAmounts)
        XCTAssertEqual(item.amountDetails.taxInclusive.minorUnitsAmount, 0)
        XCTAssertEqual(item.amountDetails.taxExclusive.minorUnitsAmount, 0)
    }

    func testUpdateShippingAddress() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            merchantCountry: "us_tax",
            automaticTax: true,
            allowedShippingCountries: ["US"]
        )
        var configuration = CheckoutElementsController.Configuration(clientSecret: checkoutSessionResponse.clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await CheckoutElementsController(configuration: configuration)

        XCTAssertNil(checkout.session.shippingAddress)
        XCTAssertEqual(checkout.session.totals.subtotal.minorUnitsAmount, 2000)
        XCTAssertEqual(checkout.session.totals.total.minorUnitsAmount, 2000)
        XCTAssertNotNil(checkout.session.taxAmounts)
        XCTAssertTrue(checkout.session.taxAmounts?.isEmpty == true)

        try await checkout.updateShippingAddress(
            name: "John Smith",
            address: .init(
                country: "US",
                line1: "456 Oak Ave",
                city: "Los Angeles",
                state: "CA",
                postalCode: "90001"
            )
        )

        // Address should be stored on the session
        let storedShipping = checkout.session.shippingAddress
        XCTAssertNotNil(storedShipping)
        XCTAssertEqual(storedShipping?.name, "John Smith")
        XCTAssertEqual(storedShipping?.address.country, "US")
        XCTAssertEqual(storedShipping?.address.line1, "456 Oak Ave")
        XCTAssertEqual(storedShipping?.address.city, "Los Angeles")
        XCTAssertEqual(storedShipping?.address.state, "CA")
        XCTAssertEqual(storedShipping?.address.postalCode, "90001")

        // Session should be refreshed (tax_region was sent to the server)
        XCTAssertEqual(checkout.session.status, .open)

        XCTAssertEqual(checkout.session.totals.subtotal.minorUnitsAmount, 2000)
        XCTAssertEqual(checkout.session.taxAmounts?.count, 1)
        let taxAmount = try XCTUnwrap(checkout.session.taxAmounts?.first?.minorUnitsAmount)
        XCTAssertGreaterThan(taxAmount, 0)
        XCTAssertEqual(
            checkout.session.totals.total.minorUnitsAmount,
            checkout.session.totals.subtotal.minorUnitsAmount + taxAmount
        )

        // When the shipping address is removed, let CheckoutClient resolve the default tax country.
        try await checkout.updateShippingAddress(name: nil, address: nil)

        // Then local shipping and the previous address's tax calculation are cleared together.
        XCTAssertNil(checkout.session.shippingAddress)
        XCTAssertEqual(checkout.session.status, .open)
        XCTAssertEqual(checkout.session.tax?.status, .requiresShippingAddress)
        XCTAssertEqual(checkout.session.totals.total.minorUnitsAmount, 2000)
    }

    func testClearLocalCustomerDataClearsLinkState() {
        // Given a customer who has used Link
        UserDefaults.standard.markLinkAsUsed()
        XCTAssertTrue(UserDefaults.standard.customerHasUsedLink)
        // ...and has a Link account in memory
        LinkAccountContext.shared.account = PaymentSheetLinkAccount(
            email: "user@example.com",
            session: nil,
            publishableKey: nil,
            displayablePaymentDetails: nil,
            apiClient: STPAPIClient(publishableKey: STPTestingDefaultPublishableKey),
            useMobileEndpoints: false,
            canSyncAttestationState: false
        )
        defer {
            LinkAccountContext.shared.account = nil
        }

        // When the customer is reset
        CheckoutElementsController.clearLocalCustomerData()

        // Then the persisted Link state is cleared
        XCTAssertFalse(UserDefaults.standard.customerHasUsedLink)
        // ...and the in-memory Link account is cleared
        XCTAssertNil(LinkAccountContext.shared.account)
    }

    func testClearLocalCustomerDataLogsAnalytic() {
        let analyticsClient = STPAnalyticsClient.sharedClient
        let previousLogHistory = analyticsClient._testLogHistory
        analyticsClient._testLogHistory = []
        defer { analyticsClient._testLogHistory = previousLogHistory }

        CheckoutElementsController.clearLocalCustomerData()

        let events = analyticsClient._testLogHistory.filter {
            $0["event"] as? String == "checkout_elements.clear_local_customer_data"
        }
        XCTAssertEqual(events.count, 1)
    }

    private func promotionCode(in session: CheckoutElementsController.Session?) -> String? {
        session?.discountAmounts.first(where: { $0.promotionCode != nil })?.promotionCode
    }
}
