//
//  MessageSender.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/2/24.
//

import Foundation

/// Sends a message to the webview by calling a function on `window`
protocol MessageSender {
    associatedtype Payload: Codable & Equatable
    /// Name of the method (e.g. `updateConnectInstance`)
    var name: String { get }
    /// Function param
    var payload: Payload { get }
}

extension MessageSender {
    var javascriptMessage: String? {
        let encoder = JSONEncoder()
        // Ensure keys are sorted for test stability.
        encoder.outputFormatting = .sortedKeys
        guard let jsonData = try? encoder.encode(payload),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            //TODO: MXMOBILE-2491 Log failure to analytics
            return nil
        }
        return "window.\(name)(\(jsonString));"
    }
}
