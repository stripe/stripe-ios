//
//  CheckoutUnitTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 2/25/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import OHHTTPStubs
import OHHTTPStubsSwift
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import XCTest

@MainActor
final class CheckoutUnitTests: XCTestCase {

    func testExtractSessionId() {
        XCTAssertEqual(
            Checkout.extractSessionId(from: "cs_test_abc123_secret_xyz789"),
            "cs_test_abc123"
        )
        XCTAssertEqual(
            Checkout.extractSessionId(from: "cs_live_def456_secret_uvw012"),
            "cs_live_def456"
        )
        // No _secret_ separator returns original
        XCTAssertEqual(
            Checkout.extractSessionId(from: "cs_test_nosecret"),
            "cs_test_nosecret"
        )
    }

    func testInitSetsLoadedState() async throws {
        let checkout = try await Checkout(configuration: CheckoutTestHelpers.makeConfiguration())
        XCTAssertFalse(checkout.isLoading)
        XCTAssertEqual(checkout.session.status?.type, .open)
    }

    func testSessionPaymentOptionUpdatesAndClears() async throws {
        // Given a Checkout with a PaymentElement and valid card payment option
        let checkout = try await Checkout(configuration: CheckoutTestHelpers.makeConfiguration())
        let paymentElement = checkout.getPaymentElement()
        let confirmParams = IntentConfirmParams(type: .stripe(.card))
        confirmParams.paymentMethodParams.card = STPPaymentMethodCardParams()
        confirmParams.paymentMethodParams.card?.number = "4242424242424242"
        confirmParams.paymentMethodParams.card?.expMonth = NSNumber(value: 12)
        confirmParams.paymentMethodParams.card?.expYear = NSNumber(value: 2040)
        confirmParams.paymentMethodParams.card?.cvc = "123"
        confirmParams.setDefaultBillingDetailsIfNecessary(for: paymentElement.embeddedPaymentElement.configuration)

        // When the embedded PaymentElement reports the selected payment option
        paymentElement.embeddedPaymentElement._test_paymentOption = .new(confirmParams: confirmParams)
        paymentElement.embeddedPaymentElementDidUpdatePaymentOption(
            embeddedPaymentElement: paymentElement.embeddedPaymentElement
        )

        // Then the Checkout session mirrors the selected payment option
        XCTAssertEqual(checkout.session.paymentOption?.paymentMethodType, "card")
        XCTAssertEqual(checkout.session.paymentOption?.label, "•••• 4242")

        // When the Checkout payment option is cleared
        checkout.clearPaymentOption()

        // Then the Checkout session payment option is cleared
        XCTAssertNil(checkout.session.paymentOption)
    }

    // MARK: - runServerUpdate Tests

