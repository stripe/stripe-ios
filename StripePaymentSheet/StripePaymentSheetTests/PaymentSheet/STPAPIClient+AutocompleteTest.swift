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
    func testAutocompleteAndDetails() async throws {
        let sessionToken = UUID().uuidString
        let locale = "en-US"
        let autocompleteResponse = try await makeAPIClient().autocomplete(
            searchText: "354 Oyster Point",
            locale: locale,
            countryCodes: ["US"],
            sessionToken: sessionToken
        )
        XCTAssertFalse(autocompleteResponse.source.isEmpty)
        XCTAssertFalse(autocompleteResponse.suggestions.isEmpty)
        let first = try XCTUnwrap(autocompleteResponse.suggestions.first)
        XCTAssertFalse(first.title.isEmpty)
        XCTAssertFalse(first.subtitle.isEmpty)
        XCTAssertFalse(first.matches.isEmpty)
        if let placeId = first.placeId {
            let detailsResponse = try await makeAPIClient().details(
                placeId: placeId,
                source: autocompleteResponse.source,
                locale: locale,
                displayTitle: first.title,
                sessionToken: sessionToken
            )
            XCTAssertNotNil(detailsResponse.address.line1)
        } else {
            XCTAssertNotNil(first.address)
        }
    }
}

private func makeAPIClient() -> STPAPIClient {
    STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
}
