//
//  CheckoutApplePayContextTests.swift
//  StripePaymentSheetTests
//
//  Created by Joyce Qin on 8/3/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Contacts
import OHHTTPStubs
import OHHTTPStubsSwift
import PassKit
@testable @_spi(InternalOnlyAPI) import StripeCore
@testable @_spi(InternalOnlyAPI) import StripeCoreTestUtils
@testable @_spi(InternalOnlyAPI) import StripePayments
@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
import StripePaymentsObjcTestUtils
import UIKit
import XCTest

@MainActor
final class CheckoutApplePayContextTests: XCTestCase {

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    // MARK: - makeSummaryItems

    func testMakeSummaryItemsWithAmount() {
        // Given a session with a single item and no tax
        let session = CheckoutTestHelpers.makeSession([
            "items": CheckoutTestHelpers.makeOneTimePriceCheckoutItems(unitAmount: 2500),
            "presentment_currency": "usd",
        ]).makePublicSession()

        // When
        let items = CheckoutApplePayContext.makeSummaryItems(for: session, label: "Test Store")

        // Then it returns the item row and a grand total, with no breakdown rows
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].label, "Test product")
        XCTAssertEqual(items[0].amount, NSDecimalNumber.stp_decimalNumber(withAmount: 2500, currency: "usd"))
        XCTAssertEqual(items[1].label, "Test Store")
        XCTAssertEqual(items[1].type, .final)
        XCTAssertEqual(items[1].amount, NSDecimalNumber.stp_decimalNumber(withAmount: 2500, currency: "usd"))
    }

    func testMakeSummaryItemsWithLineItemsAndBreakdown() {
        // Given a session with two line items and tax on one of them
        let session = CheckoutTestHelpers.makeSession([
            "items": [
                [
                    "key": "checkout_item_widget",
                    "type": "one_time_price",
                    "one_time_price": [
                        "items": [
                            [
                                "inner_item_key": "widget",
                                "quantity": 1,
                                "unit_amount": 2000,
                                "unit_amount_decimal": "2000",
                                "amount_details": [
                                    "subtotal": 2000,
                                    "total": 2200,
                                    "tax_amounts": [],
                                    "tax_inclusive": 0,
                                    "tax_exclusive": 200,
                                ],
                                "price": ["id": "price_widget", "currency": "usd", "unit_amount": 2000, "product": ["name": "Widget", "images": []]],
                            ],
                        ],
                        "subtotal": 2000,
                        "total": 2200,
                    ],
                ],
                [
                    "key": "checkout_item_gadget",
                    "type": "one_time_price",
                    "one_time_price": [
                        "items": [
                            [
                                "inner_item_key": "gadget",
                                "quantity": 2,
                                "unit_amount": 500,
                                "unit_amount_decimal": "500",
                                "amount_details": [
                                    "subtotal": 1000,
                                    "total": 1000,
                                    "tax_amounts": [],
                                    "tax_inclusive": 0,
                                    "tax_exclusive": 0,
                                ],
                                "price": ["id": "price_gadget", "currency": "usd", "unit_amount": 500, "product": ["name": "Gadget", "images": []]],
                            ],
                        ],
                        "subtotal": 1000,
                        "total": 1000,
                    ],
                ],
            ],
            "presentment_currency": "usd",
        ]).makePublicSession()

        // When
        let items = CheckoutApplePayContext.makeSummaryItems(for: session, label: "Test Store")

        // Then it returns line items, subtotal, tax, and a grand total (discount rows are unsupported in unified mode)
        XCTAssertEqual(items.count, 5)
        XCTAssertEqual(items[0].label, "Widget")
        XCTAssertEqual(items[0].amount, NSDecimalNumber.stp_decimalNumber(withAmount: 2000, currency: "usd"))
        XCTAssertEqual(items[1].label, "Gadget ×2")
        XCTAssertEqual(items[1].amount, NSDecimalNumber.stp_decimalNumber(withAmount: 1000, currency: "usd"))
        XCTAssertEqual(items[2].label, String.Localized.subtotal)
        XCTAssertEqual(items[2].amount, NSDecimalNumber.stp_decimalNumber(withAmount: 3000, currency: "usd"))
        XCTAssertEqual(items[3].label, String.Localized.tax)
        XCTAssertEqual(items[3].amount, NSDecimalNumber.stp_decimalNumber(withAmount: 200, currency: "usd"))
        XCTAssertEqual(items[4].label, "Test Store")
        XCTAssertEqual(items[4].amount, NSDecimalNumber.stp_decimalNumber(withAmount: 3200, currency: "usd"))
    }

    func testMakeSummaryItemsWithLBPTaxAndQuantity() {
        // Given three items at 23.01 LBP each and 0.49 LBP in tax
        let intent = Intent._testCheckoutSession(
            amount: 6952,
            currency: "lbp",
            oneTimePriceItems: [.init(key: "li_1", displayName: "Widget", quantity: 3, unitAmount: 2301)],
            subtotal: 6903,
            taxAmount: 49
        )
        guard case .checkout(let session) = intent else {
            XCTFail("Expected checkout intent")
            return
        }

        // When building the Apple Pay summary
        let items = CheckoutApplePayContext.makeSummaryItems(for: session, label: "Test Store")

        // Then every row uses whole pounds, rounding after multiplying by quantity
        XCTAssertEqual(items.map(\.amount), [70, 70, 1, 70])
        XCTAssertEqual(session.amount, 6952)
    }

    func testMakeSummaryItemsWithNoAmount() {
        // Given a no-payment-required session (e.g. free order)
        let session = CheckoutTestHelpers.makeSession(["payment_status": "no_payment_required"]).makePublicSession()

        // When
        let items = CheckoutApplePayContext.makeSummaryItems(for: session, label: "Test Store")

        // Then it returns a pending item with zero amount
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].label, "Test Store")
        XCTAssertEqual(items[0].type, .pending)
        XCTAssertEqual(items[0].amount, .zero)
    }

    func testMakePaymentRequestUsesPresentmentCurrency() {
        for (currency, amount, expectedAmount, exchangeRate) in [
            ("jpy", 19181, "19181", "159.8416666667"),
            ("eur", 10762, "107.62", "0.8968333333"),
        ] {
            // Given a USD merchant presenting a localized checkout
            let session = CheckoutTestHelpers.makeSession([
                "adaptive_pricing_info": [
                    "local_currency_options": [
                        [
                            "currency": currency,
                            "amount": amount,
                            "presentment_exchange_rate": exchangeRate,
                            "conversion_markup_bps": 400,
                        ],
                    ],
                    "integration_currency_option": [
                        "currency": "usd",
                        "amount": 12000,
                    ],
                ],
                "items": CheckoutTestHelpers.makeOneTimePriceCheckoutItems(currency: currency, unitAmount: amount),
                "presentment_currency": currency,
            ]).makePublicSession()
            let parameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
                apiClient: APIStubbedTestCase.stubbedAPIClient()
            )

            // When building the native payment sheet
            let request = CheckoutApplePayContext.makePaymentRequest(
                checkoutSession: session,
                applePayConfirmationParameters: parameters
            )

            // Then its currency, line item, and total all use the presentment currency
            XCTAssertEqual(request.currencyCode, currency.uppercased())
            XCTAssertEqual(request.paymentSummaryItems.count, 2)
            XCTAssertEqual(request.paymentSummaryItems.first?.amount, NSDecimalNumber(string: expectedAmount))
            XCTAssertEqual(request.paymentSummaryItems.last?.amount, NSDecimalNumber(string: expectedAmount))
        }
    }

    func testMakePaymentRequestWithoutAdaptivePricingUsesSessionCurrency() {
        // Given a checkout without an alternate currency
        let session = CheckoutTestHelpers.makeSession([
            "items": CheckoutTestHelpers.makeOneTimePriceCheckoutItems(unitAmount: 12000),
            "presentment_currency": "usd",
        ]).makePublicSession()
        let parameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: APIStubbedTestCase.stubbedAPIClient()
        )

        // When building the native payment sheet
        let request = CheckoutApplePayContext.makePaymentRequest(
            checkoutSession: session,
            applePayConfirmationParameters: parameters
        )

        // Then it retains the session currency and amount
        XCTAssertEqual(request.merchantIdentifier, "merchant.com.test")
        XCTAssertEqual(request.countryCode, "US")
        XCTAssertEqual(request.currencyCode, "USD")
        XCTAssertEqual(request.paymentSummaryItems.count, 2)
        XCTAssertEqual(request.paymentSummaryItems.last?.label, "Test Merchant")
        XCTAssertEqual(request.paymentSummaryItems.last?.type, .final)
        XCTAssertEqual(request.paymentSummaryItems.last?.amount, NSDecimalNumber(string: "120"))
    }

    func testMakePaymentRequestWithNoPaymentRequired() {
        for amount: Int? in [nil, 0] {
            // Given a setup session with an absent or zero amount
            let intent = Intent._testCheckoutSession(hasPaymentDue: false, amount: amount, currency: "USD")
            guard case .checkout(let session) = intent else {
                XCTFail("Expected checkout intent")
                return
            }
            let parameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
                apiClient: APIStubbedTestCase.stubbedAPIClient()
            )

            // When building the Apple Pay request
            let request = CheckoutApplePayContext.makePaymentRequest(
                checkoutSession: session,
                applePayConfirmationParameters: parameters
            )

            // Then the request has a pending zero total and the configured merchant details
            XCTAssertEqual(request.merchantIdentifier, "merchant.com.test")
            XCTAssertEqual(request.countryCode, session.merchantCountryCode)
            XCTAssertEqual(request.currencyCode, "USD")
            XCTAssertEqual(request.paymentSummaryItems.count, 1)
            XCTAssertEqual(request.paymentSummaryItems.first?.label, "Test Merchant")
            XCTAssertEqual(request.paymentSummaryItems.first?.type, .pending)
            XCTAssertEqual(request.paymentSummaryItems.first?.amount, .zero)
        }
    }

    func testMakePaymentRequestWithLBP() {
        // Given a Checkout Session with an amount of 23.45 LBP
        let session = CheckoutTestHelpers.makeSession([
            "integration_currency": "lbp",
            "presentment_currency": "lbp",
            "items": CheckoutTestHelpers.makeOneTimePriceCheckoutItems(currency: "lbp", unitAmount: 2345),
        ]).makePublicSession()
        let parameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: APIStubbedTestCase.stubbedAPIClient()
        )

        // When building the Apple Pay request
        let request = CheckoutApplePayContext.makePaymentRequest(
            checkoutSession: session,
            applePayConfirmationParameters: parameters
        )

        // Then the displayed total rounds up to whole pounds without changing the amount to charge
        XCTAssertEqual(request.paymentSummaryItems.last?.amount, NSDecimalNumber(string: "24"))
        XCTAssertEqual(request.currencyCode, "LBP")
        XCTAssertEqual(session.amount, 2345)
    }

    // MARK: - makePaymentRequest shipping address

    func testMakePaymentRequestRequiresShippingAddress() {
        // Given Apple Pay requires a shipping address
        let session = CheckoutTestHelpers.makeSession().makePublicSession()
        let parameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: APIStubbedTestCase.stubbedAPIClient(),
            shippingAddressRequired: true
        )

        // When
        let paymentRequest = CheckoutApplePayContext.makePaymentRequest(
            checkoutSession: session,
            applePayConfirmationParameters: parameters
        )

        // Then Apple Pay requires the customer's name and postal address
        XCTAssertTrue(paymentRequest.requiredShippingContactFields.contains(.name))
        XCTAssertTrue(paymentRequest.requiredShippingContactFields.contains(.postalAddress))
    }

    func testMakePaymentRequestDoesNotRequireShippingAddressByDefault() {
        // Given an Apple Pay confirmation
        let session = CheckoutTestHelpers.makeSession().makePublicSession()
        let parameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: APIStubbedTestCase.stubbedAPIClient()
        )

        // When
        let paymentRequest = CheckoutApplePayContext.makePaymentRequest(
            checkoutSession: session,
            applePayConfirmationParameters: parameters
        )
        // Then Apple Pay does not require shipping address contact fields
        XCTAssertFalse(paymentRequest.requiredShippingContactFields.contains(.name))
        XCTAssertFalse(paymentRequest.requiredShippingContactFields.contains(.postalAddress))
    }

    func testMakePaymentRequestRequiresEmail() {
        // Given Apple Pay needs to collect the customer's email
        let session = CheckoutTestHelpers.makeSession().makePublicSession()
        let parameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: APIStubbedTestCase.stubbedAPIClient()
        )

        // When building the payment request
        let paymentRequest = CheckoutApplePayContext.makePaymentRequest(
            checkoutSession: session,
            applePayConfirmationParameters: parameters
        )

        // Then Apple Pay requires an email contact field
        XCTAssertTrue(paymentRequest.requiredShippingContactFields.contains(.emailAddress))
    }

    func testMakePaymentRequestDoesNotRequireEmailWhenSessionHasServerEmail() {
        let session = CheckoutTestHelpers.makeSession([
            "customer_email": "customer@example.com"
        ]).makePublicSession()
        let parameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: APIStubbedTestCase.stubbedAPIClient()
        )

        let paymentRequest = CheckoutApplePayContext.makePaymentRequest(
            checkoutSession: session,
            applePayConfirmationParameters: parameters
        )

        XCTAssertFalse(paymentRequest.requiredShippingContactFields.contains(.emailAddress))
    }

    func testMakePaymentRequestDoesNotRequireEmailWhenSessionHasMerchantDefaultEmail() {
        var session = CheckoutTestHelpers.makeSession().makePublicSession()
        session.localState.email = "merchant@example.com"
        let parameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: APIStubbedTestCase.stubbedAPIClient()
        )

        let paymentRequest = CheckoutApplePayContext.makePaymentRequest(
            checkoutSession: session,
            applePayConfirmationParameters: parameters
        )

        XCTAssertFalse(paymentRequest.requiredShippingContactFields.contains(.emailAddress))
    }

    func testMakePaymentRequestPrefillsExistingShippingAddress() {
        // Given the Checkout Session already has a shipping address
        let shippingAddress = CheckoutController.Session.ShippingAddress(
            name: "Jane Doe",
            address: .init(
                country: "US",
                line1: "510 Townsend St",
                line2: "Apt 2",
                city: "San Francisco",
                state: "CA",
                postalCode: "94103"
            )
        )
        var session = CheckoutTestHelpers.makeSession().makePublicSession()
        session.localState.shippingAddress = shippingAddress
        let parameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: APIStubbedTestCase.stubbedAPIClient(),
            shippingAddressRequired: true
        )

        // When
        let paymentRequest = CheckoutApplePayContext.makePaymentRequest(
            checkoutSession: session,
            applePayConfirmationParameters: parameters
        )

        // Then Apple Pay preselects the existing shipping address
        XCTAssertEqual(paymentRequest.shippingContact?.name?.givenName, "Jane")
        XCTAssertEqual(paymentRequest.shippingContact?.postalAddress?.street, "510 Townsend St\nApt 2")
        XCTAssertEqual(paymentRequest.shippingContact?.postalAddress?.postalCode, "94103")
        XCTAssertEqual(paymentRequest.shippingContact?.postalAddress?.isoCountryCode, "US")
    }

    func testSessionShippingAddressMakesPaymentIntentShippingDetailsParams() {
        // Given a shipping address stored locally on the Checkout Session
        let shippingAddress = CheckoutController.Session.ShippingAddress(
            name: "Jane Doe",
            address: .init(
                country: "US",
                line1: "510 Townsend St",
                line2: "Apt 2",
                city: "San Francisco",
                state: "CA",
                postalCode: "94103"
            )
        )

        // When
        let shipping = shippingAddress.shippingDetailsParams

        // Then it can be sent when Apple Pay doesn't collect a shipping contact
        XCTAssertEqual(shipping?.name, "Jane Doe")
        XCTAssertEqual(shipping?.address.line1, "510 Townsend St")
        XCTAssertEqual(shipping?.address.line2, "Apt 2")
        XCTAssertEqual(shipping?.address.city, "San Francisco")
        XCTAssertEqual(shipping?.address.state, "CA")
        XCTAssertEqual(shipping?.address.postalCode, "94103")
        XCTAssertEqual(shipping?.address.country, "US")
    }

    func testDidSelectShippingContactAllowsConfiguredCountry() {
        // Given a Checkout Session with a lowercase country code that allows shipping to the US
        let (context, controller) = makeShippingContext(allowedCountries: ["us"])
        let contact = makeShippingContact(country: "US")

        // When
        var receivedUpdate: PKPaymentRequestShippingContactUpdate?
        context.paymentAuthorizationController(controller, didSelectShippingContact: contact) {
            receivedUpdate = $0
        }

        // Then Apple Pay accepts the contact
        XCTAssertTrue(receivedUpdate?.errors?.isEmpty ?? true)
    }

    func testDidSelectShippingContactRejectsDisallowedCountry() {
        // Given a Checkout Session that only allows shipping to the US
        let (context, controller) = makeShippingContext(allowedCountries: ["US"])
        let contact = makeShippingContact(country: "CA")

        // When
        var receivedUpdate: PKPaymentRequestShippingContactUpdate?
        context.paymentAuthorizationController(controller, didSelectShippingContact: contact) {
            receivedUpdate = $0
        }

        // Then Apple Pay rejects the unserviceable address before authorization
        let error = receivedUpdate?.errors?.first as NSError?
        let expectedError = CheckoutError.invalidShippingCountry(countryCode: "CA") as NSError
        XCTAssertEqual(error?.domain, expectedError.domain)
        XCTAssertEqual(error?.code, expectedError.code)
    }

    func testDidSelectShippingContactUpdatesShippingTaxRegion() async {
        // Given a Checkout Session that calculates automatic tax from shipping
        let updatedSession = CheckoutTestHelpers.makeSession([
            "shipping_address_collection": ["allowed_countries": ["US"]],
            "items": CheckoutTestHelpers.makeOneTimePriceCheckoutItems(unitAmount: 1200),
            "automatic_tax": [
                "enabled": true,
                "status": "ready",
                "address_source": "shipping",
            ],
        ]).makePublicSession()
        let updater = MockCheckoutSessionWalletUpdater(sessionToReturn: updatedSession)
        let (context, controller) = makeShippingContext(
            allowedCountries: ["US"],
            automaticTaxAddressSource: "shipping",
            checkoutWalletUpdater: updater
        )
        let contact = makeShippingContact(country: "US", postalCode: "94107")

        // When Apple Pay selects the shipping contact
        let update = await withCheckedContinuation { continuation in
            context.paymentAuthorizationController(controller, didSelectShippingContact: contact) {
                continuation.resume(returning: $0)
            }
        }

        // Then Checkout updates the shipping tax region before refreshing Apple Pay totals
        XCTAssertEqual(updater.updateCallCount, 1)
        XCTAssertEqual(updater.lastAddress?.country, "US")
        XCTAssertEqual(updater.lastAddress?.postalCode, "94107")
        XCTAssertEqual(update.paymentSummaryItems.last?.amount, NSDecimalNumber(string: "12"))
    }

    func testDidSelectShippingContactDoesNotUpdateBillingSourcedTaxRegion() {
        // Given a Checkout Session whose automatic tax source is billing
        let updater = MockCheckoutSessionWalletUpdater()
        let (context, controller) = makeShippingContext(
            allowedCountries: ["US"],
            automaticTaxAddressSource: "billing",
            checkoutWalletUpdater: updater
        )

        // When Apple Pay selects a shipping contact
        context.paymentAuthorizationController(
            controller,
            didSelectShippingContact: makeShippingContact(country: "US", postalCode: "94107")
        ) { _ in }

        // Then Checkout does not use it as the tax region
        XCTAssertEqual(updater.updateCallCount, 0)
    }

    func testCancelWaitsForShippingTaxUpdateAndRestoresTaxRegion() async {
        let existingTaxRegion = CheckoutController.Address(country: "US", postalCode: "10001")

        for initialTaxRegion in [existingTaxRegion, nil] {
            // Given an in-flight shipping tax update
            let returnedSession = CheckoutTestHelpers.makeSession().makePublicSession()
            let updater = MockCheckoutSessionWalletUpdater(
                sessionToReturn: returnedSession,
                currentTaxRegion: initialTaxRegion,
                suspendsFirstUpdate: true
            )
            let (context, controller) = makeShippingContext(
                allowedCountries: ["US"],
                automaticTaxAddressSource: "shipping",
                checkoutWalletUpdater: updater
            )
            var didReturnResult = false
            let resultTask = Task {
                let result = await context.presentApplePay()
                didReturnResult = true
                return result
            }
            await Task.yield()
            context.paymentAuthorizationController(
                controller,
                didSelectShippingContact: makeShippingContact(country: "US", postalCode: "94107")
            ) { _ in }
            while !updater.isWaiting {
                await Task.yield()
            }

            // When Apple Pay is canceled before its tax update completes
            context.paymentAuthorizationControllerDidFinish(controller)
            await Task.yield()

            // Then cancellation waits for the update and restores the previous region, including nil
            XCTAssertFalse(didReturnResult)
            updater.resume()
            let result = await resultTask.value
            XCTAssertEqual(result.paymentSheetResult, .canceled)
            XCTAssertEqual(updater.updateCallCount, 2)
            XCTAssertEqual(updater.lastAddress, initialTaxRegion)
            XCTAssertEqual(updater.currentTaxRegion, initialTaxRegion)
        }
    }

    // MARK: - makePaymentRequest billing/shipping contact fields

    func testMakePaymentRequest_billingTaxRequiresPostalAddress() {
        // Given automatic tax uses the billing address, even though address collection is .never
        let session = CheckoutTestHelpers.makeSession([
            "automatic_tax": [
                "enabled": true,
                "status": "ready",
                "address_source": "billing",
            ],
        ]).makePublicSession()
        let parameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: APIStubbedTestCase.stubbedAPIClient()
        )

        // When
        let paymentRequest = CheckoutApplePayContext.makePaymentRequest(
            checkoutSession: session,
            applePayConfirmationParameters: parameters
        )

        // Then Apple Pay collects the postal address needed to calculate tax
        XCTAssertTrue(paymentRequest.requiredBillingContactFields.contains(.postalAddress))
    }

    func testMakePaymentRequest_prefillsCompleteDefaultBillingAddress() {
        // Given default billing details with a street address
        let session = CheckoutTestHelpers.makeSession([:]).makePublicSession()
        var defaults = CheckoutController.Configuration.Defaults.BillingDetails()
        defaults.name = "Jane Doe"
        defaults.address = .init(
            country: "US",
            line1: "510 Townsend St",
            line2: "Apt 2",
            city: "San Francisco",
            state: "CA",
            postalCode: "94103"
        )
        let parameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: APIStubbedTestCase.stubbedAPIClient(),
            defaultBillingDetails: defaults
        )

        // When
        let paymentRequest = CheckoutApplePayContext.makePaymentRequest(
            checkoutSession: session,
            applePayConfirmationParameters: parameters
        )

        // Then Apple Pay is prefilled with the default billing contact
        XCTAssertEqual(paymentRequest.billingContact?.postalAddress?.street, "510 Townsend St\nApt 2")
        XCTAssertEqual(paymentRequest.billingContact?.postalAddress?.isoCountryCode, "US")
        XCTAssertEqual(paymentRequest.billingContact?.postalAddress?.city, "San Francisco")
        XCTAssertEqual(paymentRequest.billingContact?.postalAddress?.state, "CA")
        XCTAssertEqual(paymentRequest.billingContact?.postalAddress?.postalCode, "94103")
        XCTAssertEqual(paymentRequest.billingContact?.name?.givenName, "Jane")
    }

    func testMakePaymentRequest_doesNotPrefillCountryOnlyDefaultBillingAddress() {
        // Given default billing details without a street address
        let session = CheckoutTestHelpers.makeSession().makePublicSession()
        var defaults = CheckoutController.Configuration.Defaults.BillingDetails()
        defaults.address = .init(country: "GB")
        let parameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: APIStubbedTestCase.stubbedAPIClient(),
            defaultBillingDetails: defaults
        )

        // When
        let paymentRequest = CheckoutApplePayContext.makePaymentRequest(
            checkoutSession: session,
            applePayConfirmationParameters: parameters
        )

        // Then Apple Pay does not show an incomplete billing address as invalid
        XCTAssertNil(paymentRequest.billingContact)
    }

    func testMakePaymentRequest_prefillsDefaultBillingAddressWithLine1Only() {
        // Given default billing details with the minimum street address
        let session = CheckoutTestHelpers.makeSession().makePublicSession()
        var defaults = CheckoutController.Configuration.Defaults.BillingDetails()
        defaults.name = "John Smith"
        defaults.address = .init(country: "US", line1: "123 Main St")
        let parameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: APIStubbedTestCase.stubbedAPIClient(),
            defaultBillingDetails: defaults
        )

        // When
        let paymentRequest = CheckoutApplePayContext.makePaymentRequest(
            checkoutSession: session,
            applePayConfirmationParameters: parameters
        )

        // Then
        XCTAssertEqual(paymentRequest.billingContact?.postalAddress?.street, "123 Main St")
        XCTAssertEqual(paymentRequest.billingContact?.name?.givenName, "John")
    }

    func testMakePaymentRequest_doesNotPrefillMissingDefaultBillingAddress() {
        // Given no default billing address
        let session = CheckoutTestHelpers.makeSession().makePublicSession()
        let parameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: APIStubbedTestCase.stubbedAPIClient()
        )

        // When
        let paymentRequest = CheckoutApplePayContext.makePaymentRequest(
            checkoutSession: session,
            applePayConfirmationParameters: parameters
        )

        // Then
        XCTAssertNil(paymentRequest.billingContact)
    }

    // MARK: - presentation

    func testPresentationFailureReturnsCheckoutError() async {
        // Given PassKit refuses to present the Apple Pay sheet
        let analyticsClient = STPAnalyticsClient.sharedClient
        let previousLogHistory = analyticsClient._testLogHistory
        analyticsClient._testLogHistory = []
        defer { analyticsClient._testLogHistory = previousLogHistory }
        let (context, controller) = makeContext()
        controller.presentationSucceeds = false

        // When the unexpected-error assertion is captured by the test utility
        STPAssertTestUtil.shouldSuppressNextSTPAlert = true
        let result = await context.presentApplePay()

        // Then confirmation fails with actionable diagnostics
        guard case .failed(let error) = result.paymentSheetResult,
              case .unknown(let message) = error as? CheckoutError else {
            XCTFail("Expected an Apple Pay Checkout error, got \(result.paymentSheetResult)")
            return
        }
        XCTAssertTrue(message.contains("app is active"))
        XCTAssertTrue(message.contains("presenting window is visible"))
        XCTAssertTrue(error.localizedDescription.contains(message))

        // ...and the failure is logged once and triggers the expected SDK assertion
        let events = analyticsClient._testLogHistory.filter {
            $0["event"] as? String == "unexpected_error.checkout_elements"
        }
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?["error_code"] as? String, "unknown")
        XCTAssertEqual(events.first?["error_type"] as? String, "StripePaymentSheet.CheckoutError")
        XCTAssertFalse(STPAssertTestUtil.shouldSuppressNextSTPAlert)
        XCTAssertTrue(STPAssertTestUtil.lastAssertMessage.contains("unexpected_error.checkout_elements"))
    }

    // MARK: - presentationWindow

    func testPresentationWindowReturnsConfiguredWindow() {
        // Given
        let presentationWindow = UIWindow()
        let (context, authorizationController) = makeContext(presentationWindow: presentationWindow)

        // When
        let returnedWindow = context.presentationWindow(for: authorizationController)

        // Then
        XCTAssertIdentical(returnedWindow, presentationWindow)
    }

    // MARK: - Cancellation during tax updates

    func testDidFinish_notStarted_waitsForBillingTaxUpdateBeforeCanceling() async {
        // Given Apple Pay presented by ECE with a billing tax update that is suspended
        let updatedSession = CheckoutTestHelpers.makeOpenSession().makePublicSession()
        let updater = MockCheckoutSessionWalletUpdater(
            sessionToReturn: updatedSession,
            suspendsFirstUpdate: true
        )
        let (context, mockController) = makeContext(
            collectsTaxFromBillingAddress: true,
            checkoutWalletUpdater: updater,
            attribution: .init(confirmingElement: .expressCheckoutElement, configuredElements: [.expressCheckoutElement])
        )
        var didReturnResult = false
        let resultTask = Task {
            let result = await context.presentApplePay()
            didReturnResult = true
            return result
        }
        await Task.yield()

        let paymentMethod = MockPKPaymentMethod(billingAddress: makeBillingContact())
        context.paymentAuthorizationController(mockController, didSelectPaymentMethod: paymentMethod) { _ in }
        while !updater.isWaiting {
            await Task.yield()
        }

        // When Apple Pay finishes before the update completes
        context.paymentAuthorizationControllerDidFinish(mockController)
        await Task.yield()

        // Then presentApplePay remains pending until the updater is released
        XCTAssertFalse(didReturnResult)
        updater.resume()
        let result = await resultTask.value
        XCTAssertEqual(result.paymentSheetResult, .canceled)
        XCTAssertEqual(updater.updateCallCount, 2)
        XCTAssertNil(updater.lastAddress)
        XCTAssertNil(updater.currentTaxRegion)
    }

    // MARK: - Authorization

    func testAuthorizationConfirmsWithTokenAndWalletContactDetails() async throws {
        // Given an authorized Apple Pay payment with billing and shipping contacts
        APIStubbedTestCase.stubAllOutgoingRequests()
        stub(condition: isPath("/v1/tokens")) { _ in
            HTTPStubsResponse(jsonObject: self.tokenJSON(), statusCode: 200, headers: nil)
        }
        let payment = STPFixtures.testPKPaymentWithContactDetails()
        let billingAddress = CNMutablePostalAddress()
        billingAddress.street = "123 Main St"
        billingAddress.isoCountryCode = "US"
        payment.billingContact?.postalAddress = billingAddress
        payment.billingContact?.emailAddress = nil
        payment.billingContact?.phoneNumber = nil
        payment.shippingContact?.emailAddress = "wallet@example.com"
        payment.shippingContact?.phoneNumber = CNPhoneNumber(stringValue: "+1 (415) 555-1234")
        let response = try PaymentPagesAPIResponse.decode(fromAPIResponse: makeConfirmResponseJSON())
        let confirmed = expectation(description: "Checkout confirmed with inline Apple Pay data")
        let (context, controller) = makeContext { parameters in
            XCTAssertNil(parameters.paymentMethodId)
            XCTAssertEqual(parameters.paymentMethodData?.card?.token, "tok_apple_pay")
            XCTAssertEqual(parameters.expectedPaymentMethodType, "card")
            XCTAssertEqual(parameters.expectedAmount, 1000)
            XCTAssertEqual(parameters.paymentMethodData?.billingDetails?.name, "Jane Doe")
            XCTAssertEqual(parameters.paymentMethodData?.billingDetails?.address?.line1, "123 Main St")
            XCTAssertEqual(parameters.paymentMethodData?.billingDetails?.email, "wallet@example.com")
            XCTAssertEqual(parameters.paymentMethodData?.billingDetails?.phone, "14155551234")
            XCTAssertEqual(parameters.shipping?.address.line1, "510 Townsend St")
            XCTAssertNotNil(parameters.paymentMethodData?.clientAttributionMetadata)
            XCTAssertNotNil(parameters.clientAttributionMetadata)
            confirmed.fulfill()
            return .completed(response)
        }

        // When Apple Pay authorizes the payment
        let resultTask = Task { await context.presentApplePay() }
        let authorized = expectation(description: "Apple Pay authorization succeeds")
        context.paymentAuthorizationController(controller, didAuthorizePayment: payment) { result in
            XCTAssertEqual(result.status, .success)
            authorized.fulfill()
        }

        // Then confirmation receives the wallet details, and dismissal completes Checkout
        await fulfillment(of: [confirmed, authorized], timeout: 5)
        context.paymentAuthorizationControllerDidFinish(controller)
        let result = await resultTask.value
        XCTAssertEqual(result.paymentSheetResult, .completed)
    }

    func testAuthorizationConfirmsWithPaymentElementSource() async throws {
        try await assertAuthorizationConfirmsWithSource(.paymentElement)
    }

    func testAuthorizationConfirmsWithExpressCheckoutElementSource() async throws {
        try await assertAuthorizationConfirmsWithSource(.expressCheckoutElement)
    }

    private func assertAuthorizationConfirmsWithSource(
        _ confirmationSource: CheckoutController.ConfirmingElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        // Given an Apple Pay confirmation flow built for a specific Checkout Elements component
        APIStubbedTestCase.stubAllOutgoingRequests()
        stub(condition: isPath("/v1/tokens")) { _ in
            HTTPStubsResponse(jsonObject: self.tokenJSON(), statusCode: 200, headers: nil)
        }
        let response = try PaymentPagesAPIResponse.decode(fromAPIResponse: makeConfirmResponseJSON())
        let confirmed = expectation(description: "Checkout confirmed with inline Apple Pay data")
        let (context, controller) = makeContext(attribution: .init(confirmingElement: confirmationSource, configuredElements: [.paymentElement, .expressCheckoutElement])) { parameters in
            // Then the /confirm request parameters are tagged with that same component, so
            // payment_method_data[payment_user_agent] can be built for the right one downstream
            XCTAssertEqual(parameters.confirmationSource, confirmationSource, file: file, line: line)
            for metadata in [parameters.clientAttributionMetadata, parameters.paymentMethodData?.clientAttributionMetadata] {
                XCTAssertEqual(metadata?.merchantIntegrationSource, "mobile-checkout", file: file, line: line)
                XCTAssertEqual(metadata?.merchantIntegrationSubtype, confirmationSource.rawValue, file: file, line: line)
                XCTAssertEqual(metadata?.merchantIntegrationAdditionalElements, ["mobile-payment-element", "mobile-express-checkout-element"], file: file, line: line)
            }
            confirmed.fulfill()
            return .completed(response)
        }

        // When Apple Pay authorizes the payment
        let resultTask = Task { await context.presentApplePay() }
        context.paymentAuthorizationController(controller, didAuthorizePayment: STPFixtures.simulatorApplePayPayment()) { _ in }

        // Then confirmation receives the right confirmationSource, and dismissal completes Checkout
        await fulfillment(of: [confirmed], timeout: 5)
        context.paymentAuthorizationControllerDidFinish(controller)
        let result = await resultTask.value
        XCTAssertEqual(result.paymentSheetResult, .completed, file: file, line: line)
    }

    func testRetryAfterConfirmationFailureUsesNewToken() async throws {
        // Given a confirmation failure followed by a successful retry
        APIStubbedTestCase.stubAllOutgoingRequests()
        var tokenCount = 0
        stub(condition: isPath("/v1/tokens")) { _ in
            tokenCount += 1
            return HTTPStubsResponse(jsonObject: self.tokenJSON(id: "tok_\(tokenCount)"), statusCode: 200, headers: nil)
        }
        let response = try PaymentPagesAPIResponse.decode(fromAPIResponse: makeConfirmResponseJSON())
        var confirmedTokens: [String?] = []
        let (context, controller) = makeContext { parameters in
            confirmedTokens.append(parameters.paymentMethodData?.card?.token)
            if confirmedTokens.count == 1 {
                return .failed(CheckoutError.unknown(debugDescription: "Declined"))
            }
            return .completed(response)
        }
        let firstAuthorization = expectation(description: "First authorization fails")
        context.paymentAuthorizationController(controller, didAuthorizePayment: STPFixtures.simulatorApplePayPayment()) { result in
            XCTAssertEqual(result.status, .failure)
            firstAuthorization.fulfill()
        }
        await fulfillment(of: [firstAuthorization], timeout: 5)

        // When the customer authorizes another payment on the same Apple Pay sheet
        let retry = expectation(description: "Retry succeeds")
        context.paymentAuthorizationController(controller, didAuthorizePayment: STPFixtures.simulatorApplePayPayment()) { result in
            XCTAssertEqual(result.status, .success)
            retry.fulfill()
        }

        // Then the retry uses a newly created token
        await fulfillment(of: [retry], timeout: 5)
        XCTAssertEqual(confirmedTokens, ["tok_1", "tok_2"])
    }

    func testTokenizationFailureDoesNotConfirm() async {
        // Given Apple Pay tokenization fails
        APIStubbedTestCase.stubAllOutgoingRequests()
        stub(condition: isPath("/v1/tokens")) { _ in
            HTTPStubsResponse(jsonObject: ["error": ["type": "card_error", "message": "Declined"]], statusCode: 402, headers: nil)
        }
        let (context, controller) = makeContext { _ in
            XCTFail("Checkout must not confirm when tokenization fails")
            return .canceled()
        }

        // When Apple Pay authorizes the payment
        let resultTask = Task { await context.presentApplePay() }
        let authorized = expectation(description: "Tokenization error reaches Apple Pay")
        context.paymentAuthorizationController(controller, didAuthorizePayment: STPFixtures.simulatorApplePayPayment()) { result in
            XCTAssertEqual(result.status, .failure)
            XCTAssertFalse(result.errors?.isEmpty ?? true)
            authorized.fulfill()
        }

        // Then Apple Pay reports failure, and dismissal returns that failure to Checkout
        await fulfillment(of: [authorized], timeout: 5)
        context.paymentAuthorizationControllerDidFinish(controller)
        guard case .failed = await resultTask.value else {
            return XCTFail("Expected Checkout to return the tokenization failure")
        }
    }

    func testCancelDuringTokenizationDoesNotConfirm() async {
        // Given tokenization is still in flight
        let tokenRequested = expectation(description: "Tokenization started")
        let apiClient = DeferredTokenizationAPIClient()
        apiClient.onTokenization = { tokenRequested.fulfill() }
        let confirmed = expectation(description: "Canceled payment must not confirm")
        confirmed.isInverted = true
        let (context, controller) = makeContext(apiClient: apiClient) { _ in
            confirmed.fulfill()
            return .canceled()
        }
        let resultTask = Task { await context.presentApplePay() }
        context.paymentAuthorizationController(controller, didAuthorizePayment: STPFixtures.simulatorApplePayPayment()) { _ in
            XCTFail("Canceled authorization must not call its completion handler")
        }
        await fulfillment(of: [tokenRequested], timeout: 5)

        // When the customer cancels before tokenization returns
        context.paymentAuthorizationControllerDidFinish(controller)

        // Then Checkout cancels and ignores the returned token
        let result = await resultTask.value
        XCTAssertEqual(result.paymentSheetResult, .canceled)
        apiClient.completeTokenization?(STPToken.decodedObject(fromAPIResponse: tokenJSON()), nil)
        await fulfillment(of: [confirmed], timeout: 0.5)
    }

    // MARK: - Helpers

    private func tokenJSON(id: String = "tok_apple_pay") -> [String: Any] {
        ["id": id, "object": "token", "type": "card", "created": 1234567890, "livemode": false]
    }

    private func makeContext(
        sessionId: String = "cs_test_123",
        apiClient: STPAPIClient? = nil,
        presentationWindow: UIWindow? = nil,
        collectsTaxFromBillingAddress: Bool = false,
        checkoutWalletUpdater: CheckoutSessionWalletUpdater? = nil,
        attribution: CheckoutAttributionContext = .init(confirmingElement: .paymentElement, configuredElements: [.paymentElement]),
        confirmationHandler: @escaping CheckoutController.ApplePayConfirmationParameters.ConfirmationHandler = { _ in
            .failed(CheckoutError.unknown(debugDescription: "Unexpected Apple Pay confirmation in test."))
        }
    ) -> (CheckoutApplePayContext, MockPKPaymentAuthorizationController) {
        let resolvedAPIClient = apiClient ?? APIStubbedTestCase.stubbedAPIClient()
        let response = CheckoutTestHelpers.makeSession([
            "total_summary": ["subtotal": 1000, "total": 1000, "due": 1000],
            "id": sessionId,
            "presentment_currency": "usd",
            "automatic_tax": [
                "enabled": collectsTaxFromBillingAddress,
                "status": "ready",
                "address_source": "billing",
            ],
        ])
        let session = response.makePublicSession()
        let applePayConfirmationParameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: resolvedAPIClient,
            presentationWindow: presentationWindow,
            confirmationHandler: confirmationHandler,
            attribution: attribution
        )
        let mockController = MockPKPaymentAuthorizationController()
        let context = CheckoutApplePayContext(
            checkoutSession: session,
            applePayConfirmationParameters: applePayConfirmationParameters,
            authorizationController: mockController,
            checkoutWalletUpdater: checkoutWalletUpdater ?? MockCheckoutSessionWalletUpdater()
        )
        return (context, mockController)
    }

    private func makeShippingContext(
        allowedCountries: [String],
        automaticTaxAddressSource: String? = nil,
        checkoutWalletUpdater: CheckoutSessionWalletUpdater? = nil
    ) -> (CheckoutApplePayContext, MockPKPaymentAuthorizationController) {
        let apiClient = APIStubbedTestCase.stubbedAPIClient()
        var overrides: [String: Any] = [
            "shipping_address_collection": ["allowed_countries": allowedCountries]
        ]
        if let automaticTaxAddressSource {
            overrides["automatic_tax"] = [
                "enabled": true,
                "status": "ready",
                "address_source": automaticTaxAddressSource,
            ]
        }
        let session = CheckoutTestHelpers.makeSession(overrides).makePublicSession()
        let parameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: apiClient,
        )
        let controller = MockPKPaymentAuthorizationController()
        let context = CheckoutApplePayContext(
            checkoutSession: session,
            applePayConfirmationParameters: parameters,
            authorizationController: controller,
            checkoutWalletUpdater: checkoutWalletUpdater ?? MockCheckoutSessionWalletUpdater(sessionToReturn: session)
        )
        return (context, controller)
    }

    private func makeShippingContact(country: String, postalCode: String? = nil) -> PKContact {
        let address = CNMutablePostalAddress()
        address.isoCountryCode = country
        address.postalCode = postalCode ?? ""
        let contact = PKContact()
        contact.postalAddress = address
        return contact
    }

    private func makeBillingContact() -> CNContact {
        let contact = CNMutableContact()
        let address = CNMutablePostalAddress()
        address.isoCountryCode = "US"
        address.city = "San Francisco"
        address.state = "CA"
        address.postalCode = "94105"
        contact.postalAddresses = [CNLabeledValue(label: CNLabelHome, value: address)]
        return contact
    }

    private func makeConfirmResponseJSON() -> [String: Any] {
        CheckoutTestHelpers.makeSessionJSON([
            "id": "cs_test_123",
            "status": "complete",
            "payment_status": "paid",
            "payment_response": [
                "status": "succeeded",
                "payment_intent": ["id": "pi_test_123", "client_secret": "pi_test_123_secret_abc"],
            ],
        ])
    }

}

private final class MockPKPaymentMethod: PKPaymentMethod {
    private let mockBillingAddress: CNContact?

    init(billingAddress: CNContact?) {
        self.mockBillingAddress = billingAddress
        super.init()
    }

    override var billingAddress: CNContact? { mockBillingAddress }
}

private final class DeferredTokenizationAPIClient: STPAPIClient {
    var onTokenization: (() -> Void)?
    var completeTokenization: STPTokenCompletionBlock?

    override func createToken(with payment: PKPayment, completion: @escaping STPTokenCompletionBlock) {
        completeTokenization = completion
        onTokenization?()
    }
}
