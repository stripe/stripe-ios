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
    
    init(name: String,
         didReceiveMessage: @escaping (Payload) -> Void) {
        self.name = name
        self.didReceiveMessage = didReceiveMessage
    }
    
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard message.name == name else {
            debugPrint("Unexpected message name: \(message.name)")
            return
        }
        do {
            didReceiveMessage(try message.toDecodable())
        } catch {
            //TODO: MXMOBILE-2491 Log as analytics
            debugPrint("Failed to decode body for message with name: \(message.name) \(error.localizedDescription)")
        }
    }
}
