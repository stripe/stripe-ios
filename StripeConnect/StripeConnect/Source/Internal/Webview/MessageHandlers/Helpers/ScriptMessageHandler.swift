//
//  ScriptMessageHandler.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 5/1/24.
//

import WebKit

/// Convenience class that conforms to WKScriptMessageHandler and can be instantiated with a closure
class ScriptMessageHandler<Payload: Decodable>: NSObject, WKScriptMessageHandler {
    let name: String
    let didReceiveMessage: (Payload) -> Void
    let analyticsClient: ComponentAnalyticsClient

    init(name: String,
         analyticsClient: ComponentAnalyticsClient,
         didReceiveMessage: @escaping (Payload) -> Void) {
        self.name = name
        self.didReceiveMessage = didReceiveMessage
        self.analyticsClient = analyticsClient
    }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard message.name == name else {
            // TODO: MXMOBILE-2491 Log as analytics
            debugPrint("Unexpected message name: \(message.name)")
            return
        }
        do {
            didReceiveMessage(try message.toDecodable())
        } catch {
            analyticsClient.logDeserializeMessageErrorEvent(message: message.name, error: error)
            debugPrint("[StripeConnect] Failed to decode body for message with name: \(message.name) \(error.localizedDescription)")
        }
    }
}
