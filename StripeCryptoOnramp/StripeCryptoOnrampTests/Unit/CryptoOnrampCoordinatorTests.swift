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

    func testPlatformClientIsReusedForUnchangedCustomer() async throws {
        let state = CryptoOnrampState("test-customer")
        let client = stubbedAPIClient()
        let first = try await state.getPlatformApiClient { customerId in
            XCTAssertEqual(customerId, "test-customer")
            return client
        }

        await state.setCustomerId("test-customer")
        let second = try await state.getPlatformApiClient { _ in
            XCTFail("Expected the cached client")
            return client
        }

        XCTAssertTrue(first === client)
        XCTAssertTrue(second === client)
    }

    func testPlatformClientIsReusedWithoutCustomer() async throws {
        let state = CryptoOnrampState(nil)
        let client = stubbedAPIClient()
        let first = try await state.getPlatformApiClient { customerId in
            XCTAssertNil(customerId)
            return client
        }
        let second = try await state.getPlatformApiClient { _ in
            XCTFail("Expected the cached client")
            return client
        }

        XCTAssertTrue(first === client)
        XCTAssertTrue(second === client)
    }

    func testPlatformClientIsResolvedWhenCustomerChanges() async throws {
        let state = CryptoOnrampState(nil)
        let initialClient = stubbedAPIClient()
        _ = try await state.getPlatformApiClient { _ in initialClient }

        for customerId in ["test-customer-a", "test-customer-b"] {
            let client = stubbedAPIClient()
            await state.setCustomerId(customerId)
            let resolved = try await state.getPlatformApiClient { requestedCustomerId in
                XCTAssertEqual(requestedCustomerId, customerId)
                return client
            }
            XCTAssertTrue(resolved === client)
        }
    }

    func testClearingCustomerPreventsReuseOfAuthenticatedClient() async throws {
        let state = CryptoOnrampState("test-customer")
        let authenticatedClient = stubbedAPIClient()
        _ = try await state.getPlatformApiClient { _ in authenticatedClient }

        await state.setCustomerId(nil)
        let anonymousClient = stubbedAPIClient()
        let resolved = try await state.getPlatformApiClient { customerId in
            XCTAssertNil(customerId)
            return anonymousClient
        }

        let customerId = await state.getCustomerId()
        XCTAssertNil(customerId)
        XCTAssertTrue(resolved === anonymousClient)
    }

    func testPlatformClientRetriesWhenCustomerChangesDuringRequest() async throws {
        let state = CryptoOnrampState(nil)
        let initialClient = stubbedAPIClient()
        let authenticatedClient = stubbedAPIClient()
        var requestedCustomerIds: [String?] = []

        let resolved = try await state.getPlatformApiClient { customerId in
            requestedCustomerIds.append(customerId)
            if customerId == nil {
                // When authentication finishes before the initial response returns
                await state.setCustomerId("test-customer")
                return initialClient
            }
            return authenticatedClient
        }

        // Then both the returned client and the cache match the authenticated customer
        XCTAssertEqual(requestedCustomerIds, [nil, "test-customer"])
        XCTAssertTrue(resolved === authenticatedClient)
        let cached = try await state.getPlatformApiClient { _ in
            XCTFail("Expected the authenticated client to be cached")
            return initialClient
        }
        XCTAssertTrue(cached === authenticatedClient)
    }

    func testLatePlatformResponseDoesNotOverwriteNewerClient() async throws {
        let state = CryptoOnrampState(nil)
        let initialClient = stubbedAPIClient()
        let authenticatedClient = stubbedAPIClient()

        let resolved = try await state.getPlatformApiClient { customerId in
            XCTAssertNil(customerId)
            await state.setCustomerId("test-customer")

            // When a request for the new customer finishes before the initial response
            _ = try await state.getPlatformApiClient { newCustomerId in
                XCTAssertEqual(newCustomerId, "test-customer")
                return authenticatedClient
            }
            return initialClient
        }

        // Then the initial caller receives the newer cached client
        XCTAssertTrue(resolved === authenticatedClient)
        let cached = try await state.getPlatformApiClient { _ in
            XCTFail("Expected the newer client to remain cached")
            return initialClient
        }
        XCTAssertTrue(cached === authenticatedClient)
    }

    func testPlatformClientRetriesWhenCustomerIsClearedDuringRequest() async throws {
        let state = CryptoOnrampState("test-customer")
        let authenticatedClient = stubbedAPIClient()
        let anonymousClient = stubbedAPIClient()
        var requestedCustomerIds: [String?] = []

        let resolved = try await state.getPlatformApiClient { customerId in
            requestedCustomerIds.append(customerId)
            if customerId != nil {
                await state.setCustomerId(nil)
                return authenticatedClient
            }
            return anonymousClient
        }

        XCTAssertEqual(requestedCustomerIds, ["test-customer", nil])
        XCTAssertTrue(resolved === anonymousClient)
    }

    func testFailedPlatformRequestCanBeRetried() async throws {
        let state = CryptoOnrampState(nil)
        let expectedError = NSError(domain: "TestError", code: 1)
        do {
            _ = try await state.getPlatformApiClient { _ in throw expectedError }
            XCTFail("Expected the request to fail")
        } catch {
            XCTAssertEqual(error as NSError, expectedError)
        }

        let client = stubbedAPIClient()
        let resolved = try await state.getPlatformApiClient { _ in client }
        XCTAssertTrue(resolved === client)
    }

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
