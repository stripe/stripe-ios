//
//  AutocompleteResponse.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 4/20/26.
//

import Foundation

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

        let suggestions = suggestionsDict.compactMap { suggestionDict in AddressSuggestion.decodedObject(fromAPIResponse: suggestionDict) }

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

    /// The raw API response used to create this object.
    let allResponseFields: [AnyHashable: Any]

    private init(title: String,
                 subtitle: String,
                 matches: [NSRange],
                 allResponseFields: [AnyHashable: Any]
    ) {
        self.title = title
        self.subtitle = subtitle
        self.matches = matches
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

    func asAddress(completion: @escaping (PaymentSheet.Address?) -> Void) {
        // Place details lookup not yet implemented; return nil to fall back to manual entry.
        completion(nil)
    }
}

// MARK: - STPAPIResponseDecodable
extension AddressSuggestion: STPAPIResponseDecodable {
    static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response,
              let title = dict["title"] as? String,
              let subtitle = dict["subtitle"] as? String,
              let matchesDict = dict["matches"] as? [[AnyHashable: Any]]
        else {
            return nil
        }

        let matches: [NSRange] = matchesDict.compactMap { matchDict in
            guard let endOffset = matchDict["endOffset"] as? Int else { return nil }
            let startOffset = matchDict["startOffset"] as? Int ?? 0
            return NSRange(location: startOffset, length: endOffset - startOffset)
        }
        return AddressSuggestion(
            title: title,
            subtitle: subtitle,
            matches: matches,
            allResponseFields: dict
        ) as? Self
    }
}
