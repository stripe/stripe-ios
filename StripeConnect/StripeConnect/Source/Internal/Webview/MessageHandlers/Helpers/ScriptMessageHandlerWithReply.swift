//
//  ScriptMessageHandlerWithReply.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 5/1/24.
//

@_spi(STP) import StripeCore
import WebKit

/// Convenience class that conforms to WKScriptMessageHandlerWithReply and can be instantiated with a closure
class ScriptMessageHandlerWithReply<Payload: Decodable, Response: Encodable>: NSObject, WKScriptMessageHandlerWithReply {
    let name: String
    let sourcePolicy: STPWebMessageSourcePolicy
    let didReceiveMessage: (Payload) async throws -> Response

    init(name: String,
         sourcePolicy: STPWebMessageSourcePolicy,
         didReceiveMessage: @escaping (Payload) async throws -> Response) {
        self.name = name
        self.sourcePolicy = sourcePolicy
        self.didReceiveMessage = didReceiveMessage
    }

    @MainActor
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) async -> (Any?, String?) {
        guard message.name == name else {
            debugPrint("Unexpected message name: \(message.name)")
            return (nil, "Unexpected message")
        }
        guard sourcePolicy.isAuthorized(source: message.webView,
                                        scheme: message.frameInfo.securityOrigin.protocol,
                                        host: message.frameInfo.securityOrigin.host,
                                        port: message.frameInfo.securityOrigin.port) else {
            return (nil, "Invalid message origin")
        }
        do {
            let payload: Payload = try message.toDecodable()
            let value = try await didReceiveMessage(payload)

            let response = try value.jsonObject(with: .connectEncoder)
            return (response, nil)
        } catch {
            debugPrint("Error processing message: \((error as NSError).debugDescription)")
            return (nil, (error as NSError).debugDescription)
        }
    }
}
