//
//  JSONEncoder+extension.swift
//  StripeConnect
//
//  Created by Chris Mays on 9/4/24.
//

import Foundation

extension JSONEncoder {
    /// Encoder used for JS Messaging and URL param encoding
    static let connectEncoder = makeConnectEncoder()

    static func makeConnectEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        // Ensure keys are sorted for test stability.
        encoder.outputFormatting = .sortedKeys
        return encoder
    }

    /// Encoder used for analytics
    static let analyticsEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .secondsSince1970
        return encoder
    }()
}
