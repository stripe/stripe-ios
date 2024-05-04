//
//  ScriptMessageHandlerWithReply.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 5/1/24.
//

import WebKit

/// Convenience class that conforms to WKScriptMessageHandlerWithReply and can be instantiated with a closure
class ScriptMessageHandlerWithReply<T>: NSObject, WKScriptMessageHandlerWithReply {
    let name: String
    let didReceiveMessage: (WKScriptMessage) async throws -> T

    init(name: String,
         didReceiveMessage: @escaping (WKScriptMessage) async throws -> T) {
        self.name = name
        self.didReceiveMessage = didReceiveMessage
    }

    @MainActor
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) async -> (Any?, String?) {
        guard message.name == name else {
            debugPrint("Unexpected message name: \(message.name)")
            return (nil, "Unexpected message")
        }

        do {
            let value = try await didReceiveMessage(message)
            return (value, nil)
        } catch {
            return (nil, error.localizedDescription)
        }
    }
}
