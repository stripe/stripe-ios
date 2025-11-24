//
//  URL+LinkBankPaymentMethod.swift
//  StripeCore
//
//  Created by Mat Schmid on 2025-11-24.
//

import Foundation

@_spi(STP) public extension URL {
    enum LinkBankPaymentMethodError: Error {
        case failedToBase64Decode
    }

    /// Extracts and decodes a `LinkBankPaymentMethod` from URL query parameters.
    ///
    /// The URL is expected to contain a base64-encoded payment method in the `payment_method` parameter.
    ///
    /// - Returns: The decoded `LinkBankPaymentMethod`, or `nil` if the `payment_method` parameter is not present.
    /// - Throws: `LinkBankPaymentMethodError.failedToBase64Decode` if base64 decoding fails, or a `DecodingError` if JSON decoding fails.
    func extractLinkBankPaymentMethod() throws -> LinkBankPaymentMethod? {
        guard let encodedPaymentMethod = extractQueryValue(forKey: "payment_method") else {
            return nil
        }

        guard let data = Data(base64Encoded: encodedPaymentMethod) else {
            throw LinkBankPaymentMethodError.failedToBase64Decode
        }

        return try StripeJSONDecoder().decode(LinkBankPaymentMethod.self, from: data)
    }

    /// Extracts a query parameter value from the URL.
    ///
    /// - Parameter key: The query parameter key to extract.
    /// - Returns: The decoded value, or `nil` if the parameter is not present.
    func extractQueryValue(forKey key: String) -> String? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            assertionFailure("Invalid URL")
            return nil
        }
        return components
            .queryItems?
            .first(where: { $0.name == key })?
            .value?
            .removingPercentEncoding
    }
}
