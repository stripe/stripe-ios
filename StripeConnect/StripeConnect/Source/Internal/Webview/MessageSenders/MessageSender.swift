//
//  MessageSender.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/2/24.
//

import Foundation

/// Sends a message to the webview by calling a function on `window`
protocol MessageSender {
    associatedtype Payload: Encodable
    /// Name of the method (e.g. `updateConnectInstance`)
    var name: String { get }
    /// Function param
    var payload: Payload { get }
}

extension MessageSender {
    var javascriptMessage: String? {
        guard let jsonData = try? JSONEncoder.connectEncoder.encode(payload),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            //TODO: MXMOBILE-2491 Log failure to analytics
            return nil
        }
        return "window.\(name)(\(jsonString));"
    }
}
