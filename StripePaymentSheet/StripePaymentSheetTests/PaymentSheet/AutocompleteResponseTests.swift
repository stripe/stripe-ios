//
//  AutocompleteResponseTests.swift
//  StripePaymentSheetTests
//
//  Created by Joyce Qin on 5/21/26.
//

import XCTest

@testable import StripePaymentSheet

class AutocompleteResponseTests: XCTestCase {

    // MARK: - AutocompleteResponse

    func testDecodesResponse() {
        let response: [AnyHashable: Any] = [
            "source": "google",
            "suggestions": [makeSuggestionDict(title: "123 Main St", subtitle: "New York, NY", endOffset: 3, placeID: "places/abc123")],
        ]
        let result = AutocompleteResponse.decodedObject(fromAPIResponse: response)
        XCTAssertEqual(result?.source, "google")
        XCTAssertEqual(result?.suggestions.count, 1)
    }

    func testDecodesMultipleSuggestions() {
        let response: [AnyHashable: Any] = [
            "source": "google",
            "suggestions": [
                makeSuggestionDict(title: "123 Main St", subtitle: "New York, NY", endOffset: 3, placeID: nil),
                makeSuggestionDict(title: "456 Oak Ave", subtitle: "Brooklyn, NY", endOffset: 3, placeID: nil),
            ],
        ]
        XCTAssertEqual(AutocompleteResponse.decodedObject(fromAPIResponse: response)?.suggestions.count, 2)
    }

    func testSkipsInvalidSuggestions() {
        let response: [AnyHashable: Any] = [
            "source": "google",
            "suggestions": [
                makeSuggestionDict(title: "123 Main St", subtitle: "New York, NY", endOffset: 3, placeID: nil),
                ["invalid": "data"],
            ],
        ]
        XCTAssertEqual(AutocompleteResponse.decodedObject(fromAPIResponse: response)?.suggestions.count, 1)
    }

    func testReturnsNilForMissingSource() {
        let response: [AnyHashable: Any] = ["suggestions": []]
        XCTAssertNil(AutocompleteResponse.decodedObject(fromAPIResponse: response))
    }

    func testReturnsNilForMissingSuggestions() {
        let response: [AnyHashable: Any] = ["source": "google"]
        XCTAssertNil(AutocompleteResponse.decodedObject(fromAPIResponse: response))
    }

    func testReturnsNilForNilResponse() {
        XCTAssertNil(AutocompleteResponse.decodedObject(fromAPIResponse: nil))
    }

    // MARK: - AddressSuggestion fields

    func testDecodesSuggestionFields() {
        let suggestion = AddressSuggestion.decodedObject(fromAPIResponse:
            makeSuggestionDict(title: "123 Main St", subtitle: "New York, NY", endOffset: 3, placeID: "places/abc123")
        )
        XCTAssertEqual(suggestion?.title, "123 Main St")
        XCTAssertEqual(suggestion?.subtitle, "New York, NY")
        XCTAssertEqual(suggestion?.placeID, "places/abc123")
    }

    func testDecodesSuggestionWithNilPlaceID() {
        let suggestion = AddressSuggestion.decodedObject(fromAPIResponse:
            makeSuggestionDict(title: "123 Main St", subtitle: "New York, NY", endOffset: 3, placeID: nil)
        )
        XCTAssertNotNil(suggestion)
        XCTAssertNil(suggestion?.placeID)
    }

    func testReturnsNilForMissingDisplayData() {
        let dict: [AnyHashable: Any] = ["place_id": "places/abc123"]
        XCTAssertNil(AddressSuggestion.decodedObject(fromAPIResponse: dict))
    }

    func testReturnsNilForMissingTitle() {
        let dict: [AnyHashable: Any] = ["display_data": ["subtitle": "New York, NY", "matches": []]]
        XCTAssertNil(AddressSuggestion.decodedObject(fromAPIResponse: dict))
    }

    func testReturnsNilForMissingSubtitle() {
        let dict: [AnyHashable: Any] = ["display_data": ["title": "123 Main St", "matches": []]]
        XCTAssertNil(AddressSuggestion.decodedObject(fromAPIResponse: dict))
    }

    // MARK: - Match ranges

    func testMatchRangeFromEndOffsetOnly() {
        let suggestion = AddressSuggestion.decodedObject(fromAPIResponse:
            makeSuggestionDict(title: "123 Main St", subtitle: "New York, NY", endOffset: 3, placeID: nil)
        )!
        XCTAssertEqual(suggestion.matches.count, 1)
        XCTAssertEqual(suggestion.matches[0], NSRange(location: 0, length: 3))
    }

    func testMatchRangeFromStartAndEndOffset() {
        let dict: [AnyHashable: Any] = [
            "display_data": [
                "title": "123 Main St",
                "subtitle": "New York, NY",
                "matches": [["start_offset": 4, "end_offset": 8]],
            ],
        ]
        let suggestion = AddressSuggestion.decodedObject(fromAPIResponse: dict)!
        XCTAssertEqual(suggestion.matches.count, 1)
        XCTAssertEqual(suggestion.matches[0], NSRange(location: 4, length: 4))
    }

    func testMultipleMatchRanges() {
        let dict: [AnyHashable: Any] = [
            "display_data": [
                "title": "123 Main St",
                "subtitle": "New York, NY",
                "matches": [
                    ["end_offset": 3],
                    ["start_offset": 4, "end_offset": 8],
                ],
            ],
        ]
        let suggestion = AddressSuggestion.decodedObject(fromAPIResponse: dict)!
        XCTAssertEqual(suggestion.matches.count, 2)
        XCTAssertEqual(suggestion.matches[0], NSRange(location: 0, length: 3))
        XCTAssertEqual(suggestion.matches[1], NSRange(location: 4, length: 4))
    }

    func testMatchMissingEndOffsetIsSkipped() {
        let dict: [AnyHashable: Any] = [
            "display_data": [
                "title": "123 Main St",
                "subtitle": "New York, NY",
                "matches": [["start_offset": 0]],
            ],
        ]
        let suggestion = AddressSuggestion.decodedObject(fromAPIResponse: dict)!
        XCTAssertEqual(suggestion.matches.count, 0)
    }

    // MARK: - AddressSearchResult conformance

    func testTitleHighlightRangesMatchMatches() {
        let suggestion = AddressSuggestion.decodedObject(fromAPIResponse:
            makeSuggestionDict(title: "123 Main St", subtitle: "New York, NY", endOffset: 3, placeID: nil)
        )!
        XCTAssertEqual(suggestion.titleHighlightRanges.count, 1)
        XCTAssertEqual(suggestion.titleHighlightRanges[0].rangeValue, NSRange(location: 0, length: 3))
    }

    func testSubtitleHighlightRangesAreEmpty() {
        let suggestion = AddressSuggestion.decodedObject(fromAPIResponse:
            makeSuggestionDict(title: "123 Main St", subtitle: "New York, NY", endOffset: 3, placeID: nil)
        )!
        XCTAssertTrue(suggestion.subtitleHighlightRanges.isEmpty)
    }

    // MARK: - Helpers

    private func makeSuggestionDict(title: String, subtitle: String, endOffset: Int, placeID: String?) -> [AnyHashable: Any] {
        var dict: [AnyHashable: Any] = [
            "display_data": [
                "title": title,
                "subtitle": subtitle,
                "matches": [["end_offset": endOffset]],
            ],
        ]
        if let placeID {
            dict["place_id"] = placeID
        }
        return dict
    }
}
