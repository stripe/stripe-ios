//
//  AutocompleteResponse.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 4/20/26.
//

import Foundation

private extension String {
    /// Converts a half-open code-point range [start, end) to an NSRange of UTF-16 code units.
    /// The Google API returns zero based Unicode character offsets, which could theoretically include non-BMP characters
    /// `highlightSearchString` uses NSAttributedString, which is UTF-16, so we convert to get the correct range
    func utf16Range(fromCodePointOffsets start: Int, to end: Int) -> NSRange? {
        let scalars = unicodeScalars
        guard
            let startIndex = scalars.index(scalars.startIndex, offsetBy: start, limitedBy: scalars.endIndex),
            let endIndex = scalars.index(scalars.startIndex, offsetBy: end, limitedBy: scalars.endIndex)
        else { return nil }
        return NSRange(startIndex..<endIndex, in: self)
    }
}

class AutocompleteResponse: NSObject {

    /// The list of autocomplete suggestions
    let suggestions: [AddressSuggestion]

    /// The source of the autocomplete response (e.g. "google")
    let source: String

    /// The raw API response used to create this object.
    let allResponseFields: [AnyHashable: Any]

    private init(
        suggestions: [AddressSuggestion],
        source: String,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.suggestions = suggestions
        self.source = source
        self.allResponseFields = allResponseFields
    }
}

// MARK: - STPAPIResponseDecodable
extension AutocompleteResponse: STPAPIResponseDecodable {
    static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response,
              let suggestionsDict = dict["suggestions"] as? [[AnyHashable: Any]],
              let source = dict["source"] as? String
        else {
            return nil
        }

        let suggestions = suggestionsDict.compactMap { AddressSuggestion.decodedObject(fromAPIResponse: $0) }

        return AutocompleteResponse(
            suggestions: suggestions,
            source: source,
            allResponseFields: dict
        ) as? Self
    }
}

class AddressSuggestion: NSObject {

    /// The title text to display in the address suggestion.
    let title: String

    /// The subtitle text to display in the address suggestion.
    let subtitle: String

    /// The ranges to bold, as NSRanges over UTF-16 code units.
    let matches: [NSRange]

    /// The place id for fetching full address details.
    let placeId: String?

    /// The pre-filled address components, if returned by the API.
    let address: PaymentSheet.Address?

    /// The raw API response used to create this object.
    let allResponseFields: [AnyHashable: Any]

    private init(
        title: String,
        subtitle: String,
        matches: [NSRange],
        placeId: String?,
        address: PaymentSheet.Address?,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.title = title
        self.subtitle = subtitle
        self.matches = matches
        self.placeId = placeId
        self.address = address
        self.allResponseFields = allResponseFields
    }
}

// MARK: - AddressSearchResult
extension AddressSuggestion: AddressSearchResult {
    var titleHighlightRanges: [NSValue] {
        return matches.map { NSValue(range: $0) }
    }

    var subtitleHighlightRanges: [NSValue] {
        return []
    }

    func asAddress(apiClient: STPAPIClient?, source: String?, sessionToken: String?, apiKey: String?, completion: @escaping (PaymentSheet.Address?) -> Void) {
        if let address {
            completion(address)
        }
        guard let apiClient,
                  let placeId,
                  let source,
                  let sessionToken else {
                      completion(nil)
                      return
        }
        Task { @MainActor in
            do {
                completion(try await apiClient.details(placeId: placeId, source: source, displayTitle: title, sessionToken: sessionToken, apiKey: apiKey).address)
            } catch {
                completion(nil)
            }
        }
    }
}

// MARK: - STPAPIResponseDecodable
extension AddressSuggestion: STPAPIResponseDecodable {
    static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response,
              let displayData = dict["display_data"] as? [AnyHashable: Any],
              let title = displayData["title"] as? String,
              let subtitle = displayData["subtitle"] as? String,
              let matchesDict = displayData["matches"] as? [[AnyHashable: Any]]
        else {
            return nil
        }

        let matches: [NSRange] = matchesDict.compactMap { matchDict in
            guard let endOffset = matchDict["end_offset"] as? Int else { return nil }
            let startOffset = matchDict["start_offset"] as? Int ?? 0
            return title.utf16Range(fromCodePointOffsets: startOffset, to: endOffset)
        }

        let address = (dict["address"] as? [AnyHashable: Any]).map {
            PaymentSheet.Address(
                city: $0["city"] as? String,
                country: $0["country"] as? String,
                line1: $0["line1"] as? String,
                line2: $0["line2"] as? String,
                postalCode: $0["postal_code"] as? String,
                state: $0["state"] as? String
            )
        }

        return AddressSuggestion(
            title: title,
            subtitle: subtitle,
            matches: matches,
            placeId: dict["place_id"] as? String,
            address: address,
            allResponseFields: dict
        ) as? Self
    }
}

class DetailsResponse: NSObject {

    /// The pre-filled address components.
    let address: PaymentSheet.Address

    /// The raw API response used to create this object.
    let allResponseFields: [AnyHashable: Any]

    private init(
        address: PaymentSheet.Address,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.address = address
        self.allResponseFields = allResponseFields
    }
}

// MARK: - STPAPIResponseDecodable
extension DetailsResponse: STPAPIResponseDecodable {
    static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response,
              let addressDict = dict["address"] as? [AnyHashable: Any]
        else {
            return nil
        }

        let address = PaymentSheet.Address(
            city: addressDict["city"] as? String,
            country: addressDict["country"] as? String,
            line1: addressDict["line1"] as? String,
            line2: addressDict["line2"] as? String,
            postalCode: addressDict["postal_code"] as? String,
            state: addressDict["state"] as? String
        )

        return DetailsResponse(
            address: address,
            allResponseFields: dict
        ) as? Self
    }
}
