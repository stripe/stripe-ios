//
//  AddressAutocompleteModelTests.swift
//  StripePaymentSheetTests
//
//  Created by Joyce Qin on 5/21/26.
//

import XCTest

@testable import StripePaymentSheet

class AddressAutocompleteModelTests: XCTestCase {

    // MARK: - AddressAutocompleteResponse

    func testDecodesResponse() {
        let response: [AnyHashable: Any] = [
            "source": "google",
            "suggestions": [makeSuggestionDict(title: "123 Main St", subtitle: "New York, NY", endOffset: 3, placeId: "places/abc123")],
        ]
        let result = AddressAutocompleteResponse.decodedObject(fromAPIResponse: response)
        XCTAssertEqual(result?.source, "google")
        XCTAssertEqual(result?.suggestions.count, 1)
    }

    func testDecodesMultipleSuggestions() {
        let response: [AnyHashable: Any] = [
            "source": "google",
            "suggestions": [
                makeSuggestionDict(title: "123 Main St", subtitle: "New York, NY", endOffset: 3, placeId: nil),
                makeSuggestionDict(title: "456 Oak Ave", subtitle: "Brooklyn, NY", endOffset: 3, placeId: nil),
            ],
        ]
        XCTAssertEqual(AddressAutocompleteResponse.decodedObject(fromAPIResponse: response)?.suggestions.count, 2)
    }

    func testSkipsInvalidSuggestions() {
        let response: [AnyHashable: Any] = [
            "source": "google",
            "suggestions": [
                makeSuggestionDict(title: "123 Main St", subtitle: "New York, NY", endOffset: 3, placeId: nil),
                ["invalid": "data"],
            ],
        ]
        XCTAssertEqual(AddressAutocompleteResponse.decodedObject(fromAPIResponse: response)?.suggestions.count, 1)
    }

    func testReturnsNilForMissingSource() {
        let response: [AnyHashable: Any] = ["suggestions": []]
        XCTAssertNil(AddressAutocompleteResponse.decodedObject(fromAPIResponse: response))
    }

    func testReturnsNilForMissingSuggestions() {
        let response: [AnyHashable: Any] = ["source": "google"]
        XCTAssertNil(AddressAutocompleteResponse.decodedObject(fromAPIResponse: response))
    }

    func testReturnsNilForNilResponse() {
        XCTAssertNil(AddressAutocompleteResponse.decodedObject(fromAPIResponse: nil))
    }

    // MARK: - AddressSuggestion fields

    func testDecodesSuggestionFields() {
        let suggestion = AddressSuggestion.decodedObject(fromAPIResponse:
            makeSuggestionDict(title: "123 Main St", subtitle: "New York, NY", endOffset: 3, placeId: "places/abc123")
        )
        XCTAssertEqual(suggestion?.title, "123 Main St")
        XCTAssertEqual(suggestion?.subtitle, "New York, NY")
        XCTAssertEqual(suggestion?.placeId, "places/abc123")
    }

