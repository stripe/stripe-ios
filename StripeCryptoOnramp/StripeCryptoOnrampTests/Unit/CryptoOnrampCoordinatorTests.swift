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

    func testApplePayPlatformPublishableKeyValidationSucceedsForMatchingKeys() throws {
        // Given an Apple Pay payment method and current platform using the same publishable key
        let publishableKey = "pk_test_matching"

        // When validating the keys, then no error is thrown
        XCTAssertNoThrow(try CryptoOnrampCoordinator.validateApplePayPlatformPublishableKey(
            publishableKey,
            currentPlatformPublishableKey: publishableKey
        ))
    }

    func testApplePayPlatformPublishableKeyValidationFailsForDifferentKeys() throws {
        do {
            // When validating an Apple Pay payment method against a different current platform key
            try CryptoOnrampCoordinator.validateApplePayPlatformPublishableKey(
                "pk_test_selected",
                currentPlatformPublishableKey: "pk_test_current"
            )
            XCTFail("Expected validation to fail.")
        } catch {
            // Then the mismatch requires Apple Pay to be collected again
            guard let coordinatorError = error as? CryptoOnrampCoordinator.Error,
                  case .applePayMerchantOfRecordMismatch = coordinatorError else {
                XCTFail("Expected an Apple Pay merchant-of-record mismatch but got: \(error).")
                return
            }
        }
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
