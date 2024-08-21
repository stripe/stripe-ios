//
//  MessageSenderTestBase.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/14/24.
//

@testable import StripeConnect
import XCTest
import WebKit

class MessageSenderTestBase: XCTestCase {
    var webView: WKWebView!
    
    override func setUp() {
        super.setUp()
        webView = WKWebView(frame: .zero)
    }
    
    override func tearDown() {
        webView = nil
        super.tearDown()
    }
    
    private class MessageHandler: NSObject, WKScriptMessageHandler {
        var messageReceived: ((Any) -> Void)?
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            messageReceived?(message.body)
        }
    }
    
    func validateMessageSent<Sender: MessageSender>(sender: Sender) throws {
        let jsMessage = try XCTUnwrap(sender.javascriptMessage)
        let expectation = XCTestExpectation(description: "JavaScript execution")
        let messageHandler = MessageHandler()
        messageHandler.messageReceived = { (payload: Any) in
            if let jsonString = payload as? String,
               let data = jsonString.data(using: .utf8),
               let dict = try? JSONDecoder().decode(Sender.Payload.self, from: data) {
                XCTAssertEqual(dict, sender.payload)
                expectation.fulfill()
            }
        }
        
        // Inject the receiver function that validates the message was sent
        let receiverFunctionName = "receiver"
        webView.evaluateJavaScript("""
                window.\(sender.name) = function(message) {
                    window.webkit.messageHandlers.\(receiverFunctionName).postMessage(JSON.stringify(message));
                };
            """)
        webView.configuration.userContentController.add(messageHandler, name: receiverFunctionName)
        
        webView.evaluateJavaScript(jsMessage) { (result, error) in
            if let error {
                XCTFail("JavaScript execution failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}