    func testRunServerUpdateWrapsClosureError() async throws {
        let checkout = try await Checkout(configuration: CheckoutTestHelpers.makeConfiguration())
        let expectedMessage = "Server returned 500"

        do {
            try await checkout.runServerUpdate {
                throw NSError(domain: "test", code: 500, userInfo: [NSLocalizedDescriptionKey: expectedMessage])
            }
            XCTFail("Expected CheckoutError.apiError")
        } catch let error as CheckoutError {
            guard case .apiError(let message) = error else {
                XCTFail("Expected .apiError, got \(error)")
                return
            }
            XCTAssertEqual(message, expectedMessage)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testRunServerUpdateWrapsTimeoutError() async throws {
        let checkout = try await Checkout(configuration: CheckoutTestHelpers.makeConfiguration())

        do {
            try await checkout.runServerUpdate {
                throw TimeoutError()
            }
            XCTFail("Expected CheckoutError.timedOut")
        } catch let error as CheckoutError {
            guard case .timedOut = error else {
                XCTFail("Expected .timedOut, got \(error)")
                return
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testRunServerUpdateWrapsGenericError() async throws {
        let checkout = try await Checkout(configuration: CheckoutTestHelpers.makeConfiguration())

        do {
            try await checkout.runServerUpdate {
                throw URLError(.notConnectedToInternet)
            }
            XCTFail("Expected CheckoutError.apiError")
        } catch let error as CheckoutError {
            guard case .apiError(let message) = error else {
                XCTFail("Expected .apiError, got \(error)")
                return
            }
            XCTAssertEqual(message, URLError(.notConnectedToInternet).localizedDescription)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

// MARK: - Address Override Tests

    func testUpdateBillingAddress_noTax_setsLocallyAndNotifiesDelegate() async throws {
        let checkout = try await Checkout(configuration: CheckoutTestHelpers.makeConfiguration())
        let delegate = MockCheckoutDelegate()
        checkout.delegate = delegate
        let recorder = CheckoutEmissionRecorder(checkout)

        try await checkout.updateBillingAddress(
            name: "Jane Doe",
            address: .init(country: "US", line1: "123 Main St", city: "SF", state: "CA", postalCode: "94105")
        )

        let stored = checkout.session.billingAddress
        XCTAssertEqual(stored?.name, "Jane Doe")
        XCTAssertEqual(stored?.address.country, "US")
        XCTAssertEqual(delegate.updateSessionCallCount, 2)
        XCTAssertEqual(delegate.beginLoadingCallCount, 1)
        XCTAssertEqual(delegate.finishLoadingCallCount, 1)
        XCTAssertEqual(recorder.sessions.count, 2)
        XCTAssertEqual(recorder.loading, [true, false])
    }

    func testUpdateShippingAddress_noTax_setsLocallyAndNotifiesDelegate() async throws {
        let checkout = try await Checkout(configuration: CheckoutTestHelpers.makeConfiguration())
        let delegate = MockCheckoutDelegate()
        checkout.delegate = delegate
        let recorder = CheckoutEmissionRecorder(checkout)

        try await checkout.updateShippingAddress(
            name: "John Smith",
            address: .init(country: "US", line1: "456 Oak Ave", city: "LA", state: "CA", postalCode: "90001")
        )

        let stored = checkout.session.shippingAddress
        XCTAssertEqual(stored?.name, "John Smith")
        XCTAssertEqual(stored?.address.country, "US")
        XCTAssertEqual(delegate.updateSessionCallCount, 2)
        XCTAssertEqual(delegate.beginLoadingCallCount, 1)
        XCTAssertEqual(delegate.finishLoadingCallCount, 1)
        XCTAssertEqual(recorder.sessions.count, 2)
        XCTAssertEqual(recorder.loading, [true, false])
    }

    func testUpdateShippingAddress_disallowedCountry_throws() async throws {
        let session = CheckoutTestHelpers.makeOpenSession(allowedCountries: ["US", "CA"])
        let checkout = try await Checkout(configuration: CheckoutTestHelpers.makeConfiguration(apiResponse: session))

        do {
            try await checkout.updateShippingAddress(
                address: .init(country: "DE")
            )
            XCTFail("Expected invalidShippingCountry error")
        } catch let error as CheckoutError {
            guard case .invalidShippingCountry("DE") = error else {
                XCTFail("Wrong error case: \(error)")
                return
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testUpdateShippingAddress_allowedCountry_succeeds() async throws {
        let session = CheckoutTestHelpers.makeOpenSession(allowedCountries: ["US", "CA", "GB"])
        let checkout = try await Checkout(configuration: CheckoutTestHelpers.makeConfiguration(apiResponse: session))

        try await checkout.updateShippingAddress(
            address: .init(country: "CA", line1: "80 Spadina Ave", city: "Toronto", state: "ON", postalCode: "M5V 2J4")
        )

        XCTAssertEqual(checkout.session.shippingAddress?.address.country, "CA")
    }

    func testUpdateShippingAddress_taxUpdateFailurePreservesPreviousAddress() async throws {
        // Given a Checkout Session using shipping address for automatic tax calculation
        var json = CheckoutTestHelpers.openSessionJSON
        json["tax_context"] = [
            "automatic_tax_enabled": true,
            "automatic_tax_address_source": "session.shipping",
        ]
        let session = PaymentPagesAPIResponse.decodedObject(fromAPIResponse: json)!
        let checkout = try await Checkout(configuration: CheckoutTestHelpers.makeConfiguration(apiResponse: session))

        // ...and a previously stored local shipping address
        let previousAddress = Checkout.ContactAddress(
            name: "Jane Doe",
            address: .init(
                country: "US",
                line1: "123 Main St",
                city: "San Francisco",
                state: "CA",
                postalCode: "94105"
            )
        )
        checkout.dangerouslySetSessionDirectly(
            checkout.session.makeCopyOverriding(shippingAddress: .newValue(previousAddress))
        )

        // ...and the server tax update fails
        stub(condition: { request in
            request.httpMethod == "POST"
                && request.url?.path == "/v1/payment_pages/cs_test_123"
        }) { _ in
            HTTPStubsResponse(
                jsonObject: [
                    "error": [
                        "type": "invalid_request_error",
                        "message": "Tax update failed",
                    ],
                ],
                statusCode: 500,
                headers: nil
            )
        }

        // When the customer updates their shipping address
        do {
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
            XCTFail("Expected CheckoutError.apiError")
        } catch let error as CheckoutError {
            guard case .apiError = error else {
                XCTFail("Expected .apiError, got \(error)")
                return
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        // Then the previous local shipping address is preserved
        XCTAssertEqual(checkout.session.shippingAddress, previousAddress)
    }

    // MARK: - Address Collection Decoding Tests

    func testRequiresBillingAddress_whenRequired() {
        var json = CheckoutTestHelpers.openSessionJSON
        json["billing_address_collection"] = "required"
        let session = PaymentPagesAPIResponse.decodedObject(fromAPIResponse: json)!
        XCTAssertTrue(session.requiresBillingAddress)
    }

    func testRequiresBillingAddress_whenAutoOrNil() {
        // "auto" should not be required
        var jsonAuto = CheckoutTestHelpers.openSessionJSON
        jsonAuto["billing_address_collection"] = "auto"
        let sessionAuto = PaymentPagesAPIResponse.decodedObject(fromAPIResponse: jsonAuto)!
        XCTAssertFalse(sessionAuto.requiresBillingAddress)

        // absent field should not be required
        let jsonNil = CheckoutTestHelpers.openSessionJSON
        let sessionNil = PaymentPagesAPIResponse.decodedObject(fromAPIResponse: jsonNil)!
        XCTAssertFalse(sessionNil.requiresBillingAddress)
    }

    func testAllowedShippingCountries_whenPresent() {
        var json = CheckoutTestHelpers.openSessionJSON
        json["shipping_address_collection"] = ["allowed_countries": ["US", "CA", "IE", "GB"]]
        let session = PaymentPagesAPIResponse.decodedObject(fromAPIResponse: json)!
        XCTAssertEqual(session.allowedShippingCountries, ["US", "CA", "IE", "GB"])
    }

    func testAllowedShippingCountries_whenNil() {
        let json = CheckoutTestHelpers.openSessionJSON
        let session = PaymentPagesAPIResponse.decodedObject(fromAPIResponse: json)!
        XCTAssertNil(session.allowedShippingCountries)
    }

    // MARK: - Tax Amount Tests

    func testTotalTaxExclusive_singleAmount() {
        var json = CheckoutTestHelpers.openSessionJSON
        json["line_item_group"] = [
            "tax_amounts": [
                [
                    "amount": 1185,
                    "inclusive": false,
                    "taxable_amount": 12000,
                    "tax_rate": [
                        "display_name": "Sales Tax",
                        "percentage": 9.875,
                        "jurisdiction": "UT",
                    ],
                ],
            ],
        ]
        json["total_summary"] = [
            "subtotal": 12000,
            "total": 13185,
        ]
        let session = PaymentPagesAPIResponse.decodedObject(fromAPIResponse: json)!
        XCTAssertEqual(session.makePublicSession().total?.taxExclusive.minorUnitsAmount, 1185)
        XCTAssertEqual(session.tax.taxAmounts?.count, 1)
    }

    func testTotalTaxExclusive_multipleAmounts() {
        var json = CheckoutTestHelpers.openSessionJSON
        json["line_item_group"] = [
            "tax_amounts": [
                [
                    "amount": 500,
                    "inclusive": false,
                    "taxable_amount": 10000,
                    "tax_rate": [
                        "display_name": "State Tax",
                        "percentage": 5.0,
                        "jurisdiction": "CA",
                    ],
                ],
                [
                    "amount": 200,
                    "inclusive": false,
                    "taxable_amount": 10000,
                    "tax_rate": [
                        "display_name": "County Tax",
                        "percentage": 2.0,
                        "jurisdiction": "LA County",
                    ],
                ],
            ],
        ]
        json["total_summary"] = [
            "subtotal": 10000,
            "total": 10700,
        ]
        let session = PaymentPagesAPIResponse.decodedObject(fromAPIResponse: json)!
        XCTAssertEqual(session.makePublicSession().total?.taxExclusive.minorUnitsAmount, 700)
        XCTAssertEqual(session.tax.taxAmounts?.count, 2)
    }

    func testTotalTaxExclusive_noTaxAmounts() {
        var json = CheckoutTestHelpers.openSessionJSON
        json["total_summary"] = [
            "subtotal": 10000,
            "total": 10000,
        ]
        let session = PaymentPagesAPIResponse.decodedObject(fromAPIResponse: json)!
        XCTAssertEqual(session.makePublicSession().total?.taxExclusive.minorUnitsAmount, 0)
        XCTAssertNil(session.tax.taxAmounts)
    }

    // MARK: - Requires Shipping Address Tests

    func testRequiresShippingAddress_whenCountriesPresent() {
        var json = CheckoutTestHelpers.openSessionJSON
        json["shipping_address_collection"] = ["allowed_countries": ["US", "CA"]]
        let session = PaymentPagesAPIResponse.decodedObject(fromAPIResponse: json)!
        XCTAssertTrue(session.makePublicSession().requiresShippingAddress)
    }

    func testRequiresShippingAddress_whenNil() {
        let json = CheckoutTestHelpers.openSessionJSON
        let session = PaymentPagesAPIResponse.decodedObject(fromAPIResponse: json)!
        XCTAssertFalse(session.makePublicSession().requiresShippingAddress)
    }

    // MARK: - Full Session Decoding with Tax Amounts

    func testFullSessionDecodingWithTaxAmounts() {
        var json = CheckoutTestHelpers.openSessionJSON
        json["billing_address_collection"] = "required"
        json["shipping_address_collection"] = ["allowed_countries": ["US", "CA", "GB"]]
        json["line_item_group"] = [
            "tax_amounts": [
                [
                    "amount": 1000,
                    "inclusive": false,
                    "taxable_amount": 20000,
                    "tax_rate": [
                        "display_name": "Sales Tax",
                        "percentage": 5.0,
                        "jurisdiction": "NY",
                    ],
                ],
            ],
        ]
        json["total_summary"] = [
            "due": 21000,
            "subtotal": 20000,
            "total": 21000,
        ]

        let session = PaymentPagesAPIResponse.decodedObject(fromAPIResponse: json)!

        // Verify tax amounts
        XCTAssertEqual(session.tax.taxAmounts?.count, 1)
        XCTAssertEqual(session.tax.taxAmounts?.first?.amount.minorUnitsAmount, 1000)
        XCTAssertEqual(session.tax.taxAmounts?.first?.displayName, "Sales Tax")

        // Verify address collection settings
        XCTAssertTrue(session.requiresBillingAddress)
        XCTAssertTrue(session.makePublicSession().requiresShippingAddress)
        XCTAssertEqual(session.allowedShippingCountries, ["US", "CA", "GB"])

        // Verify totals
        XCTAssertNotNil(session.total)
        XCTAssertEqual(session.total?.subtotal.minorUnitsAmount, 20000)
        XCTAssertEqual(session.total?.total.minorUnitsAmount, 21000)
        XCTAssertEqual(session.makePublicSession().total?.taxExclusive.minorUnitsAmount, 1000)
    }

    // MARK: - commitSession Tests

    func testUpdateSessionNotifiesDelegate() async throws {
        // Given a Checkout with a delegate and session recorder
        let checkout = try await Checkout(configuration: CheckoutTestHelpers.makeConfiguration())
        let delegate = MockCheckoutDelegate()
        checkout.delegate = delegate
        let recorder = CheckoutEmissionRecorder(checkout)

        var updatedJSON = CheckoutTestHelpers.openSessionJSON
        updatedJSON["status"] = "complete"
        updatedJSON["payment_status"] = "paid"
        let confirmResponse = PaymentPagesAPIResponse.decodedObject(fromAPIResponse: updatedJSON)!

        // When the confirmed session is committed
        try await checkout.commitSession(confirmResponse)

        // Then Checkout updates the session and notifies observers
        XCTAssertEqual(checkout.session.status?.type, .complete)
        XCTAssertEqual(checkout.session.status?.paymentStatus, .paid)
        // There are two emissions: one for the committed session, one for PaymentElement re-syncing the payment option.
        XCTAssertEqual(delegate.updateSessionCallCount, 2)
        XCTAssertEqual(recorder.sessions.count, 2)
    }

    func testUpdateSessionCarriesOverAddressOverrides() async throws {
        let checkout = try await Checkout(configuration: CheckoutTestHelpers.makeConfiguration())

        // Set address overrides on the initial session
        let billingUpdate = Checkout.ContactAddress(
            name: "Jane Doe",
            address: .init(country: "US")
        )
        checkout.dangerouslySetSessionDirectly(checkout.session.makeCopyOverriding(billingAddress: .newValue(billingUpdate)))

        // Simulate a confirm response
        var updatedJSON = CheckoutTestHelpers.openSessionJSON
        updatedJSON["status"] = "complete"
        updatedJSON["payment_status"] = "paid"
        let confirmResponse = PaymentPagesAPIResponse.decodedObject(fromAPIResponse: updatedJSON)!

        try await checkout.commitSession(confirmResponse)

        // Address overrides should be carried over to the new session
        XCTAssertEqual(checkout.session.billingAddress?.name, "Jane Doe")
        XCTAssertEqual(checkout.session.billingAddress?.address.country, "US")
    }

    func testUpdateSessionCanBeCalledMultipleTimes() async throws {
        // Initialize with billing address already set so it doesn't emit a change
        let checkout = try await Checkout(configuration: CheckoutTestHelpers.makeConfiguration())
        checkout.dangerouslySetSessionDirectly(
            checkout.session.makeCopyOverriding(
                billingAddress: .newValue(
                    Checkout.ContactAddress(
                        name: "Jane Doe",
                        address: .init(country: "US")
                    )
                )
            )
        )
        let delegate = MockCheckoutDelegate()
        checkout.delegate = delegate
        let recorder = CheckoutEmissionRecorder(checkout)

        var firstResponse = CheckoutTestHelpers.openSessionJSON
        firstResponse["status"] = "complete"
        firstResponse["payment_status"] = "paid"
        let firstConfirm = PaymentPagesAPIResponse.decodedObject(fromAPIResponse: firstResponse)!

        try await checkout.commitSession(firstConfirm)
        XCTAssertEqual(checkout.session.status?.type, .complete)
        XCTAssertEqual(checkout.session.billingAddress?.name, "Jane Doe")

        var secondResponse = CheckoutTestHelpers.openSessionJSON
        secondResponse["status"] = "open"
        let secondSession = PaymentPagesAPIResponse.decodedObject(fromAPIResponse: secondResponse)!

        try await checkout.commitSession(secondSession)
        XCTAssertEqual(checkout.session.status?.type, .open)
        XCTAssertEqual(checkout.session.billingAddress?.name, "Jane Doe")
        XCTAssertEqual(delegate.updateSessionCallCount, 4)
        XCTAssertEqual(recorder.sessions.count, 4)
    }

    // MARK: - State Convenience Tests

    func testSessionAvailableAfterInit() async throws {
        let checkout = try await Checkout(configuration: CheckoutTestHelpers.makeConfiguration())
        XCTAssertEqual(checkout.session.status?.type, .open)
    }

    func testIsLoadingFalseAfterInit() async throws {
        let checkout = try await Checkout(configuration: CheckoutTestHelpers.makeConfiguration())
        XCTAssertFalse(checkout.isLoading)
    }

    func testCommitSessionNotifiesRegularDelegate() async throws {
        // Given a Checkout with a regular delegate
        let checkout = try await Checkout(configuration: CheckoutTestHelpers.makeConfiguration())
        var callOrder: [String] = []

        let delegate = MockCheckoutDelegate()
        delegate.onUpdateSession = { callOrder.append("regular") }
        checkout.delegate = delegate
        let recorder = CheckoutEmissionRecorder(checkout)

        var updatedJSON = CheckoutTestHelpers.openSessionJSON
        updatedJSON["status"] = "complete"
        updatedJSON["payment_status"] = "paid"
        let updatedSession = PaymentPagesAPIResponse.decodedObject(fromAPIResponse: updatedJSON)!

        // When the updated session is committed
        try await checkout.commitSession(updatedSession)

        // Then the delegate is notified for both session emissions
        XCTAssertEqual(callOrder, ["regular", "regular"])
        // There are two emissions: one for the committed session, one for PaymentElement re-syncing the payment option.
        XCTAssertEqual(delegate.updateSessionCallCount, 2)
        XCTAssertEqual(recorder.sessions.count, 2)
    }
    // MARK: - updatePaymentMethod Parameter Encoding Tests

    func testUpdatePaymentMethodParameters_expiryOnly() {
        let params = STPAPIClient.updatePaymentMethodParameters(
            paymentMethodId: "pm_123",
            billingDetails: nil,
            expiryDetails: Checkout.PaymentMethodExpiryDetails(expMonth: 12, expYear: 2028)
        )

        XCTAssertEqual(params["payment_method_to_update[payment_method_id]"] as? String, "pm_123")
        XCTAssertEqual(params["payment_method_to_update[expiry_details][exp_month]"] as? Int, 12)
        XCTAssertEqual(params["payment_method_to_update[expiry_details][exp_year]"] as? Int, 2028)
        XCTAssertNil(params["payment_method_to_update[billing_details][name]"])
        XCTAssertEqual(params.count, 3)
    }

    func testUpdatePaymentMethodParameters_billingDetailsOnly() {
        let billing = Checkout.PaymentMethodBillingDetails(
            name: "Jane Doe",
            email: "jane@example.com",
            phone: "+15551234567",
            address: Checkout.PaymentMethodBillingAddress(
                line1: "123 Main St",
                line2: "Apt 4",
                city: "San Francisco",
                state: "CA",
                postalCode: "94105",
                country: "US"
            )
        )
        let params = STPAPIClient.updatePaymentMethodParameters(
            paymentMethodId: "pm_456",
            billingDetails: billing,
            expiryDetails: nil
        )

        XCTAssertEqual(params["payment_method_to_update[payment_method_id]"] as? String, "pm_456")
        XCTAssertEqual(params["payment_method_to_update[billing_details][name]"] as? String, "Jane Doe")
        XCTAssertEqual(params["payment_method_to_update[billing_details][email]"] as? String, "jane@example.com")
        XCTAssertEqual(params["payment_method_to_update[billing_details][phone]"] as? String, "+15551234567")
        XCTAssertEqual(params["payment_method_to_update[billing_details][address][line1]"] as? String, "123 Main St")
        XCTAssertEqual(params["payment_method_to_update[billing_details][address][line2]"] as? String, "Apt 4")
        XCTAssertEqual(params["payment_method_to_update[billing_details][address][city]"] as? String, "San Francisco")
        XCTAssertEqual(params["payment_method_to_update[billing_details][address][state]"] as? String, "CA")
        XCTAssertEqual(params["payment_method_to_update[billing_details][address][postal_code]"] as? String, "94105")
        XCTAssertEqual(params["payment_method_to_update[billing_details][address][country]"] as? String, "US")
        XCTAssertNil(params["payment_method_to_update[expiry_details][exp_month]"])
        XCTAssertEqual(params.count, 10)
    }

    func testUpdatePaymentMethodParameters_billingAndExpiry() {
        let billing = Checkout.PaymentMethodBillingDetails(
            name: "John Smith",
            address: nil
        )
        let expiry = Checkout.PaymentMethodExpiryDetails(expMonth: 3, expYear: 2026)
        let params = STPAPIClient.updatePaymentMethodParameters(
            paymentMethodId: "pm_789",
            billingDetails: billing,
            expiryDetails: expiry
        )

        XCTAssertEqual(params["payment_method_to_update[payment_method_id]"] as? String, "pm_789")
        XCTAssertEqual(params["payment_method_to_update[billing_details][name]"] as? String, "John Smith")
        XCTAssertEqual(params["payment_method_to_update[expiry_details][exp_month]"] as? Int, 3)
        XCTAssertEqual(params["payment_method_to_update[expiry_details][exp_year]"] as? Int, 2026)
        XCTAssertNil(params["payment_method_to_update[billing_details][email]"])
        XCTAssertNil(params["payment_method_to_update[billing_details][address][line1]"])
        XCTAssertEqual(params.count, 4)
    }

    func testUpdatePaymentMethodParameters_partialBillingAddress() {
        let billing = Checkout.PaymentMethodBillingDetails(
            address: Checkout.PaymentMethodBillingAddress(
                postalCode: "94105",
                country: "US"
            )
        )
        let params = STPAPIClient.updatePaymentMethodParameters(
            paymentMethodId: "pm_abc",
            billingDetails: billing,
            expiryDetails: nil
        )

        XCTAssertEqual(params["payment_method_to_update[payment_method_id]"] as? String, "pm_abc")
        XCTAssertEqual(params["payment_method_to_update[billing_details][address][postal_code]"] as? String, "94105")
        XCTAssertEqual(params["payment_method_to_update[billing_details][address][country]"] as? String, "US")
        XCTAssertNil(params["payment_method_to_update[billing_details][name]"])
        XCTAssertNil(params["payment_method_to_update[billing_details][address][line1]"])
        XCTAssertNil(params["payment_method_to_update[billing_details][address][city]"])
        XCTAssertEqual(params.count, 3)
    }

}
