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
            characterCount: 5,
            sessionToken: "tok_abc",
            source: "google",
            duration: 1.5,
            latency: 0.3,
            apiClient: .init(publishableKey: "pk_test_123")
        )
        let last = client._testLogHistory.last!
        XCTAssertEqual(last["event"] as? String, "mc_address_autocomplete_suggestions")
        XCTAssertEqual(last["character_count"] as? Int, 5)
        XCTAssertEqual(last["session_token"] as? String, "tok_abc")
        XCTAssertEqual(last["source"] as? String, "google")
        XCTAssertEqual(last["duration"] as? Double, 1.5)
        XCTAssertEqual(last["latency"] as? Double, 0.3)
    }

    func testLogAddressAutocompleteSuggestions_withoutLatency() {
        let client = STPTestingAnalyticsClient()
        client.logAddressAutocompleteSuggestions(
            characterCount: 3,
            sessionToken: "tok_xyz",
            source: "apple",
            duration: 0.8,
            latency: nil,
            apiClient: .init(publishableKey: "pk_test_123")
        )
        let last = client._testLogHistory.last!
        XCTAssertEqual(last["event"] as? String, "mc_address_autocomplete_suggestions")
        XCTAssertEqual(last["source"] as? String, "apple")
        XCTAssertNil(last["latency"])
    }

    func testLogAddressAutocompleteComplete_withLatency() {
        let client = STPTestingAnalyticsClient()
        client.logAddressAutocompleteComplete(
            characterCount: 7,
            sessionToken: "tok_abc",
            source: "google",
            duration: 2.0,
            latency: 0.4,
            apiClient: .init(publishableKey: "pk_test_123")
        )
        let last = client._testLogHistory.last!
        XCTAssertEqual(last["event"] as? String, "mc_address_autocomplete_complete")
        XCTAssertEqual(last["character_count"] as? Int, 7)
        XCTAssertEqual(last["source"] as? String, "google")
        XCTAssertEqual(last["latency"] as? Double, 0.4)
    }

    func testLogAddressAutocompleteComplete_withoutLatency() {
        let client = STPTestingAnalyticsClient()
        client.logAddressAutocompleteComplete(
            characterCount: 4,
            sessionToken: "tok_xyz",
            source: "apple",
            duration: 1.2,
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
            error: error,
            sessionToken: "tok_abc",
            duration: 0.5,
            apiClient: .init(publishableKey: "pk_test_123")
        )
        let last = client._testLogHistory.last!
        XCTAssertEqual(last["event"] as? String, "mc_address_autocomplete_error")
        XCTAssertEqual(last["session_token"] as? String, "tok_abc")
        XCTAssertEqual(last["error"] as? String, "network failure")
        XCTAssertEqual(last["duration"] as? Double, 0.5)
    }
}
