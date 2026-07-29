//
//  FinancialConnectionsLiteTests.swift
//  StripeFinancialConnectionsLiteTests
//

@_spi(STP) import StripeCore
@testable @_spi(STP) import StripeFinancialConnectionsLite
import XCTest

class FinancialConnectionsLiteTests: XCTestCase {

    func testUsesProvidedAPIClient() {
        // Given a custom API client
        let customClient = STPAPIClient(publishableKey: "pk_test_custom")

        // When constructing FinancialConnectionsLite with it
        let fcLite = FinancialConnectionsLite(
            clientSecret: "las_123",
            returnUrl: URL(string: "stripe://return"),
            apiClient: customClient
        )

        // Then that client is stored (rather than falling back to .shared)
        XCTAssertTrue(fcLite.apiClient === customClient)
    }

    func testDefaultsToSharedAPIClient() {
        // Given no explicit API client
        let fcLite = FinancialConnectionsLite(clientSecret: "las_123", returnUrl: nil)

        // Then it defaults to the shared client
        XCTAssertTrue(fcLite.apiClient === STPAPIClient.shared)
    }

    func testStoresConsumerKeyAndPrefillDetails() {
        // Given a FinancialConnectionsLite instance
        let fcLite = FinancialConnectionsLite(clientSecret: "las_123", returnUrl: nil)

        // When setting the consumer key and prefill details
        fcLite.consumerPublishableKey = "pk_consumer"
        fcLite.prefillDetails = WebPrefillDetails(
            email: "test@example.com",
            phone: "5551234567",
            countryCode: "US"
        )

        // Then they are stored
        XCTAssertEqual(fcLite.consumerPublishableKey, "pk_consumer")
        XCTAssertEqual(fcLite.prefillDetails?.email, "test@example.com")
        XCTAssertEqual(fcLite.prefillDetails?.phone, "5551234567")
        XCTAssertEqual(fcLite.prefillDetails?.countryCode, "US")
    }
}
