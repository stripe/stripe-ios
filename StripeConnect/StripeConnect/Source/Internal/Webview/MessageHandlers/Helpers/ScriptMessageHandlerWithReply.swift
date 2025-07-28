//
//  ScriptMessageHandlerWithReply.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 5/1/24.
//

import WebKit

/// Convenience class that conforms to WKScriptMessageHandlerWithReply and can be instantiated with a closure
class ScriptMessageHandlerWithReply<Payload: Decodable, Response: Encodable>: NSObject, WKScriptMessageHandlerWithReply {
    let name: String
    let didReceiveMessage: (Payload) async throws -> Response

    init(name: String,
         didReceiveMessage: @escaping (Payload) async throws -> Response) {
        self.name = name
        self.didReceiveMessage = didReceiveMessage
    }

    @MainActor
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) async -> (Any?, String?) {
        guard message.name == name else {
            return (nil, "Unexpected message")
        }

        // Validate message origin for security
        guard isValidStripeOrigin(message) else {
            return (nil, "Invalid message origin")
        }
        do {
            let payload: Payload = try message.toDecodable()
            let value = try await didReceiveMessage(payload)

            let response = try value.jsonObject(with: .connectEncoder)
            return (response, nil)
        } catch {
            return (nil, (error as NSError).debugDescription)
        }
    }

    /// Validates that the message comes from a trusted Stripe origin
    private func isValidStripeOrigin(_ message: WKScriptMessage) -> Bool {
        guard let securityOrigin = message.frameInfo.securityOrigin else {
            return false
        }

        // Allow messages from Stripe domains
        let allowedHosts = ["connect.stripe.com", "connect-js.stripe.com", "js.stripe.com"]
        return allowedHosts.contains(securityOrigin.host)
    }
}
