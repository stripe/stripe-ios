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

    func testCachedCustomerSessionClientSecretIsNotExpiredBeforeThirtyMinutes() {
        // Given a cached session using a controllable clock
        let timeReference = MockTimeReference()
        let cachedSession = makeCachedSession(timeProvider: timeReference.now)

        // When the clock advances to one second before the thirty-minute cutoff
        timeReference.advanceBy(30 * 60 - 1)

        // Then the session is still valid
        XCTAssertFalse(cachedSession.isExpired())
    }

    func testCachedCustomerSessionClientSecretIsExpiredAtThirtyMinutes() {
        // Given a cached session using a controllable clock
        let timeReference = MockTimeReference()
        let cachedSession = makeCachedSession(timeProvider: timeReference.now)

        // When the clock advances exactly thirty minutes
        timeReference.advanceBy(30 * 60)

        // Then the session has expired
        XCTAssertTrue(cachedSession.isExpired())
    }

    func testCachedCustomerSessionClientSecretIsExpiredAfterThirtyMinutes() {
        // Given a cached session using a controllable clock
        let timeReference = MockTimeReference()
        let cachedSession = makeCachedSession(timeProvider: timeReference.now)

        // When the clock advances past thirty minutes
        timeReference.advanceBy(30 * 60 + 1)

        // Then the session has expired
        XCTAssertTrue(cachedSession.isExpired())
    }

    func testCachedCustomerSessionClientSecretReusesUnexpiredSession() async throws {
        // Given an adapter that has already claimed a customer session
        let timeReference = MockTimeReference()
        var elementsSessionRequestCount = 0
        StubbedBackend.stubSessions(fileMock: .elementsSessions_customerSessionsCustomerSheet_200) { data in
            elementsSessionRequestCount += 1
            return data
        }
        var providerCallCount = 0
        let adapter = makeAdapter(timeProvider: timeReference.now) {
            providerCallCount += 1
            return .init(customerId: "cus_123", clientSecret: "cuss_123")
        }
        let originalSession = try await adapter.cachedCustomerSessionClientSecret()

        // When the cached session is requested again before it expires
        timeReference.advanceBy(30 * 60 - 1)
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
        let timeReference = MockTimeReference()
        var elementsSessionRequestCount = 0
        StubbedBackend.stubSessions(fileMock: .elementsSessions_customerSessionsCustomerSheet_200) { data in
            elementsSessionRequestCount += 1
            return data
        }
        var providerCallCount = 0
        let adapter = makeAdapter(timeProvider: timeReference.now) {
            providerCallCount += 1
            return .init(customerId: "cus_123", clientSecret: "cuss_123")
        }
        let (_, originalSession) = try await adapter.elementsSessionWithCustomerSessionClientSecret()

        // When another Elements session is loaded before the customer session expires
        timeReference.advanceBy(30 * 60 - 1)
        let (_, cachedSession) = try await adapter.elementsSessionWithCustomerSessionClientSecret()

        // Then the API is called again using the cached customer session without calling the provider
        XCTAssertEqual(providerCallCount, 1)
        XCTAssertEqual(elementsSessionRequestCount, 2)
        XCTAssertEqual(cachedSession.customerId, "cus_123")
        XCTAssertEqual(cachedSession.customerSessionClientSecret.clientSecret, "cuss_123")
        XCTAssertEqual(cachedSession.apiKey, originalSession.apiKey)
        XCTAssertEqual(cachedSession.cacheDate, originalSession.cacheDate)
    }

    func testCachedCustomerSessionClientSecretRefreshesExpiredSession() async throws {
        // Given an adapter that has already claimed a customer session
        let timeReference = MockTimeReference()
        var elementsSessionRequestCount = 0
        StubbedBackend.stubSessions(fileMock: .elementsSessions_customerSessionsCustomerSheet_200) { data in
            elementsSessionRequestCount += 1
            return data
        }
        var providerCallCount = 0
        let adapter = makeAdapter(timeProvider: timeReference.now) {
            providerCallCount += 1
            return .init(customerId: "cus_123", clientSecret: "cuss_\(providerCallCount)")
        }
        let originalSession = try await adapter.cachedCustomerSessionClientSecret()

        // When the cached session is requested exactly thirty minutes later
        timeReference.advanceBy(30 * 60)
        let refreshedSession = try await adapter.cachedCustomerSessionClientSecret()

        // Then a new session is claimed and cached with a new expiry time
        XCTAssertEqual(providerCallCount, 2)
        XCTAssertEqual(elementsSessionRequestCount, 2)
        XCTAssertEqual(originalSession.customerSessionClientSecret.clientSecret, "cuss_1")
        XCTAssertEqual(refreshedSession.customerSessionClientSecret.clientSecret, "cuss_2")
        XCTAssertEqual(refreshedSession.cacheDate, timeReference.now())
        XCTAssertFalse(refreshedSession.isExpired())

        // ...and the refreshed session stays cached for another thirty minutes
        timeReference.advanceBy(30 * 60 - 1)
        let cachedSession = try await adapter.cachedCustomerSessionClientSecret()
        XCTAssertEqual(providerCallCount, 2)
        XCTAssertEqual(elementsSessionRequestCount, 2)
        XCTAssertEqual(cachedSession.customerSessionClientSecret.clientSecret, "cuss_2")
        XCTAssertEqual(cachedSession.cacheDate, refreshedSession.cacheDate)
    }

    func testElementsSessionRefreshesExpiredCustomerSession() async throws {
        // Given an adapter that has already loaded an Elements session
        let timeReference = MockTimeReference()
        var elementsSessionRequestCount = 0
        StubbedBackend.stubSessions(fileMock: .elementsSessions_customerSessionsCustomerSheet_200) { data in
            elementsSessionRequestCount += 1
            return data
        }
        var providerCallCount = 0
        let adapter = makeAdapter(timeProvider: timeReference.now) {
            providerCallCount += 1
            return .init(customerId: "cus_123", clientSecret: "cuss_\(providerCallCount)")
        }
        let (_, originalSession) = try await adapter.elementsSessionWithCustomerSessionClientSecret()

        // When another Elements session is loaded after the customer session expires
        timeReference.advanceBy(30 * 60 + 1)
        let (_, refreshedSession) = try await adapter.elementsSessionWithCustomerSessionClientSecret()

        // Then a new customer session is claimed and cached
        XCTAssertEqual(providerCallCount, 2)
        XCTAssertEqual(elementsSessionRequestCount, 2)
        XCTAssertEqual(originalSession.customerSessionClientSecret.clientSecret, "cuss_1")
        XCTAssertEqual(refreshedSession.customerSessionClientSecret.clientSecret, "cuss_2")
        XCTAssertEqual(refreshedSession.cacheDate, timeReference.now())
        XCTAssertFalse(refreshedSession.isExpired())

        // ...and the refreshed session is available without another provider or API call
        let cachedSession = try await adapter.cachedCustomerSessionClientSecret()
        XCTAssertEqual(providerCallCount, 2)
        XCTAssertEqual(elementsSessionRequestCount, 2)
        XCTAssertEqual(cachedSession.customerSessionClientSecret.clientSecret, "cuss_2")
        XCTAssertEqual(cachedSession.cacheDate, refreshedSession.cacheDate)
    }

    private func makeCachedSession(
        timeProvider: @escaping () -> Date = Date.init
    ) -> CustomerSessionAdapter.CachedCustomerSessionClientSecret {
        return .init(customerSessionClientSecret: .init(customerId: "cus_123", clientSecret: "cuss_123"),
                     apiKey: "ek_123",
                     timeProvider: timeProvider)
    }

    private func makeAdapter(
        timeProvider: @escaping () -> Date = Date.init,
        customerSessionClientSecretProvider: @escaping CustomerSessionAdapter.CustomerSessionClientSecretProvider
    ) -> CustomerSessionAdapter {
        var configuration = CustomerSheet.Configuration()
        configuration.apiClient = stubbedAPIClient()
        return CustomerSessionAdapter(
            customerSessionClientSecretProvider: customerSessionClientSecretProvider,
            intentConfiguration: .init(setupIntentClientSecretProvider: { "si_123" }),
            configuration: configuration,
            timeProvider: timeProvider
        )
    }

    private final class MockTimeReference {
        private var date = Date(timeIntervalSince1970: 1_000_000)

        func advanceBy(_ timeInterval: TimeInterval) {
            date = date.addingTimeInterval(timeInterval)
        }

        func now() -> Date {
            return date
        }
    }
}
