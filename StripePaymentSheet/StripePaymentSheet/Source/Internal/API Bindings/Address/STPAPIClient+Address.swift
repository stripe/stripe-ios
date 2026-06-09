//
//  STPAPIClient+Address.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 6/4/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

// MARK: - Address Autocomplete

extension STPAPIClient {
    /// Fetches autocomplete suggestions.
    /// - Parameters:
    ///   - searchText: The search text.
    ///   - locale: The BCP 47 language tag for the locale to use. Defaults to the device locale.
    ///   - countryCodes: The countries to restrict the results to, from the country selector.
    ///   - sessionToken: The session identifier that groups the autocomplete requests together to be billed together.
    func getAddressSuggestions(
        searchText: String,
        locale: String = Locale.current.toLanguageTag(),
        countryCodes: [String]?,
        sessionToken: String,
        apiKey: String? = nil
    ) async throws -> AddressAutocompleteResponse {
        let endpoint = "\(APIEndpointElementsAddress)/autocomplete"
        var parameters: [String: Any] = [
            "search_text": searchText,
            "locale": locale,
            "session_token": sessionToken,
            "client_type": "mobile",
        ]
        if let countryCodes {
            parameters["country_codes[]"] = Set<AnyHashable>(countryCodes)
        }
        if let apiKey {
            parameters["api_key"] = apiKey
        }
        return try await APIRequest<AddressAutocompleteResponse>.post(
            with: self,
            endpoint: endpoint,
            parameters: parameters
        )
    }

    /// Fetches address details.
    /// - Parameters:
    ///   - placeId: The id of the autocomplete suggestion selected.
    ///   - source: The source of the autocomplete suggestion selected.
    ///   - locale: The BCP 47 language tag for the locale to use. Defaults to the device locale.
    ///   - displayTitle: The displayed title from the autocomplete suggestion selected.
    ///   - sessionToken: The session identifier that groups the autocomplete requests together to be billed together.
    func getAddressDetails(
        placeId: String,
        source: String,
        locale: String = Locale.current.toLanguageTag(),
        displayTitle: String,
        sessionToken: String,
        apiKey: String? = nil
    ) async throws -> AddressDetailsResponse {
        let endpoint = "\(APIEndpointElementsAddress)/details"
        var parameters: [String: Any] = [
            "place_id": placeId,
            "source": source,
            "locale": locale,
            "display_title": displayTitle,
            "session_token": sessionToken,
            "client_type": "mobile",
        ]
        if let apiKey {
            parameters["api_key"] = apiKey
        }
        return try await APIRequest<AddressDetailsResponse>.post(
            with: self,
            endpoint: endpoint,
            parameters: parameters
        )
    }
}

private let APIEndpointElementsAddress = "elements/address"
