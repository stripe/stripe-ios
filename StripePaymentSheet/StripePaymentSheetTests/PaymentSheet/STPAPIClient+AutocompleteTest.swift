//
//  STPAPIClient+AutocompleteTest.swift
//  StripePaymentSheetTests
//
//  Created by Joyce Qin on 5/26/26.
//

import StripeCoreTestUtils
import StripePaymentsTestUtils
import XCTest

@testable @_spi(STP) import StripePaymentSheet

class STPAPIClientAutocompleteTest: STPNetworkStubbingTestCase {
    func _testAutocomplete() async throws {
        let response = try await makeAPIClient().autocomplete(
            searchText: "354 Oyster Point",
            locale: "en-US",
            countryCodes: ["US"],
            sessionToken: UUID().uuidString
        )
        XCTAssertFalse(response.source.isEmpty)
        XCTAssertFalse(response.suggestions.isEmpty)
        let first = try XCTUnwrap(response.suggestions.first)
        XCTAssertFalse(first.title.isEmpty)
        XCTAssertFalse(first.subtitle.isEmpty)
        XCTAssertFalse(first.matches.isEmpty)
    }
}

private func makeAPIClient() -> STPAPIClient {
    STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
}
