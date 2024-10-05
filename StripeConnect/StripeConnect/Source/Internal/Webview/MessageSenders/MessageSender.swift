//
//  MessageSender.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/2/24.
//

import Foundation

struct MessageSenderError: Error { }

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
            throw MessageSenderError()
        }
        return "window.\(name)(\(jsonString));"
    }
}
