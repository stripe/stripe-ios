//
//  CustomerSessionAdapterTests.swift
//  StripePaymentSheetTests
//

import Foundation
import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
import XCTest

class CustomerSessionAdapterTests: APIStubbedTestCase {
    func testCachedCustomerSessionClientSecretIsNotExpiredWhenCreated() {
        let cachedSession = makeCachedSession()

        XCTAssertFalse(cachedSession.isExpired())
    }

    func testCachedCustomerSessionClientSecretReusesUnexpiredSession() async throws {
        // Given an adapter that has already claimed a customer session
        var elementsSessionRequestCount = 0
        StubbedBackend.stubSessions(fileMock: .elementsSessions_customerSessionsCustomerSheet_200) { data in
            elementsSessionRequestCount += 1
            return data
        }
        var providerCallCount = 0
        let adapter = makeAdapter {
            providerCallCount += 1
            return .init(customerId: "cus_123", clientSecret: "cuss_123")
        }
        let originalSession = try await adapter.cachedCustomerSessionClientSecret()

        // When the cached session is requested again before it expires
        let cachedSession = try await adapter.cachedCustomerSessionClientSecret()

        // Then the same credentials are returned without calling the provider or API again
        XCTAssertEqual(providerCallCount, 1)
        XCTAssertEqual(elementsSessionRequestCount, 1)
        XCTAssertEqual(cachedSession.customerId, "cus_123")
        XCTAssertEqual(cachedSession.customerSessionClientSecret.clientSecret, "cuss_123")
        XCTAssertEqual(cachedSession.apiKey, originalSession.apiKey)
        XCTAssertEqual(cachedSession.cacheDate, originalSession.cacheDate)
    }

    func testElementsSessionReusesUnexpiredCustomerSession() async throws {
        // Given an adapter that has already loaded an Elements session
        var elementsSessionRequestCount = 0
        StubbedBackend.stubSessions(fileMock: .elementsSessions_customerSessionsCustomerSheet_200) { data in
            elementsSessionRequestCount += 1
            return data
        }
        var providerCallCount = 0
        let adapter = makeAdapter {
            providerCallCount += 1
            return .init(customerId: "cus_123", clientSecret: "cuss_123")
        }
        let (_, originalSession) = try await adapter.elementsSessionWithCustomerSessionClientSecret()

        // When another Elements session is loaded before the customer session expires
        let (_, cachedSession) = try await adapter.elementsSessionWithCustomerSessionClientSecret()

        // Then the API is called again using the cached customer session without calling the provider
        XCTAssertEqual(providerCallCount, 1)
        XCTAssertEqual(elementsSessionRequestCount, 2)
        XCTAssertEqual(cachedSession.customerId, "cus_123")
        XCTAssertEqual(cachedSession.customerSessionClientSecret.clientSecret, "cuss_123")
        XCTAssertEqual(cachedSession.apiKey, originalSession.apiKey)
        XCTAssertEqual(cachedSession.cacheDate, originalSession.cacheDate)
    }

    private func makeCachedSession() -> CustomerSessionAdapter.CachedCustomerSessionClientSecret {
        return .init(customerSessionClientSecret: .init(customerId: "cus_123", clientSecret: "cuss_123"),
                     apiKey: "ek_123")
    }

    private func makeAdapter(
        customerSessionClientSecretProvider: @escaping CustomerSessionAdapter.CustomerSessionClientSecretProvider
    ) -> CustomerSessionAdapter {
        var configuration = CustomerSheet.Configuration()
        configuration.apiClient = stubbedAPIClient()
        return CustomerSessionAdapter(
            customerSessionClientSecretProvider: customerSessionClientSecretProvider,
            intentConfiguration: .init(setupIntentClientSecretProvider: { "si_123" }),
            configuration: configuration
        )
    }
}
