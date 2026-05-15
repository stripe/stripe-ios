//
//  CheckoutUnitTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 2/25/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

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
        guard case .loaded = checkout.state else {
            XCTFail("Expected .loaded state after init with session")
            return
        }
        XCTAssertEqual(checkout.state.session.status?.type, .open)
        XCTAssertFalse(checkout.state.isLoading)
    }

    // MARK: - Requires Open Session Tests

    func testApplyPromotionCodeRequiresOpenSession() async throws {
        let checkout = await makeCheckoutWithClosedSession()

        do {
            try await checkout.applyPromotionCode("SAVE25")
            XCTFail("Expected CheckoutError.sessionNotOpen")
        } catch let error as CheckoutError {
            guard case .sessionNotOpen = error else {
                XCTFail("Expected .sessionNotOpen, got \(error)")
                return
            }
        }
    }

    func testRemovePromotionCodeRequiresOpenSession() async throws {
        let checkout = await makeCheckoutWithClosedSession()

        do {
            try await checkout.removePromotionCode()
            XCTFail("Expected CheckoutError.sessionNotOpen")
        } catch let error as CheckoutError {
            guard case .sessionNotOpen = error else {
                XCTFail("Expected .sessionNotOpen, got \(error)")
                return
            }
        }
    }

    func testUpdateQuantityRequiresOpenSession() async throws {
        let checkout = await makeCheckoutWithClosedSession()

        do {
            try await checkout.updateQuantity(lineItemId: "li_123", quantity: 2)
            XCTFail("Expected CheckoutError.sessionNotOpen")
        } catch let error as CheckoutError {
            guard case .sessionNotOpen = error else {
                XCTFail("Expected .sessionNotOpen, got \(error)")
                return
            }
        }
    }

    func testSelectShippingOptionRequiresOpenSession() async throws {
        let checkout = await makeCheckoutWithClosedSession()

        do {
            try await checkout.selectShippingOption("shr_123")
            XCTFail("Expected CheckoutError.sessionNotOpen")
        } catch let error as CheckoutError {
            guard case .sessionNotOpen = error else {
                XCTFail("Expected .sessionNotOpen, got \(error)")
                return
            }
        }
    }

    func testUpdateBillingAddressRequiresOpenSession() async throws {
        let checkout = await makeCheckoutWithClosedSession()

        do {
            try await checkout.updateBillingAddress(
                name: "Jane Doe",
                address: .init(country: "US")
            )
            XCTFail("Expected CheckoutError.sessionNotOpen")
        } catch let error as CheckoutError {
            guard case .sessionNotOpen = error else {
                XCTFail("Expected .sessionNotOpen, got \(error)")
                return
            }
        }
    }

    func testUpdateShippingAddressRequiresOpenSession() async throws {
        let checkout = await makeCheckoutWithClosedSession()

        do {
            try await checkout.updateShippingAddress(
                name: "Jane Doe",
                address: .init(country: "US")
            )
            XCTFail("Expected CheckoutError.sessionNotOpen")
        } catch let error as CheckoutError {
            guard case .sessionNotOpen = error else {
                XCTFail("Expected .sessionNotOpen, got \(error)")
                return
            }
        }
    }

    func testUpdateTaxIdRequiresOpenSession() async throws {
        let checkout = await makeCheckoutWithClosedSession()

        do {
            try await checkout.updateTaxId(type: "eu_vat", value: "DE123456789")
            XCTFail("Expected CheckoutError.sessionNotOpen")
        } catch let error as CheckoutError {
            guard case .sessionNotOpen = error else {
                XCTFail("Expected .sessionNotOpen, got \(error)")
                return
            }
        }
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

        try await checkout.updateBillingAddress(
            name: "Jane Doe",
            address: .init(country: "US", line1: "123 Main St", city: "SF", state: "CA", postalCode: "94105")
        )

        let stored = checkout.state.session.billingAddress
        XCTAssertEqual(stored?.name, "Jane Doe")
        XCTAssertEqual(stored?.address.country, "US")
        XCTAssertTrue(delegate.didChangeStateCalled)
    }

    func testUpdateShippingAddress_noTax_setsLocallyAndNotifiesDelegate() async throws {
        let checkout = await makeCheckoutWithOpenSession()
        let delegate = MockCheckoutDelegate()
        checkout.delegate = delegate

        try await checkout.updateShippingAddress(
            name: "John Smith",
            address: .init(country: "US", line1: "456 Oak Ave", city: "LA", state: "CA", postalCode: "90001")
        )

        let stored = checkout.state.session.shippingAddress
        XCTAssertEqual(stored?.name, "John Smith")
        XCTAssertEqual(stored?.address.country, "US")
        XCTAssertTrue(delegate.didChangeStateCalled)
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

    // MARK: - onConfirmed Tests

    func testOnConfirmedUpdatesSessionAndNotifiesDelegate() async {
        let checkout = await makeCheckoutWithOpenSession()
        let delegate = MockCheckoutDelegate()
        checkout.delegate = delegate

        // Simulate a confirm response with different data
        var updatedJSON = CheckoutTestHelpers.makeOpenSessionJSON()
        updatedJSON["status"] = "complete"
        updatedJSON["payment_status"] = "paid"
        let confirmResponse = STPCheckoutSession.decodedObject(fromAPIResponse: updatedJSON)!

        // Invoke the onConfirmed closure as the confirm call sites do
        let stpSession = checkout.state.session as! STPCheckoutSession
        stpSession.onConfirmed?(confirmResponse)

        // Verify session was updated with the confirm response data
        XCTAssertEqual(checkout.state.session.status?.type, .complete)
        XCTAssertEqual(checkout.state.session.status?.paymentStatus, .paid)
        XCTAssertTrue(delegate.didChangeStateCalled)
    }

    func testOnConfirmedCarriesOverAddressOverrides() async {
        let checkout = await makeCheckoutWithOpenSession()

        // Set address overrides on the initial session
        let billingUpdate = Checkout.ContactAddress(
            name: "Jane Doe",
            address: .init(country: "US")
        )
        (checkout.state.session as! STPCheckoutSession).billingAddress = billingUpdate

        // Simulate a confirm response
        var updatedJSON = CheckoutTestHelpers.makeOpenSessionJSON()
        updatedJSON["status"] = "complete"
        updatedJSON["payment_status"] = "paid"
        let confirmResponse = STPCheckoutSession.decodedObject(fromAPIResponse: updatedJSON)!

        let stpSession = checkout.state.session as! STPCheckoutSession
        stpSession.onConfirmed?(confirmResponse)

        // Address overrides should be carried over to the new session
        XCTAssertEqual(checkout.state.session.billingAddress?.name, "Jane Doe")
        XCTAssertEqual(checkout.state.session.billingAddress?.address.country, "US")
    }

    func testOnConfirmedSetsNewClosureOnUpdatedSession() async {
        let checkout = await makeCheckoutWithOpenSession()
        let delegate = MockCheckoutDelegate()
        checkout.delegate = delegate

        // First confirm
        var firstResponse = CheckoutTestHelpers.makeOpenSessionJSON()
        firstResponse["status"] = "complete"
        firstResponse["payment_status"] = "paid"
        let firstConfirm = STPCheckoutSession.decodedObject(fromAPIResponse: firstResponse)!

        (checkout.state.session as! STPCheckoutSession).onConfirmed?(firstConfirm)
        XCTAssertEqual(checkout.state.session.status?.type, .complete)

        // The new session should also have onConfirmed set,
        // so a second invocation still works
        let secondSession = checkout.state.session as! STPCheckoutSession
        XCTAssertNotNil(secondSession.onConfirmed)
    }

    // MARK: - State Convenience Tests

    func testStateSessionAlwaysReturnsSession() async {
        let checkout = await makeCheckoutWithOpenSession()
        XCTAssertNotNil(checkout.state.session)
        XCTAssertEqual(checkout.state.session.status?.type, .open)
    }

    func testStateIsLoadingReturnsFalseForLoaded() async {
        let checkout = await makeCheckoutWithOpenSession()
        XCTAssertFalse(checkout.state.isLoading)
    }

    // MARK: - Helpers

    private func makeCheckoutWithOpenSession() async -> Checkout {
        let session = CheckoutTestHelpers.makeOpenSession()
        return await Checkout(clientSecret: "cs_test_123_secret_abc", session: session)
    }

    private func makeCheckoutWithClosedSession() async -> Checkout {
        let session = CheckoutTestHelpers.makeClosedSession()
        return await Checkout(clientSecret: "cs_test_123_secret_abc", session: session)
    }
}

// MARK: - Mock Delegate

@MainActor
private class MockCheckoutDelegate: CheckoutDelegate {
    var didChangeStateCalled = false
    var lastState: Checkout.State?

    func checkout(_ checkout: Checkout, didChangeState state: Checkout.State) {
        didChangeStateCalled = true
        lastState = state
    }
}

@MainActor
private class MockCheckoutIntegrationDelegate: CheckoutIntegrationDelegate {
    var isSheetPresented: Bool = false
}
