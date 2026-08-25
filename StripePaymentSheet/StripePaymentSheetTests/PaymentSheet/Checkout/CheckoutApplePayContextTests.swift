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
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
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
            "checkout_items": CheckoutTestHelpers.makeOneTimePriceCheckoutItems(unitAmount: 2500),
            "currency": "usd",
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
            "currency": "usd",
            "checkout_items": [
                [
                    "key": "checkout_item_widget",
                    "type": "one_time_price",
                    "one_time_price": [
                        "items": [
                            [
                                "inner_item_key": "widget",
                                "quantity": 1,
                                "subtotal": 2000,
                                "total": 2200,
                                "unit_amount": 2000,
                                "unit_amount_decimal": "2000",
                                "tax_amounts": [],
                                "tax_inclusive": 0,
                                "tax_exclusive": 200,
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
                                "subtotal": 1000,
                                "total": 1000,
                                "unit_amount": 500,
                                "unit_amount_decimal": "500",
                                "tax_amounts": [],
                                "tax_inclusive": 0,
                                "tax_exclusive": 0,
                                "price": ["id": "price_gadget", "currency": "usd", "unit_amount": 500, "product": ["name": "Gadget", "images": []]],
                            ],
                        ],
                        "subtotal": 1000,
                        "total": 1000,
                    ],
                ],
            ],
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

    // MARK: - makePaymentRequest shipping address

    func testMakePaymentRequestRequiresShippingAddress() {
        // Given Express Checkout Element is configured to require a shipping address
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
        XCTAssertEqual(paymentRequest.requiredShippingContactFields, [.name, .postalAddress])
    }

    func testMakePaymentRequestDoesNotRequireShippingAddressByDefault() {
        // Given Express Checkout Element uses its default shipping address configuration
        let session = CheckoutTestHelpers.makeSession().makePublicSession()
        let parameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: APIStubbedTestCase.stubbedAPIClient()
        )

        // When
        let paymentRequest = CheckoutApplePayContext.makePaymentRequest(
            checkoutSession: session,
            applePayConfirmationParameters: parameters
        )
        // Then Apple Pay does not require shipping contact fields
        XCTAssertTrue(paymentRequest.requiredShippingContactFields.isEmpty)
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
        let session = CheckoutTestHelpers.makeSession().makePublicSession().makeCopyOverriding(
            shippingAddress: .newValue(shippingAddress)
        )
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
        // Given a Checkout Session that allows shipping to the US
        let (context, controller) = makeShippingContext(allowedCountries: ["US"])
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
        XCTAssertEqual(error?.domain, PKPaymentErrorDomain)
        XCTAssertEqual(error?.code, PKPaymentError.Code.shippingAddressUnserviceableError.rawValue)
    }
      
    // MARK: - makePaymentRequest billing/shipping contact fields

    func testMakePaymentRequest_defaultConfig_requiresOnlyPostalAddress() {
        // Given a session with the default (automatic) billing details collection configuration
        let session = CheckoutTestHelpers.makeSession([:]).makePublicSession()
        let parameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: APIStubbedTestCase.stubbedAPIClient(),
            billingDetailsCollectionConfiguration: PaymentSheet.BillingDetailsCollectionConfiguration()
        )

        // When building the payment request
        let paymentRequest = CheckoutApplePayContext.makePaymentRequest(checkoutSession: session, applePayConfirmationParameters: parameters)

        // Then it requires the billing postal address (for tax/postal code) but nothing else
        XCTAssertEqual(paymentRequest.requiredBillingContactFields, [.postalAddress])
        XCTAssertTrue(paymentRequest.requiredShippingContactFields.isEmpty)
    }

    func testMakePaymentRequest_addressNever_doesNotRequireBillingAddress() {
        // Given a configuration that never collects the billing address
        let session = CheckoutTestHelpers.makeSession([:]).makePublicSession()
        var billingConfig = PaymentSheet.BillingDetailsCollectionConfiguration()
        billingConfig.address = .never
        let parameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: APIStubbedTestCase.stubbedAPIClient(),
            billingDetailsCollectionConfiguration: billingConfig
        )

        // When building the payment request
        let paymentRequest = CheckoutApplePayContext.makePaymentRequest(checkoutSession: session, applePayConfirmationParameters: parameters)

        // Then the postal address isn't required
        XCTAssertFalse(paymentRequest.requiredBillingContactFields.contains(.postalAddress))
    }

    func testMakePaymentRequest_billingTaxRequiresPostalAddress() {
        // Given automatic tax uses the billing address, even though address collection is .never
        let session = CheckoutTestHelpers.makeSession([
            "tax_context": [
                "automatic_tax_enabled": true,
                "automatic_tax_address_source": "session.billing",
            ],
        ]).makePublicSession()
        var billingConfig = PaymentSheet.BillingDetailsCollectionConfiguration()
        billingConfig.address = .never
        let parameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: APIStubbedTestCase.stubbedAPIClient(),
            billingDetailsCollectionConfiguration: billingConfig
        )

        // When
        let paymentRequest = CheckoutApplePayContext.makePaymentRequest(
            checkoutSession: session,
            applePayConfirmationParameters: parameters
        )

        // Then Apple Pay collects the postal address needed to calculate tax
        XCTAssertTrue(paymentRequest.requiredBillingContactFields.contains(.postalAddress))
    }

    func testMakePaymentRequest_nameAlways_requiresBillingName() {
        // Given a configuration that always collects the billing name
        let session = CheckoutTestHelpers.makeSession([:]).makePublicSession()
        var billingConfig = PaymentSheet.BillingDetailsCollectionConfiguration()
        billingConfig.name = .always
        let parameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: APIStubbedTestCase.stubbedAPIClient(),
            billingDetailsCollectionConfiguration: billingConfig
        )

        // When building the payment request
        let paymentRequest = CheckoutApplePayContext.makePaymentRequest(checkoutSession: session, applePayConfirmationParameters: parameters)

        // Then the billing contact fields include the name, but not email or phone
        XCTAssertTrue(paymentRequest.requiredBillingContactFields.contains(.name))
        XCTAssertFalse(paymentRequest.requiredBillingContactFields.contains(.emailAddress))
        XCTAssertFalse(paymentRequest.requiredBillingContactFields.contains(.phoneNumber))
    }

    func testMakePaymentRequest_emailAndPhoneAlways_requireShippingContactFields() {
        // Given a configuration that always collects email and phone
        let session = CheckoutTestHelpers.makeSession([:]).makePublicSession()
        var billingConfig = PaymentSheet.BillingDetailsCollectionConfiguration()
        billingConfig.email = .always
        billingConfig.phone = .always
        let parameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: APIStubbedTestCase.stubbedAPIClient(),
            billingDetailsCollectionConfiguration: billingConfig
        )

        // When building the payment request
        let paymentRequest = CheckoutApplePayContext.makePaymentRequest(checkoutSession: session, applePayConfirmationParameters: parameters)

        // Then email and phone are required as shipping contact fields, not billing
        XCTAssertTrue(paymentRequest.requiredShippingContactFields.contains(.emailAddress))
        XCTAssertTrue(paymentRequest.requiredShippingContactFields.contains(.phoneNumber))
        XCTAssertFalse(paymentRequest.requiredBillingContactFields.contains(.emailAddress))
        XCTAssertFalse(paymentRequest.requiredBillingContactFields.contains(.phoneNumber))
    }

    func testMakePaymentRequest_ece_defaultConfig_requiresOnlyPostalAddress() {
        // Given a session with the default (automatic) billing details collection configuration
        let session = CheckoutTestHelpers.makeSession([:]).makePublicSession()
        let parameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: APIStubbedTestCase.stubbedAPIClient(),
            billingDetailsCollectionConfiguration: ExpressCheckoutElement.BillingDetailsCollectionConfiguration().paymentSheetConfiguration()
        )

        // When building the payment request
        let paymentRequest = CheckoutApplePayContext.makePaymentRequest(checkoutSession: session, applePayConfirmationParameters: parameters)

        // Then it requires the billing postal address (for tax/postal code) but nothing else
        XCTAssertEqual(paymentRequest.requiredBillingContactFields, [.postalAddress])
        XCTAssertTrue(paymentRequest.requiredShippingContactFields.isEmpty)
    }

    func testMakePaymentRequest_ece_addressAlways_requiresPostalAddress() {
        // Given a configuration that collects the full billing address
        let session = CheckoutTestHelpers.makeSession([:]).makePublicSession()
        var billingConfig = ExpressCheckoutElement.BillingDetailsCollectionConfiguration()
        billingConfig.address = .full
        let parameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: APIStubbedTestCase.stubbedAPIClient(),
            billingDetailsCollectionConfiguration: billingConfig.paymentSheetConfiguration()
        )

        // When building the payment request
        let paymentRequest = CheckoutApplePayContext.makePaymentRequest(checkoutSession: session, applePayConfirmationParameters: parameters)

        // Then the postal address is required
        XCTAssertTrue(paymentRequest.requiredBillingContactFields.contains(.postalAddress))
    }

    func testMakePaymentRequest_ece_nameAlways_requiresBillingName() {
        // Given a configuration that always collects the billing name
        let session = CheckoutTestHelpers.makeSession([:]).makePublicSession()
        var billingConfig = ExpressCheckoutElement.BillingDetailsCollectionConfiguration()
        billingConfig.name = .always
        let parameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: APIStubbedTestCase.stubbedAPIClient(),
            billingDetailsCollectionConfiguration: billingConfig.paymentSheetConfiguration()
        )

        // When building the payment request
        let paymentRequest = CheckoutApplePayContext.makePaymentRequest(checkoutSession: session, applePayConfirmationParameters: parameters)

        // Then the billing contact fields include the name, but not email or phone
        XCTAssertTrue(paymentRequest.requiredBillingContactFields.contains(.name))
        XCTAssertFalse(paymentRequest.requiredBillingContactFields.contains(.emailAddress))
        XCTAssertFalse(paymentRequest.requiredBillingContactFields.contains(.phoneNumber))
    }

    func testMakePaymentRequest_ece_doesNotRequireShippingContactFields() {
        // Given an ECE billing details collection configuration
        let session = CheckoutTestHelpers.makeSession([:]).makePublicSession()
        let parameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: APIStubbedTestCase.stubbedAPIClient(),
            billingDetailsCollectionConfiguration: ExpressCheckoutElement.BillingDetailsCollectionConfiguration().paymentSheetConfiguration()
        )

        // When building the payment request
        let paymentRequest = CheckoutApplePayContext.makePaymentRequest(checkoutSession: session, applePayConfirmationParameters: parameters)

        // Then ECE does not ask Apple Pay to collect contact details as shipping fields
        XCTAssertTrue(paymentRequest.requiredShippingContactFields.isEmpty)
    }

    func testMakePaymentRequest_prefillsCompleteDefaultBillingAddress() {
        // Given default billing details with a street address
        let session = CheckoutTestHelpers.makeSession([:]).makePublicSession()
        var defaults = CheckoutController.Configuration.Defaults.BillingDetails()
        defaults.name = "Jane Doe"
        defaults.address = .init(
            country: "US",
            line1: "510 Townsend St",
            city: "San Francisco",
            state: "CA",
            postalCode: "94103"
        )
        let parameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: APIStubbedTestCase.stubbedAPIClient(),
            billingDetailsCollectionConfiguration: PaymentSheet.BillingDetailsCollectionConfiguration(),
            defaultBillingDetails: defaults
        )

        // When
        let paymentRequest = CheckoutApplePayContext.makePaymentRequest(
            checkoutSession: session,
            applePayConfirmationParameters: parameters
        )

        // Then Apple Pay is prefilled with the default billing contact
        XCTAssertEqual(paymentRequest.billingContact?.postalAddress?.street, "510 Townsend St")
        XCTAssertEqual(paymentRequest.billingContact?.postalAddress?.postalCode, "94103")
        XCTAssertEqual(paymentRequest.billingContact?.name?.givenName, "Jane")
    }

    func testMakeFallbackBillingDetails_attachesDefaultsOnlyWhenConfigured() {
        // Given default billing details and attachment enabled
        let session = CheckoutTestHelpers.makeSession([:]).makePublicSession()
        var defaults = CheckoutController.Configuration.Defaults.BillingDetails()
        defaults.name = "Jane Doe"
        defaults.address = .init(country: "US", line1: "510 Townsend St")
        var billingConfiguration = PaymentSheet.BillingDetailsCollectionConfiguration()
        billingConfiguration.attachDefaultsToPaymentMethod = true
        let parameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: APIStubbedTestCase.stubbedAPIClient(),
            billingDetailsCollectionConfiguration: billingConfiguration,
            defaultBillingDetails: defaults
        )

        // When
        let fallback = CheckoutApplePayContext.makeFallbackBillingDetails(
            checkoutSession: session,
            applePayConfirmationParameters: parameters
        )

        // Then the defaults are attached to PaymentMethod creation
        XCTAssertEqual(fallback?.name, "Jane Doe")
        XCTAssertEqual(fallback?.address?.line1, "510 Townsend St")
        XCTAssertEqual(fallback?.address?.country, "US")
    }

    func testMakeFallbackBillingDetails_doesNotAttachDefaultsByDefault() {
        // Given default billing details with attachment disabled
        let session = CheckoutTestHelpers.makeSession([:]).makePublicSession()
        var defaults = CheckoutController.Configuration.Defaults.BillingDetails()
        defaults.name = "Jane Doe"
        let parameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: APIStubbedTestCase.stubbedAPIClient(),
            billingDetailsCollectionConfiguration: PaymentSheet.BillingDetailsCollectionConfiguration(),
            defaultBillingDetails: defaults
        )

        // When
        let fallback = CheckoutApplePayContext.makeFallbackBillingDetails(
            checkoutSession: session,
            applePayConfirmationParameters: parameters
        )

        // Then defaults are used only for prefill, not attached to the PaymentMethod
        XCTAssertNil(fallback)
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

    // MARK: - paymentAuthorizationControllerDidFinish state machine

    func testDidFinish_notStarted_cancels() async {
        // Given a context in the .notStarted state
        let (context, mockController) = makeContext()

        // When the sheet is dismissed before the user pays
        let resultTask = Task { await context.presentApplePay() }
        await Task.yield()
        context.paymentAuthorizationControllerDidFinish(mockController)

        // Then the result is .canceled
        let result = await resultTask.value
        XCTAssertEqual(result.paymentSheetResult, .canceled)
    }

    func testDidFinish_pending_setsDeferFlag() {
        // Given a context in the .pending state (payment is in-flight)
        let (context, mockController) = makeContext()
        context.paymentState = .pending

        // When the user cancels while pending
        context.paymentAuthorizationControllerDidFinish(mockController)

        // Then it defers the dismiss instead of canceling immediately
        XCTAssertTrue(context.didCancelOrTimeoutWhilePending)
    }

    func testDidFinish_error_returnsError() async {
        // Given a context that finished with an error
        let (context, mockController) = makeContext()
        let error = CheckoutError.unknown(debugDescription: "test error")
        context.paymentState = .error
        context.result = .failed(error)

        // When the sheet is dismissed
        let resultTask = Task { await context.presentApplePay() }
        await Task.yield()
        context.paymentAuthorizationControllerDidFinish(mockController)

        // Then the result is .failed
        let result = await resultTask.value
        if case .failed = result.paymentSheetResult {
            // expected
        } else {
            XCTFail("Expected .failed, got \(result.paymentSheetResult)")
        }
    }

    func testDidFinish_success_returnsSuccess() async {
        // Given a context that finished with success
        let (context, mockController) = makeContext()
        context.paymentState = .success
        context.result = .completed(try! PaymentPagesAPIResponse.decode(fromAPIResponse: makeConfirmResponseJSON()))

        // When the sheet is dismissed
        let resultTask = Task { await context.presentApplePay() }
        await Task.yield()
        context.paymentAuthorizationControllerDidFinish(mockController)

        // Then the result is .completed
        let result = await resultTask.value
        XCTAssertEqual(result.paymentSheetResult, .completed)
    }

    // MARK: - Helpers

    private func makeContext(
        sessionId: String = "cs_test_123",
        apiClient: STPAPIClient? = nil,
        presentationWindow: UIWindow? = nil
    ) -> (CheckoutApplePayContext, MockPKPaymentAuthorizationController) {
        let resolvedAPIClient = apiClient ?? APIStubbedTestCase.stubbedAPIClient()
        let response = CheckoutTestHelpers.makeSession([
            "session_id": sessionId,
            "currency": "usd",
            "total_summary": ["subtotal": 1000, "total": 1000, "due": 1000],
        ])
        let session = response.makePublicSession()
        let applePayConfirmationParameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: resolvedAPIClient,
            billingDetailsCollectionConfiguration: PaymentSheet.BillingDetailsCollectionConfiguration(),
            presentationWindow: presentationWindow
        )
        let mockController = MockPKPaymentAuthorizationController()
        let context = CheckoutApplePayContext(
            checkoutSession: session,
            applePayConfirmationParameters: applePayConfirmationParameters,
            authorizationController: mockController
        )
        return (context, mockController)
    }

    private func makeShippingContext(
        allowedCountries: [String]
    ) -> (CheckoutApplePayContext, MockPKPaymentAuthorizationController) {
        let apiClient = APIStubbedTestCase.stubbedAPIClient()
        let session = CheckoutTestHelpers.makeSession([
            "shipping_address_collection": ["allowed_countries": allowedCountries],
        ]).makePublicSession()
        let parameters = CheckoutController.ApplePayConfirmationParameters.makeMock(apiClient: apiClient)
        let controller = MockPKPaymentAuthorizationController()
        let context = CheckoutApplePayContext(
            checkoutSession: session,
            applePayConfirmationParameters: parameters,
            authorizationController: controller
        )
        return (context, controller)
    }

    private func makeShippingContact(country: String) -> PKContact {
        let address = CNMutablePostalAddress()
        address.isoCountryCode = country
        let contact = PKContact()
        contact.postalAddress = address
        return contact
    }

    private func makeConfirmResponseJSON() -> [String: Any] {
        let paymentIntentJSON: [String: Any] = [
            "id": "pi_test_123",
            "object": "payment_intent",
            "amount": 1000,
            "currency": "usd",
            "status": "succeeded",
            "livemode": false,
            "created": 1234567890,
            "payment_method_types": ["card"],
            "client_secret": "pi_test_123_secret_abc",
        ]
        var json: [String: Any] = [
            "session_id": "cs_test_123",
            "object": "checkout.session",
            "livemode": false,
            "mode": "modeless",
            "currency": "usd",
            "checkout_items": CheckoutTestHelpers.makeOneTimePriceCheckoutItems(),
            "status": "complete",
            "payment_status": "paid",
            "payment_method_types": ["card"],
            "elements_session": CheckoutTestHelpers.minimalElementsSessionJSON,
            "payment_intent": paymentIntentJSON,
        ]
        json["client_secret"] = "cs_test_123_secret_abc"
        return json
    }

}
