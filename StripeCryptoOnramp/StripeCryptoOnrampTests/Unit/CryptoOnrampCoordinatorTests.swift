//
//  CryptoOnrampCoordinatorTests.swift
//  StripeCryptoOnrampTests
//
//  Created by Michael Liberatore on 7/20/26.
//

import Foundation
import OHHTTPStubs
import OHHTTPStubsSwift
import StripeCore
import StripeCoreTestUtils
@testable @_spi(CryptoOnrampAlpha) import StripeCryptoOnramp
import XCTest

final class CryptoOnrampCoordinatorTests: APIStubbedTestCase {
    func testCreateSucceedsWithoutSpecifyingPaymentMethodTypes() async throws {
        stub { request in
            request.url?.path == "/v1/elements/sessions"
        } response: { request in
            // Tests for a regression that occurred when `LinkController` briefly was passing
            // "link" for `payment_method_types`, ultimately triggering a failure to initialize onramp.
            XCTAssertFalse(request.url?.absoluteString.contains("payment_method_types") ?? true)
            return HTTPStubsResponse(jsonObject: Self.linkElementsSession, statusCode: 200, headers: nil)
        }

        let apiClient = stubbedAPIClient()
        apiClient.publishableKey = "pk_test_1234"

        let coordinator = try await CryptoOnrampCoordinator.create(apiClient: apiClient)
        XCTAssertNotNil(coordinator)
    }

    func testGetPlatformApiClientSucceedsWithoutCryptoCustomerID() async throws {
        // Given a coordinator created without a crypto customer ID
        stubElementsSession()
        let platformSettingsRequests = stubPlatformSettings()
        let coordinator = try await CryptoOnrampCoordinator.create(apiClient: stubbedCryptoOnrampAPIClient())

        // When resolving the platform API client
        let platformApiClient = try await coordinator.getPlatformApiClient()

        // Then the platform publishable key is used, and no crypto customer ID was sent
        XCTAssertEqual(platformApiClient.publishableKey, Self.platformPublishableKey)
        XCTAssertEqual(platformSettingsRequests.value.count, 1)
        XCTAssertNil(platformSettingsRequests.value.first?["crypto_customer_id"])
        XCTAssertNil(platformSettingsRequests.value.first?["country_hint"])
    }

    func testGetPlatformApiClientSendsCryptoCustomerIDWhenAvailable() async throws {
        // Given a coordinator created with a crypto customer ID
        stubElementsSession()
        let platformSettingsRequests = stubPlatformSettings()
        let coordinator = try await CryptoOnrampCoordinator.create(
            apiClient: stubbedCryptoOnrampAPIClient(),
            cryptoCustomerID: Self.cryptoCustomerID
        )

        // When resolving the platform API client
        _ = try await coordinator.getPlatformApiClient()

        // Then the crypto customer ID was sent
        XCTAssertEqual(platformSettingsRequests.value.count, 1)
        XCTAssertEqual(platformSettingsRequests.value.first?["crypto_customer_id"], Self.cryptoCustomerID)
    }

    func testGetPlatformApiClientSendsCountryHintWhenConfigured() async throws {
        // Given a coordinator created with a country hint and no crypto customer ID
        stubElementsSession()
        let platformSettingsRequests = stubPlatformSettings()
        let coordinator = try await CryptoOnrampCoordinator.create(
            apiClient: stubbedCryptoOnrampAPIClient(),
            countryHint: "GB"
        )

        // When resolving the platform API client
        _ = try await coordinator.getPlatformApiClient()

        // Then the country hint was sent
        XCTAssertEqual(platformSettingsRequests.value.count, 1)
        XCTAssertEqual(platformSettingsRequests.value.first?["country_hint"], "GB")
    }

    func testGetPlatformApiClientCachesResultUntilCryptoCustomerIDChanges() async throws {
        // Given a platform API client resolved before authentication
        stubElementsSession()
        let platformSettingsRequests = stubPlatformSettings()
        let coordinator = try await CryptoOnrampCoordinator.create(apiClient: stubbedCryptoOnrampAPIClient())
        _ = try await coordinator.getPlatformApiClient()

        // When resolving it again without any change
        _ = try await coordinator.getPlatformApiClient()

        // Then the cached client is reused
        XCTAssertEqual(platformSettingsRequests.value.count, 1)

        // ...and when a crypto customer ID becomes available and the client is resolved again
        await coordinator.setCryptoCustomerId(Self.cryptoCustomerID)
        _ = try await coordinator.getPlatformApiClient()

        // Then platform settings are re-fetched using the crypto customer ID
        XCTAssertEqual(platformSettingsRequests.value.count, 2)
        XCTAssertEqual(platformSettingsRequests.value.last?["crypto_customer_id"], Self.cryptoCustomerID)
    }

    func testCreateCryptoPaymentTokenThrowsWithoutSelectedPaymentSource() async throws {
        // Given a coordinator with no collected payment method
        stubElementsSession()
        let coordinator = try await CryptoOnrampCoordinator.create(apiClient: stubbedCryptoOnrampAPIClient())

        do {
            // When creating a crypto payment token
            _ = try await coordinator.createCryptoPaymentToken()
            XCTFail("Expected failure but got success.")
        } catch {
            // Then an error is thrown
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Helpers

    /// Thread-safe collection of observed request parameters.
    private final class RequestRecorder: @unchecked Sendable {
        private let lock = NSLock()
        private var parameters: [[String: String]] = []

        var value: [[String: String]] {
            lock.lock()
            defer { lock.unlock() }
            return parameters
        }

        func record(_ newParameters: [String: String]) {
            lock.lock()
            defer { lock.unlock() }
            parameters.append(newParameters)
        }
    }

    private func stubbedCryptoOnrampAPIClient() -> STPAPIClient {
        let apiClient = stubbedAPIClient()
        apiClient.publishableKey = "pk_test_1234"
        return apiClient
    }

    private func stubElementsSession() {
        stub { request in
            request.url?.path == "/v1/elements/sessions"
        } response: { _ in
            HTTPStubsResponse(jsonObject: Self.linkElementsSession, statusCode: 200, headers: nil)
        }
    }

    private func stubPlatformSettings() -> RequestRecorder {
        let recorder = RequestRecorder()
        stub { request in
            request.url?.path == "/v1/crypto/internal/platform_settings"
        } response: { request in
            recorder.record(request.url?.queryParametersDictionary ?? [:])
            return HTTPStubsResponse(
                jsonObject: ["publishable_key": Self.platformPublishableKey],
                statusCode: 200,
                headers: nil
            )
        }
        return recorder
    }

    private static let cryptoCustomerID = "crc_12345"
    private static let platformPublishableKey = "pk_test_platform_1234"

    private static let linkElementsSession: [String: Any] = [
        "config_id": "config_crypto_onramp",
        "link_settings": [
            "link_funding_sources": ["CARD"],
            "link_mobile_use_attestation_endpoints": true,
        ],
        "merchant_country": "US",
        "ordered_payment_method_types_and_wallets": ["card"],
        "payment_method_preference": [
            "country_code": "US",
            "object": "payment_method_preference",
            "ordered_payment_method_types": ["card"],
            "type": "deferred_intent",
        ],
        "session_id": "elements_session_crypto_onramp",
    ]
}

private extension URL {
    var queryParametersDictionary: [String: String] {
        guard let queryItems = URLComponents(url: self, resolvingAgainstBaseURL: false)?.queryItems else {
            return [:]
        }

        return queryItems.reduce(into: [:]) { result, item in
            if let value = item.value {
                result[item.name] = value
            }
        }
    }
}
