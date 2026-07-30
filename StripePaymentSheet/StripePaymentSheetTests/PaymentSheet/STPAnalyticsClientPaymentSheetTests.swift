//
//  STPAnalyticsClient+PaymentSheetTests.swift
//  StripePaymentSheetTests
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
import XCTest

class STPAnalyticsClientPaymentSheetTest: XCTestCase {
    func testPaymentSheetSDKVariantPayload() throws {
        // setup
        let analytic = PaymentSheetAnalytic(
            event: .paymentMethodCreation,
            additionalParams: [:]
        )
        let client = STPAnalyticsClient()
        let payload = client.payload(from: analytic)
        XCTAssertEqual("paymentsheet", payload["pay_var"] as? String)
    }

    // MARK: - logBillingAddressCompleted

    func testLogBillingAddressCompleted_withAutocomplete() {
        let client = STPTestingAnalyticsClient()
        client.logBillingAddressCompleted(
            addressCountryCode: "US",
            autoCompleteResultedSelected: true,
            editDistance: 3,
            apiClient: .init(publishableKey: "pk_test_123")
        )
        let last = client._testLogHistory.last!
        XCTAssertEqual(last["event"] as? String, "mc_billing_address_completed")
        let blob = last["address_data_blob"] as? [String: Any?]
        XCTAssertEqual(blob?["address_country_code"] as? String, "US")
        XCTAssertEqual(blob?["auto_complete_result_selected"] as? Bool, true)
        XCTAssertEqual(blob?["edit_distance"] as? Int, 3)
    }

    func testLogBillingAddressCompleted_withoutAutocomplete() {
        let client = STPTestingAnalyticsClient()
        client.logBillingAddressCompleted(
            addressCountryCode: "CA",
            autoCompleteResultedSelected: false,
            editDistance: nil,
            apiClient: .init(publishableKey: "pk_test_123")
        )
        let last = client._testLogHistory.last!
        XCTAssertEqual(last["event"] as? String, "mc_billing_address_completed")
        let blob = last["address_data_blob"] as? [String: Any?]
        XCTAssertEqual(blob?["address_country_code"] as? String, "CA")
        XCTAssertEqual(blob?["auto_complete_result_selected"] as? Bool, false)
        XCTAssertNil(blob?["edit_distance"] as? Int)
    }

    // MARK: - Autocomplete analytics

    func testLogAddressAutocompleteStart() {
        let client = STPTestingAnalyticsClient()
        client.logAddressAutocompleteStart(apiClient: .init(publishableKey: "pk_test_123"))
        XCTAssertEqual(client._testLogHistory.last?["event"] as? String, "mc_address_autocomplete_start")
    }

    func testLogAddressAutocompleteSuggestions_withLatency() {
        let client = STPTestingAnalyticsClient()
        client.logAddressAutocompleteSuggestions(
            queryLength: 5,
            autocompleteSessionToken: "tok_abc",
            source: "google",
            sessionElapsed: 1.5,
            timeToFetch: 0.3,
            apiClient: .init(publishableKey: "pk_test_123")
        )
        let last = client._testLogHistory.last!
        XCTAssertEqual(last["event"] as? String, "mc_address_autocomplete_suggestions")
        XCTAssertEqual(last["query_length"] as? Int, 5)
        XCTAssertEqual(last["autocomplete_session_token"] as? String, "tok_abc")
        XCTAssertEqual(last["source"] as? String, "google")
        XCTAssertEqual(last["session_elapsed"] as? Double, 1.5)
        XCTAssertEqual(last["time_to_fetch"] as? Double, 0.3)
    }

    func testLogAddressAutocompleteSuggestions_withoutLatency() {
        let client = STPTestingAnalyticsClient()
        client.logAddressAutocompleteSuggestions(
            queryLength: 3,
            autocompleteSessionToken: "tok_xyz",
            source: "apple",
            sessionElapsed: 0.8,
            timeToFetch: nil,
            apiClient: .init(publishableKey: "pk_test_123")
        )
        let last = client._testLogHistory.last!
        XCTAssertEqual(last["event"] as? String, "mc_address_autocomplete_suggestions")
        XCTAssertEqual(last["source"] as? String, "apple")
        XCTAssertNil(last["time_to_fetch"])
    }

    func testLogAddressAutocompleteComplete_withLatency() {
        let client = STPTestingAnalyticsClient()
        client.logAddressAutocompleteComplete(
            queryLength: 7,
            autocompleteSessionToken: "tok_abc",
            source: "google",
            timeToComplete: 2.0,
            latency: 0.4,
            apiClient: .init(publishableKey: "pk_test_123")
        )
        let last = client._testLogHistory.last!
        XCTAssertEqual(last["event"] as? String, "mc_address_autocomplete_complete")
        XCTAssertEqual(last["query_length"] as? Int, 7)
        XCTAssertEqual(last["source"] as? String, "google")
        XCTAssertEqual(last["time_to_complete"] as? Double, 2.0)
        XCTAssertEqual(last["latency"] as? Double, 0.4)
    }

    func testLogAddressAutocompleteComplete_withoutLatency() {
        let client = STPTestingAnalyticsClient()
        client.logAddressAutocompleteComplete(
            queryLength: 4,
            autocompleteSessionToken: "tok_xyz",
            source: "apple",
            timeToComplete: 1.2,
            latency: nil,
            apiClient: .init(publishableKey: "pk_test_123")
        )
        let last = client._testLogHistory.last!
        XCTAssertEqual(last["event"] as? String, "mc_address_autocomplete_complete")
        XCTAssertEqual(last["source"] as? String, "apple")
        XCTAssertNil(last["latency"])
    }

    func testLogAddressAutocompleteError() {
        let client = STPTestingAnalyticsClient()
        let error = NSError(domain: "test", code: 42, userInfo: [NSLocalizedDescriptionKey: "network failure"])
        client.logAddressAutocompleteError(
            errorType: error,
            autocompleteSessionToken: "tok_abc",
            duration: 0.5,
            apiClient: .init(publishableKey: "pk_test_123")
        )
        let last = client._testLogHistory.last!
        XCTAssertEqual(last["event"] as? String, "mc_address_autocomplete_error")
        XCTAssertEqual(last["autocomplete_session_token"] as? String, "tok_abc")
        XCTAssertEqual(last["error_type"] as? String, "network failure")
        XCTAssertEqual(last["duration"] as? Double, 0.5)
    }
}
