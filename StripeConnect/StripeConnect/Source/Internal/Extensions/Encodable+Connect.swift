//
//  Encodable+Connect.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 10/4/24.
//

import Foundation

private enum JSONSerializationError: Int, Error {
    /// The encoded object was expected to be a dictionary but turned out to be a single value
    case expectedDictionary = 0
}

extension Encodable {
    /// Encodes to a JSON serialized object with the given encoder and options
    func jsonObject(
        with encoder: JSONEncoder
    ) throws -> Any {
        let data = try encoder.encode(self)
        return try JSONSerialization.jsonObject(with: data, options: .allowFragments)
    }

    /// Encodes to a JSON dictionary with the given encoder
    func jsonDictionary(with encoder: JSONEncoder) throws -> [String: Any] {
        let json = try jsonObject(with: encoder)
        guard let dict = json as? [String: Any] else {
            throw JSONSerializationError.expectedDictionary
        }
        return dict
    }
}
