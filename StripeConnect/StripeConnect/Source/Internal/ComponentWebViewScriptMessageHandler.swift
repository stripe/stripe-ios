//
//  ComponentWebViewMessageHandler.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 5/1/24.
//

import WebKit

/// Helper that wraps WKScriptMessageHandler
protocol ComponentWebViewScriptMessageHandler: WKScriptMessageHandler {
    /// Messages with these names in JS will be handled by this handler
    associatedtype MessageHandler: RawRepresentable, CaseIterable where MessageHandler.RawValue == String

    ///
    func didReceiveMessage(_ handler: MessageHandler, body: Any)
}

extension ComponentWebViewScriptMessageHandler {
    /// Registers all messenger handlers with given WKUserContentController
    func register(_ userContentController: WKUserContentController) {
        MessageHandler.allCases.forEach { handler in
            userContentController.add(self, name: handler.rawValue)
        }
    }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard let handler = MessageHandler(rawValue: message.name) else {
            debugPrint("Unrecognized handler \(message.name)")
            return
        }

        didReceiveMessage(handler, body: message.body)
    }
}

/// Helper that wraps WKScriptMessageHandlerWithReply

protocol ComponentWebViewScriptMessageHandlerWithReply: WKScriptMessageHandlerWithReply {
    associatedtype MessageHandlerWithReply: RawRepresentable, CaseIterable where MessageHandlerWithReply.RawValue == String

    func didReceiveMessage(_ handler: MessageHandlerWithReply, body: Any) async throws -> Any?
}

extension ComponentWebViewScriptMessageHandlerWithReply {

    func register(_ userContentController: WKUserContentController) {
        MessageHandlerWithReply.allCases.forEach { handler in
            userContentController.addScriptMessageHandler(self, contentWorld: .page, name: handler.rawValue)
        }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) async -> (Any?, String?) {
        guard let handler = MessageHandlerWithReply(rawValue: message.name) else {
            debugPrint("Unrecognized handler \(message.name)")
            return (nil, "Unexpected message received")
        }
        do {
            let result = try await didReceiveMessage(handler, body: message.body)
            return (result, nil)
        } catch {
            return (nil, error.localizedDescription)
        }
    }
}
