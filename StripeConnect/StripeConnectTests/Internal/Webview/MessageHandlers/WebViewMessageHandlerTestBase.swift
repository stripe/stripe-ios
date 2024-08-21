//
//  WebViewMessageHandlerTestBase.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/13/24.
//

@testable import StripeConnect
import XCTest
import WebKit

class ScriptMessageHandlerTestBase: XCTestCase {
    
    var webView: WKWebView!
    
    override func setUp() {
        super.setUp()
        webView = WKWebView(frame: .zero, configuration: .init())
    }
    
    func addMessageHandler<T>(messageHandler: ScriptMessageHandler<T>) {
        webView.configuration.userContentController.add(messageHandler, name: messageHandler.name)
    }
    
    struct Reply<R: Decodable>: Decodable {
        let result: R
    }
    
    func addMessageReplyHandler<Payload, Response>(messageHandler: ScriptMessageHandlerWithReply<Payload, Response>, verifyResult: @escaping (Response) -> Void) {
        addMessageHandler(messageHandler: .init(name: replyKey(message: messageHandler.name), didReceiveMessage: { (message: Reply<Response>) in
            verifyResult(message.result)
        }))
        
        webView.configuration.userContentController.addScriptMessageHandler(messageHandler, contentWorld: .page, name: messageHandler.name)
    }
    
    override func tearDown() {
        webView = nil
        super.tearDown()
    }
    
    func evaluateMessage(name: String,
                         json: String,
                         completionHandler: ((Any?, (any Error)?) -> Void)? = nil) {
        let script = """
        window.webkit.messageHandlers.\(name).postMessage(JSON.stringify(\(json)));
        """
        
        webView.evaluateJavaScript(script, completionHandler: completionHandler)
    }
    
    @discardableResult
    func evaluateMessageWithReply(name: String,
                                  json: String,
                                  completionHandler: ((Any?, (any Error)?) -> Void)? = nil) async throws -> Any? {
        let script = """
                    const message = {text: "Hello, World!"};
                    const result = await window.webkit.messageHandlers.\(name).postMessage(JSON.stringify(\(json)));
                    window.webkit.messageHandlers.\(replyKey(message: name)).postMessage(JSON.stringify({"result": result}));
                """
        return try await webView.callAsyncJavaScript(script, contentWorld: .page)
    }
    
    func replyKey(message: String) -> String {
        message + "_reply"
    }
}
