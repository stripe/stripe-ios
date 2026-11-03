import OHHTTPStubs
import OHHTTPStubsSwift
@testable @_spi(InternalOnlyAPI) import StripeCore
@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
@testable @_spi(InternalOnlyAPI) import StripePaymentsTestUtils
import XCTest

/// Live test-backend repros for overlapping merchant shipping-address updates.
/// These tests use no recorded or mocked network responses.
@MainActor
final class CheckoutShippingMutationLiveTests: XCTestCase {
    override func setUp() {
        super.setUp()
        HTTPStubs.removeAllStubs()
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    func testSetThenClearWhileRequestIsInFlight() async throws {
        try await checkUpdates(initial: nil, first: "A", last: nil)
    }

    func testChangeThenRestoreWhileRequestIsInFlight() async throws {
        try await checkUpdates(initial: "A", first: "B", last: "A")
    }

    func testClearThenRestoreWhileRequestIsInFlight() async throws {
        try await checkUpdates(initial: "A", first: nil, last: "A")
    }

    func testTwoDistinctChangesWhileRequestIsInFlight() async throws {
        try await checkUpdates(initial: "A", first: "B", last: "C")
    }

    func testSequentialSetThenClear() async throws {
        try await checkUpdates(initial: nil, first: "A", last: nil, overlapping: false)
    }

    private func checkUpdates(
        initial: String?,
        first: String?,
        last: String?,
        overlapping: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        // Given a real test session with shipping-sourced automatic tax, without an Element.
        let response = try await STPTestingAPIClient.shared.createCheckoutSession(
            automaticTax: true,
            allowedShippingCountries: ["US"],
            customerEmail: "shipping-audit@example.com"
        )
        var configuration = CheckoutController.Configuration(
            clientSecret: response.clientSecret,
            returnURL: "stripe-ios-test://checkout-return"
        )
        configuration.apiClient = STPAPIClient(publishableKey: response.publishableKey)
        let checkout = try await CheckoutController(configuration: configuration)
        XCTAssertFalse(checkout.session.livemode)
        XCTAssertEqual(checkout.session.automaticTaxAddressSource, "shipping")
        try await checkout.updateShippingAddress(name: initial, address: address(initial))

        // Observe when the first update reaches the network. Returning false leaves the
        // request untouched; no response stub is installed for it.
        let requestStarted = expectation(description: "First shipping update requested")
        requestStarted.assertForOverFulfill = false
        let observer = stub { request in
            if request.url?.path.hasSuffix("/update") == true {
                requestStarted.fulfill()
            }
            return false
        } response: { _ in
            XCTFail("The observer must never supply a response")
            return HTTPStubsResponse()
        }
        defer { HTTPStubs.removeStub(observer) }

        // When a later merchant API call arrives before the first request finishes
        let firstUpdate = Task { @MainActor in
            try await checkout.updateShippingAddress(name: first, address: self.address(first))
        }
        if overlapping {
            await fulfillment(of: [requestStarted], timeout: 10)
            XCTAssertTrue(checkout.isUpdating, "The calls must overlap", file: file, line: line)
            XCTAssertEqual(checkout.session.shippingAddress?.name, initial, file: file, line: line)
        } else {
            try await firstUpdate.value
            await fulfillment(of: [requestStarted], timeout: 10)
        }
        HTTPStubs.removeStub(observer)
        try await checkout.updateShippingAddress(name: last, address: address(last))
        try await firstUpdate.value

        // Then both calls succeeded, so the final address and tax region should be the latest.
        XCTAssertFalse(checkout.isUpdating, file: file, line: line)
        XCTAssertEqual(checkout.session.shippingAddress?.name, last, file: file, line: line)
        XCTAssertEqual(checkout.session.shippingAddress?.address, address(last), file: file, line: line)
        XCTAssertEqual(checkout.currentTaxRegion, address(last), file: file, line: line)
    }

    private func address(_ name: String?) -> CheckoutController.Address? {
        switch name {
        case "A":
            return .init(country: "US", line1: "510 Townsend St", city: "San Francisco", state: "CA", postalCode: "94103")
        case "B":
            return .init(country: "US", line1: "350 5th Ave", city: "New York", state: "NY", postalCode: "10118")
        case "C":
            return .init(country: "US", line1: "400 Broad St", city: "Seattle", state: "WA", postalCode: "98109")
        default:
            return nil
        }
    }
}
