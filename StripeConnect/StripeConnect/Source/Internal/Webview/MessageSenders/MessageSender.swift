//
//  MessageSender.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/2/24.
//

import Foundation

private enum MessageSenderError: Int, Error {
    /// Error encoding the json to utf-8
    case stringEncoding
}

/// Sends a message to the webview by calling a function on `window`
protocol MessageSender {
    typealias CustomKeyCodingStrategy = (_ keys: [any CodingKey]) -> any CodingKey

    associatedtype Payload: Encodable
    /// Name of the method (e.g. `updateConnectInstance`)
    var name: String { get }
    /// Function param
    var payload: Payload { get }
    /// JSON key-encoding encoding strategy for payload
    var customKeyEncodingStrategy: CustomKeyCodingStrategy? { get }
}

extension MessageSender {
    // Default to nil
    var customKeyEncodingStrategy: CustomKeyCodingStrategy? { nil }
}

extension MessageSender {
    var jsonEncoder: JSONEncoder {
        // Use default encoder unless we should use custom key encoding
        guard let customKeyEncodingStrategy else {
            return .connectEncoder
        }

        let encoder = JSONEncoder.makeConnectEncoder()
        encoder.keyEncodingStrategy = .custom(customKeyEncodingStrategy)
        return encoder
    }

    func jsonData() throws -> Data {
        try jsonEncoder.encode(payload)
    }

    func javascriptMessage() throws -> String {
        guard let jsonString = String(data: try jsonData(), encoding: .utf8) else {
            throw MessageSenderError.stringEncoding
        }
        return "window.\(name)(\(jsonString));"
    }
}
