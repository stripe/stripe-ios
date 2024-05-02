//
//  ScriptMessageHandler.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 5/1/24.
//

import WebKit

/// Convenience class that conforms to WKScriptMessageHandler and can be instantiated with a closure
class ScriptMessageHandler: NSObject, WKScriptMessageHandler {
    let name: String
    let didReceiveMessage: (WKScriptMessage) -> Void

    init(name: String,
         didReceiveMessage: @escaping (WKScriptMessage) -> Void) {
        self.name = name
        self.didReceiveMessage = didReceiveMessage
    }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard message.name == name else {
            debugPrint("Unexpected message name: \(message.name)")
            return
        }

        didReceiveMessage(message)
    }
}
