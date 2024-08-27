//
//  WebView+Tests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/21/24.
//

@testable import StripeConnect
import UIKit
import WebKit
import XCTest


extension WKWebView {
    
    func evaluateDebugMessage(message: String) {
        evaluateMessage(name: "debug",
                        json: """
                        "\(message)"
                        """)
    }
    
    func evaluateSetOnExit() {
        evaluateMessage(name: "onSetterFunctionCalled",
                        json: """
                        {
                            "setter": "setOnExit"
                        }
                        """)
    }
    
    func evaluateOnLoaderStart(elementTagName: String) {
        evaluateMessage(name: "onSetterFunctionCalled",
                                json: """
                        {
                            "setter": "setOnLoaderStart",
                            "value": {
                                "elementTagName": "\(elementTagName)"
                            }
                        }
                        """)
    }
    
    func evaluatePageDidLoad(pageViewId: String) {
        evaluateMessage(name: "pageDidLoad",
                        json: """
                        {"pageViewId": "\(pageViewId)"}
                        """)
    }
    
    func evaluateAccountSessionClaimed(merchantId: String) {
        evaluateMessage(name: "accountSessionClaimed",
                        json: """
                        {"merchantId": "\(merchantId)"}
                        """)
    }
    
    func evaluateOpenAuthenticatedWebView(url: String, id: String) {
        evaluateMessage(name: "openAuthenticatedWebView",
                        json: """
                        {"url": "\(url)", "id": "\(id)" }
                        """)
    }
    
    func evaluateOnLoadError(type: String, message: String) {
        evaluateMessage(name: "onSetterFunctionCalled",
                        json:
                        """
                        {
                            "setter": "setOnLoadError",
                            "value": {
                                "error": {
                                    "type": "\(type)",
                                    "message": "\(message)"
                                }
                            }
                        }
                        """)
    }
}


extension WKWebView {
    private class MessageHandler: NSObject, WKScriptMessageHandler {
        var messageReceived: ((Any) -> Void)?
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            messageReceived?(message.body)
        }
    }
    
    func expectationForMessageReceived<Sender: MessageSender>(sender: Sender) throws -> XCTestExpectation {
        let expectation = XCTestExpectation(description: "JavaScript execution")
        let messageHandler = MessageHandler()
        messageHandler.messageReceived = { (payload: Any) in
            if let jsonString = payload as? String,
               let data = jsonString.data(using: .utf8),
               let dict = try? JSONDecoder().decode(Sender.Payload.self, from: data) {
                XCTAssertEqual(dict, sender.payload)
                expectation.fulfill()
            } else {
                print("TEST")
            }
        }
        
        // Inject the receiver function that validates the message was sent
        let receiverFunctionName = "receiver_" + sender.name
        evaluateJavaScript("""
            window.\(sender.name) = function(message) {
                window.webkit.messageHandlers.\(receiverFunctionName).postMessage(JSON.stringify(message));
            };
        """)
        configuration.userContentController.add(messageHandler, name: receiverFunctionName)
        return expectation
    }
    
    func sendMessage<Sender: MessageSender>(sender: Sender) throws {
        evaluateJavaScript(try XCTUnwrap(sender.javascriptMessage)) { (result, error) in
            if let error {
                XCTFail("JavaScript execution failed: \(error)")
            }
        }
    }
    
    func evaluateMessage(name: String,
                         json: String,
                         completionHandler: ((Any?, (any Error)?) -> Void)? = nil) {
        let script = """
        window.webkit.messageHandlers.\(name).postMessage(\(json));
        """
        
        evaluateJavaScript(script, completionHandler: completionHandler)
    }
    
    @discardableResult
    func evaluateMessageWithReply(name: String,
                                  json: String,
                                  postReply: Bool = true,
                                  completionHandler: ((Any?, (any Error)?) -> Void)? = nil) async throws -> Any? {
        let script = """
                    const result = await window.webkit.messageHandlers.\(name).postMessage(\(json));
                
                """ + (postReply ?
                """
                    window.webkit.messageHandlers.\(replyKey(message: name)).postMessage({"result": result});
                """ : "")
        return try await callAsyncJavaScript(script, contentWorld: .page)
    }
    
    func addMessageReplyHandler<Payload, Response>(messageHandler: ScriptMessageHandlerWithReply<Payload, Response>, verifyResult: @escaping (Response) -> Void) {
        addMessageHandler(messageHandler: .init(name: replyKey(message: messageHandler.name), didReceiveMessage: { (message: Reply<Response>) in
            verifyResult(message.result)
        }))
        
        configuration.userContentController.addScriptMessageHandler(messageHandler, contentWorld: .page, name: messageHandler.name)
    }
    
    func replyKey(message: String) -> String {
        message + "_reply"
    }
    
    func addMessageHandler<T>(messageHandler: ScriptMessageHandler<T>) {
        configuration.userContentController.add(messageHandler, name: messageHandler.name)
    }
    
    struct Reply<R: Decodable>: Decodable {
        let result: R
    }
}
