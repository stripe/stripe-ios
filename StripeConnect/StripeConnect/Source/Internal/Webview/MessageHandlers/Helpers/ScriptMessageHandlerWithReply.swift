//
//  ScriptMessageHandlerWithReply.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 5/1/24.
//

import WebKit

/// Convenience class that conforms to WKScriptMessageHandlerWithReply and can be instantiated with a closure
class ScriptMessageHandlerWithReply<Payload: Decodable, Response: Codable>: NSObject, WKScriptMessageHandlerWithReply {
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
            debugPrint("Unexpected message name: \(message.name)")
            return (nil, "Unexpected message")
        }
        guard
            let bodyData = (message.body as? String)?.data(using: .utf8),
            let body = try? JSONDecoder().decode(Payload.self, from: bodyData) else {
            //TODO: MXMOBILE-2491 Log as analytics
            debugPrint("Failed to decode body for message with name: \(message.name)")
            return (nil, "Failed to decode body for message")
        }
        do {
            let value = try await didReceiveMessage(body)
            let data = try JSONEncoder().encode(value)
            guard let response = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else {
                return (nil, "Failed to decode body")
            }
            return (response, nil)
        } catch {
            return (nil, error.localizedDescription)
        }
    }
}