    func testDecodesSuggestionWithNilPlaceId() {
        let suggestion = AddressSuggestion.decodedObject(fromAPIResponse:
            makeSuggestionDict(title: "123 Main St", subtitle: "New York, NY", endOffset: 3, placeId: nil)
        )
        XCTAssertNotNil(suggestion)
        XCTAssertNil(suggestion?.placeId)
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

    func testReturnsNilForMissingMatches() {
        let dict: [AnyHashable: Any] = ["display_data": ["title": "123 Main St", "subtitle": "New York, NY"]]
        XCTAssertNil(AddressSuggestion.decodedObject(fromAPIResponse: dict))
    }

    // MARK: - Match ranges

    func testMatchRangeFromEndOffsetOnly() {
        let suggestion = AddressSuggestion.decodedObject(fromAPIResponse:
            makeSuggestionDict(title: "123 Main St", subtitle: "New York, NY", endOffset: 3, placeId: nil)
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

    func testMatchRangeWithNonBMPCharacterBefore() {
        // 😀 is outside the BMP: 1 code point but 2 UTF-16 code units.
        // Title: "😀 Main St" — code point offsets: 😀(0), space(1), M(2)...
        // A match at code points [2, 6) should map to UTF-16 [3, 7), not [2, 6).
        let dict: [AnyHashable: Any] = [
            "display_data": [
                "title": "😀 Main St",
                "subtitle": "New York, NY",
                "matches": [["start_offset": 2, "end_offset": 6]],
            ],
        ]
        let suggestion = AddressSuggestion.decodedObject(fromAPIResponse: dict)!
        XCTAssertEqual(suggestion.matches.count, 1)
        XCTAssertEqual(suggestion.matches[0], NSRange(location: 3, length: 4))
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

    // MARK: - address field

    func testDecodesAddress() {
        let dict = makeSuggestionDict(title: "123 Main St", subtitle: "New York, NY", endOffset: 3, placeId: nil, address: [
            "line1": "123 Main St",
            "line2": "Apt 4",
            "city": "New York",
            "state": "NY",
            "postal_code": "10001",
            "country": "US",
        ])
        let suggestion = AddressSuggestion.decodedObject(fromAPIResponse: dict)!
        XCTAssertEqual(suggestion.address?.line1, "123 Main St")
        XCTAssertEqual(suggestion.address?.line2, "Apt 4")
        XCTAssertEqual(suggestion.address?.city, "New York")
        XCTAssertEqual(suggestion.address?.state, "NY")
        XCTAssertEqual(suggestion.address?.postalCode, "10001")
        XCTAssertEqual(suggestion.address?.country, "US")
    }

    func testAddressIsNilWhenAbsent() {
        let suggestion = AddressSuggestion.decodedObject(fromAPIResponse:
            makeSuggestionDict(title: "123 Main St", subtitle: "New York, NY", endOffset: 3, placeId: nil)
        )!
        XCTAssertNil(suggestion.address)
    }

    func testAddressFieldsAreOptional() {
        let dict = makeSuggestionDict(title: "123 Main St", subtitle: "New York, NY", endOffset: 3, placeId: nil, address: [
            "line1": "123 Main St",
        ])
        let suggestion = AddressSuggestion.decodedObject(fromAPIResponse: dict)!
        XCTAssertEqual(suggestion.address?.line1, "123 Main St")
        XCTAssertNil(suggestion.address?.line2)
        XCTAssertNil(suggestion.address?.city)
        XCTAssertNil(suggestion.address?.state)
        XCTAssertNil(suggestion.address?.postalCode)
        XCTAssertNil(suggestion.address?.country)
    }

    // MARK: - AddressSearchResult conformance

    func testTitleHighlightRangesMatchMatches() {
        let suggestion = AddressSuggestion.decodedObject(fromAPIResponse:
            makeSuggestionDict(title: "123 Main St", subtitle: "New York, NY", endOffset: 3, placeId: nil)
        )!
        XCTAssertEqual(suggestion.titleHighlightRanges.count, 1)
        XCTAssertEqual(suggestion.titleHighlightRanges[0].rangeValue, NSRange(location: 0, length: 3))
    }

    func testSubtitleHighlightRangesAreEmpty() {
        let suggestion = AddressSuggestion.decodedObject(fromAPIResponse:
            makeSuggestionDict(title: "123 Main St", subtitle: "New York, NY", endOffset: 3, placeId: nil)
        )!
        XCTAssertTrue(suggestion.subtitleHighlightRanges.isEmpty)
    }

    // MARK: - AddressDetailsResponse decoding

    func testAddressDetailsResponseDecodesAllAddressFields() {
        let response: [AnyHashable: Any] = [
            "address": [
                "line1": "354 Oyster Point Boulevard",
                "line2": "Suite 100",
                "city": "South San Francisco",
                "state": "CA",
                "postal_code": "94080",
                "country": "US",
            ],
        ]
        let result = AddressDetailsResponse.decodedObject(fromAPIResponse: response)
        XCTAssertEqual(result?.address.line1, "354 Oyster Point Boulevard")
        XCTAssertEqual(result?.address.line2, "Suite 100")
        XCTAssertEqual(result?.address.city, "South San Francisco")
        XCTAssertEqual(result?.address.state, "CA")
        XCTAssertEqual(result?.address.postalCode, "94080")
        XCTAssertEqual(result?.address.country, "US")
    }

    func testAddressDetailsResponseAddressFieldsAreOptional() {
        let response: [AnyHashable: Any] = [
            "address": ["line1": "354 Oyster Point Boulevard"],
        ]
        let result = AddressDetailsResponse.decodedObject(fromAPIResponse: response)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.address.line1, "354 Oyster Point Boulevard")
        XCTAssertNil(result?.address.line2)
        XCTAssertNil(result?.address.city)
        XCTAssertNil(result?.address.state)
        XCTAssertNil(result?.address.postalCode)
        XCTAssertNil(result?.address.country)
    }

    func testAddressDetailsResponseReturnsNilForMissingAddressKey() {
        let response: [AnyHashable: Any] = ["other": "data"]
        XCTAssertNil(AddressDetailsResponse.decodedObject(fromAPIResponse: response))
    }

    func testAddressDetailsResponseReturnsNilForNilResponse() {
        XCTAssertNil(AddressDetailsResponse.decodedObject(fromAPIResponse: nil))
    }

    // MARK: - AddressSuggestion.asAddress

    func testAsAddress_withEmbeddedAddress_deliversAddress() {
        let dict = makeSuggestionDict(
            title: "354 Oyster Point Blvd",
            subtitle: "South San Francisco, CA",
            endOffset: 3,
            placeId: "places/abc123",
            address: ["line1": "354 Oyster Point Boulevard", "city": "South San Francisco"]
        )
        let suggestion = AddressSuggestion.decodedObject(fromAPIResponse: dict)!

        var result: PaymentSheet.Address?
        suggestion.asAddress { result = $0 }

        XCTAssertEqual(result?.line1, "354 Oyster Point Boulevard")
        XCTAssertEqual(result?.city, "South San Francisco")
    }

    func testAsAddress_withNoEmbeddedAddress_returnsNil() {
        let suggestion = AddressSuggestion.decodedObject(fromAPIResponse:
            makeSuggestionDict(title: "123 Main St", subtitle: "New York, NY", endOffset: 3, placeId: "places/abc123")
        )!

        var result: PaymentSheet.Address? = PaymentSheet.Address()
        suggestion.asAddress { result = $0 }
        XCTAssertNil(result)
    }

    // MARK: - Helpers

    private func makeSuggestionDict(title: String, subtitle: String, endOffset: Int, placeId: String?, address: [AnyHashable: Any]? = nil) -> [AnyHashable: Any] {
        var dict: [AnyHashable: Any] = [
            "display_data": [
                "title": title,
                "subtitle": subtitle,
                "matches": [["end_offset": endOffset]],
            ],
        ]
        if let placeId {
            dict["place_id"] = placeId
        }
        if let address {
            dict["address"] = address
        }
        return dict
    }
}
