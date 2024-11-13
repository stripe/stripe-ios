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
    associatedtype Payload: Encodable
    /// Name of the method (e.g. `updateConnectInstance`)
    var name: String { get }
    /// Function param
    var payload: Payload { get }
}

extension MessageSender {
    func javascriptMessage() throws -> String {
        let jsonData = try JSONEncoder.connectEncoder.encode(payload)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw MessageSenderError.stringEncoding
        }
        return "window.\(name)(\(jsonString));"
    }
}
