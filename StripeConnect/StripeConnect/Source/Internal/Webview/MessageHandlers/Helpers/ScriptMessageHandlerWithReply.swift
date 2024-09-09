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
            debugPrint("Unexpected message name: \(message.name)")
            return (nil, "Unexpected message")
        }
        do {
            let payload: Payload = try message.toDecodable()
            let value = try await didReceiveMessage(payload)
            let responseData = try JSONEncoder.connectEncoder.encode(value)
            
            guard let response = try? JSONSerialization.jsonObject(with: responseData, options: .allowFragments) else {
                return (nil, "Failed to encode response")
            }
            
            return (response, nil)
        } catch {
            debugPrint("Error processing message: \(error.localizedDescription)")
            return (nil, error.localizedDescription)
        }
    }
}
