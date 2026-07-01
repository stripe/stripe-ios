//
//  CheckoutUnitTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 2/25/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Combine
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

    func testInitSetsLoadedState() async {
        let checkout = await makeCheckoutWithOpenSession()
        XCTAssertFalse(checkout.isLoading)
        XCTAssertEqual(checkout.session.status?.type, .open)
    }

    // MARK: - runServerUpdate Tests

    func testRunServerUpdateWrapsClosureError() async {
        let checkout = await makeCheckoutWithOpenSession()
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

    func testRunServerUpdateWrapsTimeoutError() async {
        let checkout = await makeCheckoutWithOpenSession()

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

    func testRunServerUpdateWrapsGenericError() async {
        let checkout = await makeCheckoutWithOpenSession()

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
        let checkout = await makeCheckoutWithOpenSession()
        let delegate = MockCheckoutDelegate()
        checkout.delegate = delegate

        var sessionEmissions: [Checkout.Session] = []
        let sessionSub = checkout.$session.dropFirst().sink { sessionEmissions.append($0) }
        var loadingEmissions: [Bool] = []
        let loadingSub = checkout.$isLoading.dropFirst().sink { loadingEmissions.append($0) }

        try await checkout.updateBillingAddress(
            name: "Jane Doe",
            address: .init(country: "US", line1: "123 Main St", city: "SF", state: "CA", postalCode: "94105")
        )

        let stored = checkout.session.billingAddress
        XCTAssertEqual(stored?.name, "Jane Doe")
        XCTAssertEqual(stored?.address.country, "US")
        XCTAssertEqual(delegate.updateSessionCallCount, 1)
        XCTAssertEqual(delegate.beginLoadingCallCount, 1)
        XCTAssertEqual(delegate.finishLoadingCallCount, 1)
        XCTAssertEqual(sessionEmissions.count, 1)
        XCTAssertEqual(loadingEmissions, [true, false])

        sessionSub.cancel()
        loadingSub.cancel()
    }

    func testUpdateShippingAddress_noTax_setsLocallyAndNotifiesDelegate() async throws {
        let checkout = await makeCheckoutWithOpenSession()
        let delegate = MockCheckoutDelegate()
        checkout.delegate = delegate

        var sessionEmissions: [Checkout.Session] = []
        let sessionSub = checkout.$session.dropFirst().sink { sessionEmissions.append($0) }
        var loadingEmissions: [Bool] = []
        let loadingSub = checkout.$isLoading.dropFirst().sink { loadingEmissions.append($0) }

        try await checkout.updateShippingAddress(
            name: "John Smith",
            address: .init(country: "US", line1: "456 Oak Ave", city: "LA", state: "CA", postalCode: "90001")
        )

        let stored = checkout.session.shippingAddress
        XCTAssertEqual(stored?.name, "John Smith")
        XCTAssertEqual(stored?.address.country, "US")
        XCTAssertEqual(delegate.updateSessionCallCount, 1)
        XCTAssertEqual(delegate.beginLoadingCallCount, 1)
        XCTAssertEqual(delegate.finishLoadingCallCount, 1)
        XCTAssertEqual(sessionEmissions.count, 1)
        XCTAssertEqual(loadingEmissions, [true, false])

        sessionSub.cancel()
        loadingSub.cancel()
    }

    func testUpdateShippingAddress_disallowedCountry_throws() async throws {
        let session = CheckoutTestHelpers.makeOpenSession(allowedCountries: ["US", "CA"])
        let checkout = await Checkout(clientSecret: "cs_test_123_secret_abc", session: session)

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
        let checkout = await Checkout(clientSecret: "cs_test_123_secret_abc", session: session)

        try await checkout.updateShippingAddress(
            address: .init(country: "CA", line1: "80 Spadina Ave", city: "Toronto", state: "ON", postalCode: "M5V 2J4")
        )

        XCTAssertEqual(checkout.session.shippingAddress?.address.country, "CA")
    }

    // MARK: - Sheet Presented Guard Tests

    func testRequireOpenSessionThrowsWhenSheetPresented() async {
        let checkout = await makeCheckoutWithOpenSession()
        let integrationDelegate = MockCheckoutIntegrationDelegate()
        integrationDelegate.isSheetPresented = true
        checkout.integrationDelegate = integrationDelegate

        do {
            try await checkout.applyPromotionCode("SAVE25")
            XCTFail("Expected CheckoutError.sheetCurrentlyPresented")
        } catch let error as CheckoutError {
            guard case .sheetCurrentlyPresented = error else {
                XCTFail("Expected .sheetCurrentlyPresented, got \(error)")
                return
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Address Collection Decoding Tests

    func testRequiresBillingAddress_whenRequired() {
        var json = CheckoutTestHelpers.makeOpenSessionJSON()
        json["billing_address_collection"] = "required"
        let session = STPCheckoutSession.decodedObject(fromAPIResponse: json)!
        XCTAssertTrue(session.requiresBillingAddress)
    }

    func testRequiresBillingAddress_whenAutoOrNil() {
        // "auto" should not be required
        var jsonAuto = CheckoutTestHelpers.makeOpenSessionJSON()
        jsonAuto["billing_address_collection"] = "auto"
        let sessionAuto = STPCheckoutSession.decodedObject(fromAPIResponse: jsonAuto)!
        XCTAssertFalse(sessionAuto.requiresBillingAddress)

        // absent field should not be required
        let jsonNil = CheckoutTestHelpers.makeOpenSessionJSON()
        let sessionNil = STPCheckoutSession.decodedObject(fromAPIResponse: jsonNil)!
        XCTAssertFalse(sessionNil.requiresBillingAddress)
    }

    func testAllowedShippingCountries_whenPresent() {
        var json = CheckoutTestHelpers.makeOpenSessionJSON()
        json["shipping_address_collection"] = ["allowed_countries": ["US", "CA", "IE", "GB"]]
        let session = STPCheckoutSession.decodedObject(fromAPIResponse: json)!
        XCTAssertEqual(session.allowedShippingCountries, ["US", "CA", "IE", "GB"])
    }

    func testAllowedShippingCountries_whenNil() {
        let json = CheckoutTestHelpers.makeOpenSessionJSON()
        let session = STPCheckoutSession.decodedObject(fromAPIResponse: json)!
        XCTAssertNil(session.allowedShippingCountries)
    }

    // MARK: - Tax Amount Tests

    func testTotalTaxAmount_singleAmount() {
        var json = CheckoutTestHelpers.makeOpenSessionJSON()
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
        let session = STPCheckoutSession.decodedObject(fromAPIResponse: json)!
        XCTAssertEqual(session.totalTaxAmount, 1185)
        XCTAssertEqual(session.taxAmounts.count, 1)
    }

    func testTotalTaxAmount_multipleAmounts() {
        var json = CheckoutTestHelpers.makeOpenSessionJSON()
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
        let session = STPCheckoutSession.decodedObject(fromAPIResponse: json)!
        XCTAssertEqual(session.totalTaxAmount, 700)
        XCTAssertEqual(session.taxAmounts.count, 2)
    }

    func testTotalTaxAmount_noTaxAmounts() {
        let json = CheckoutTestHelpers.makeOpenSessionJSON()
        let session = STPCheckoutSession.decodedObject(fromAPIResponse: json)!
        XCTAssertEqual(session.totalTaxAmount, 0)
        XCTAssertTrue(session.taxAmounts.isEmpty)
    }

    // MARK: - Requires Shipping Address Tests

    func testRequiresShippingAddress_whenCountriesPresent() {
        var json = CheckoutTestHelpers.makeOpenSessionJSON()
        json["shipping_address_collection"] = ["allowed_countries": ["US", "CA"]]
        let session = STPCheckoutSession.decodedObject(fromAPIResponse: json)!
        XCTAssertTrue(session.requiresShippingAddress)
    }

    func testRequiresShippingAddress_whenNil() {
        let json = CheckoutTestHelpers.makeOpenSessionJSON()
        let session = STPCheckoutSession.decodedObject(fromAPIResponse: json)!
        XCTAssertFalse(session.requiresShippingAddress)
    }

    // MARK: - Full Session Decoding with Tax Amounts

    func testFullSessionDecodingWithTaxAmounts() {
        var json = CheckoutTestHelpers.makeOpenSessionJSON()
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

        let session = STPCheckoutSession.decodedObject(fromAPIResponse: json)!

        // Verify tax amounts
        XCTAssertEqual(session.taxAmounts.count, 1)
        XCTAssertEqual(session.totalTaxAmount, 1000)
        XCTAssertEqual(session.taxAmounts.first?.taxRate?.displayName, "Sales Tax")
        XCTAssertEqual(session.taxAmounts.first?.taxRate?.jurisdiction, "NY")
        XCTAssertEqual(session.tax.taxAmounts?.count, 1)
        XCTAssertEqual(session.tax.taxAmounts?.first?.amount.minorUnitsAmount, 1000)
        XCTAssertEqual(session.tax.taxAmounts?.first?.displayName, "Sales Tax")

        // Verify address collection settings
        XCTAssertTrue(session.requiresBillingAddress)
        XCTAssertTrue(session.requiresShippingAddress)
        XCTAssertEqual(session.allowedShippingCountries, ["US", "CA", "GB"])

        // Verify totals
        XCTAssertNotNil(session.total)
        XCTAssertEqual(session.total?.subtotal.minorUnitsAmount, 20000)
        XCTAssertEqual(session.total?.total.minorUnitsAmount, 21000)
        XCTAssertEqual(session.total?.taxExclusive.minorUnitsAmount, 1000)
    }

    // MARK: - commitSession Tests

    func testUpdateSessionNotifiesDelegate() async throws {
        let checkout = await makeCheckoutWithOpenSession()
        let delegate = MockCheckoutDelegate()
        checkout.delegate = delegate

        var sessionEmissions: [Checkout.Session] = []
        let sessionSub = checkout.$session.dropFirst().sink { sessionEmissions.append($0) }

        // Simulate a confirm response with different data
        var updatedJSON = CheckoutTestHelpers.makeOpenSessionJSON()
        updatedJSON["status"] = "complete"
        updatedJSON["payment_status"] = "paid"
        let confirmResponse = STPCheckoutSession.decodedObject(fromAPIResponse: updatedJSON)!

        try await checkout.commitSession(confirmResponse)

        // Verify session was updated with the confirm response data
        XCTAssertEqual(checkout.session.status?.type, .complete)
        XCTAssertEqual(checkout.session.status?.paymentStatus, .paid)
        XCTAssertEqual(delegate.updateSessionCallCount, 1)
        XCTAssertEqual(sessionEmissions.count, 1)

        sessionSub.cancel()
    }

    func testUpdateSessionCarriesOverAddressOverrides() async throws {
        let checkout = await makeCheckoutWithOpenSession()

        // Set address overrides on the initial session
        let billingUpdate = Checkout.ContactAddress(
            name: "Jane Doe",
            address: .init(country: "US")
        )
        checkout.stpSession.billingAddress = billingUpdate

        // Simulate a confirm response
        var updatedJSON = CheckoutTestHelpers.makeOpenSessionJSON()
        updatedJSON["status"] = "complete"
        updatedJSON["payment_status"] = "paid"
        let confirmResponse = STPCheckoutSession.decodedObject(fromAPIResponse: updatedJSON)!

        try await checkout.commitSession(confirmResponse)

        // Address overrides should be carried over to the new session
        XCTAssertEqual(checkout.session.billingAddress?.name, "Jane Doe")
        XCTAssertEqual(checkout.session.billingAddress?.address.country, "US")
    }

    func testUpdateSessionCanBeCalledMultipleTimes() async throws {
        let checkout = await makeCheckoutWithOpenSession()
        let delegate = MockCheckoutDelegate()
        checkout.delegate = delegate

        var sessionEmissions: [Checkout.Session] = []
        let sessionSub = checkout.$session.dropFirst().sink { sessionEmissions.append($0) }

        // Set a billing address that should survive both session swaps
        checkout.stpSession.billingAddress = Checkout.ContactAddress(
            name: "Jane Doe",
            address: .init(country: "US")
        )

        // First update
        var firstResponse = CheckoutTestHelpers.makeOpenSessionJSON()
        firstResponse["status"] = "complete"
        firstResponse["payment_status"] = "paid"
        let firstConfirm = STPCheckoutSession.decodedObject(fromAPIResponse: firstResponse)!

        try await checkout.commitSession(firstConfirm)
        XCTAssertEqual(checkout.session.status?.type, .complete)
        XCTAssertEqual(checkout.session.billingAddress?.name, "Jane Doe")

        // Second update
        var secondResponse = CheckoutTestHelpers.makeOpenSessionJSON()
        secondResponse["status"] = "open"
        let secondSession = STPCheckoutSession.decodedObject(fromAPIResponse: secondResponse)!

        try await checkout.commitSession(secondSession)
        XCTAssertEqual(checkout.session.status?.type, .open)
        XCTAssertEqual(checkout.session.billingAddress?.name, "Jane Doe")
        XCTAssertEqual(delegate.updateSessionCallCount, 2)
        XCTAssertEqual(sessionEmissions.count, 2)

        sessionSub.cancel()
    }

    func testCommitSessionWithTerminalStatusStillNotifiesIntegrationDelegate() async throws {
        let checkout = await makeCheckoutWithOpenSession()
        let integrationDelegate = MockCheckoutIntegrationDelegate()
        checkout.integrationDelegate = integrationDelegate

        var completedJSON = CheckoutTestHelpers.makeOpenSessionJSON()
        completedJSON["status"] = "complete"
        completedJSON["payment_status"] = "paid"
        let completedSession = STPCheckoutSession.decodedObject(fromAPIResponse: completedJSON)!

        try await checkout.commitSession(completedSession)

        XCTAssertEqual(integrationDelegate.checkoutDidUpdateCallCount, 1)
        XCTAssertEqual(checkout.session.status?.type, .complete)
    }

    // MARK: - State Convenience Tests

    func testSessionAvailableAfterInit() async {
        let checkout = await makeCheckoutWithOpenSession()
        XCTAssertEqual(checkout.session.status?.type, .open)
    }

    func testIsLoadingFalseAfterInit() async {
        let checkout = await makeCheckoutWithOpenSession()
        XCTAssertFalse(checkout.isLoading)
    }

    // MARK: - checkoutDidUpdate Tests

    func testCheckoutDidUpdateCalledWhenSessionChanges() async throws {
        let checkout = await makeCheckoutWithOpenSession()
        let integrationDelegate = MockCheckoutIntegrationDelegate()
        checkout.integrationDelegate = integrationDelegate

        var sessionEmissions: [Checkout.Session] = []
        let sessionSub = checkout.$session.dropFirst().sink { sessionEmissions.append($0) }

        var updatedJSON = CheckoutTestHelpers.makeOpenSessionJSON()
        updatedJSON["status"] = "complete"
        updatedJSON["payment_status"] = "paid"
        let updatedSession = STPCheckoutSession.decodedObject(fromAPIResponse: updatedJSON)!

        try await checkout.commitSession(updatedSession)

        XCTAssertEqual(integrationDelegate.checkoutDidUpdateCallCount, 1)
        XCTAssertTrue(integrationDelegate.lastCheckout === checkout)
        XCTAssertEqual(sessionEmissions.count, 1)

        sessionSub.cancel()
    }

    func testCheckoutDidUpdateCalledEvenWhenSessionUnchanged() async throws {
        let checkout = await makeCheckoutWithOpenSession()
        let integrationDelegate = MockCheckoutIntegrationDelegate()
        checkout.integrationDelegate = integrationDelegate

        var sessionEmissions: [Checkout.Session] = []
        let sessionSub = checkout.$session.dropFirst().sink { sessionEmissions.append($0) }

        // Update with same session data — delegates still fire because the caller
        // decided an update occurred (e.g. after an API call).
        let sameSession = STPCheckoutSession.decodedObject(fromAPIResponse: CheckoutTestHelpers.makeOpenSessionJSON())!
        try await checkout.commitSession(sameSession)

        XCTAssertEqual(integrationDelegate.checkoutDidUpdateCallCount, 1)
        XCTAssertEqual(sessionEmissions.count, 1)

        sessionSub.cancel()
    }

    func testCommitSessionNotifiesRegularDelegateThenIntegrationDelegate() async throws {
        let checkout = await makeCheckoutWithOpenSession()
        var callOrder: [String] = []

        let integrationDelegate = MockCheckoutIntegrationDelegate()
        integrationDelegate.onUpdate = { callOrder.append("integration") }
        checkout.integrationDelegate = integrationDelegate

        let delegate = MockCheckoutDelegate()
        delegate.onUpdateSession = { callOrder.append("regular") }
        checkout.delegate = delegate

        var sessionEmissions: [Checkout.Session] = []
        let sessionSub = checkout.$session.dropFirst().sink { sessionEmissions.append($0) }

        var updatedJSON = CheckoutTestHelpers.makeOpenSessionJSON()
        updatedJSON["status"] = "complete"
        updatedJSON["payment_status"] = "paid"
        let updatedSession = STPCheckoutSession.decodedObject(fromAPIResponse: updatedJSON)!

        try await checkout.commitSession(updatedSession)

        XCTAssertEqual(callOrder, ["regular", "integration"])
        XCTAssertEqual(integrationDelegate.checkoutDidUpdateCallCount, 1)
        XCTAssertEqual(delegate.updateSessionCallCount, 1)
        XCTAssertEqual(sessionEmissions.count, 1)

        sessionSub.cancel()
    }

    func testCheckoutDidUpdateErrorBubblesUp() async {
        let checkout = await makeCheckoutWithOpenSession()
        let integrationDelegate = MockCheckoutIntegrationDelegate()
        let testError = NSError(domain: "test", code: 42)
        integrationDelegate.shouldThrow = testError
        checkout.integrationDelegate = integrationDelegate

        var updatedJSON = CheckoutTestHelpers.makeOpenSessionJSON()
        updatedJSON["status"] = "complete"
        updatedJSON["payment_status"] = "paid"
        let updatedSession = STPCheckoutSession.decodedObject(fromAPIResponse: updatedJSON)!

        do {
            try await checkout.commitSession(updatedSession)
            XCTFail("Expected error to propagate")
        } catch {
            XCTAssertEqual((error as NSError).code, 42)
        }
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

    // MARK: - Helpers

    private func makeCheckoutWithOpenSession() async -> Checkout {
        let session = CheckoutTestHelpers.makeOpenSession()
        return await Checkout(clientSecret: "cs_test_123_secret_abc", session: session)
    }

}

// MARK: - Mock Delegate

@MainActor
private class MockCheckoutDelegate: CheckoutDelegate {
    var lastSession: Checkout.Session?
    var updateSessionCallCount = 0
    var beginLoadingCallCount = 0
    var finishLoadingCallCount = 0
    var onUpdateSession: (() -> Void)?

    func checkoutDidBeginLoading(_ checkout: Checkout) {
        beginLoadingCallCount += 1
    }

    func checkoutDidFinishLoading(_ checkout: Checkout) {
        finishLoadingCallCount += 1
    }

    func checkoutDidUpdateSession(_ checkout: Checkout, session: Checkout.Session) {
        updateSessionCallCount += 1
        lastSession = session
        onUpdateSession?()
    }
}

@MainActor
private class MockCheckoutIntegrationDelegate: CheckoutIntegrationDelegate {
    var isSheetPresented: Bool = false
    var checkoutDidUpdateCallCount = 0
    var lastCheckout: Checkout?
    var shouldThrow: Error?
    var onUpdate: (() -> Void)?

    func checkoutDidUpdate(_ checkout: Checkout) async throws {
        checkoutDidUpdateCallCount += 1
        lastCheckout = checkout
        onUpdate?()
        if let error = shouldThrow { throw error }
    }
}
