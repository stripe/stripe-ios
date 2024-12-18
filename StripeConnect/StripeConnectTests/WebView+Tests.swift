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

    func evaluateSetOnExit() async throws {
        try await evaluateMessage(name: "onSetterFunctionCalled",
                        json: """
                        {
                            "setter": "setOnExit"
                        }
                        """)
    }

    func evaluateOnLoaderStart(elementTagName: String) async throws {
        try await evaluateMessage(name: "onSetterFunctionCalled",
                                json: """
                                {
                                    "setter": "setOnLoaderStart",
                                    "value": {
                                        "elementTagName": "\(elementTagName)"
                                    }
                                }
                                """)
    }

    func evaluatePageDidLoad(pageViewId: String) async throws {
        try await evaluateMessage(name: "pageDidLoad",
                                  json: """
                                  {"pageViewId": "\(pageViewId)"}
                                  """)
    }

    func evaluateAccountSessionClaimed(merchantId: String) async throws {
        try await evaluateMessage(name: "accountSessionClaimed",
                                  json: """
                                  {"merchantId": "\(merchantId)"}
                                  """)
    }

    func evaluateOpenAuthenticatedWebView(url: String, id: String) async throws {
        try await evaluateMessage(name: "openAuthenticatedWebView",
                                  json: """
                                  {"url": "\(url)", "id": "\(id)" }
                                  """)
    }

    func evaluateOpenFinancialConnectionsWebView(clientSecret: String, id: String, connectedAccountId: String) {
        evaluateMessage(name: "openFinancialConnections",
                        json: """
                        {"clientSecret": "\(clientSecret)", "id": "\(id)",  "connectedAccountId": "\(connectedAccountId)", }
                        """)
    }

    func evaluateOnLoadError(type: String, message: String) async throws {
        try await evaluateMessage(name: "onSetterFunctionCalled",
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

    func expectationForMessageReceived<Sender: MessageSender>(
        sender: Sender,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> XCTestExpectation {
        let expectation = XCTestExpectation(description: "JavaScript execution")
        let messageHandler = MessageHandler()
        messageHandler.messageReceived = { (payload: Any) in
            guard let payloadData = try? JSONSerialization.connectData(withJSONObject: payload) else {
                XCTFail("Failed to encode payload", file: file, line: line)
                return
            }
            guard let responseData = try? sender.jsonData() else {
                XCTFail("Failed to encode response data", file: file, line: line)
                return
            }
            XCTAssertEqual(String(data: responseData, encoding: .utf8), String(data: payloadData, encoding: .utf8), file: file, line: line)
            expectation.fulfill()
        }

        // Inject the receiver function that validates the message was sent
        let receiverFunctionName = "receiver_" + sender.name
        evaluateJavaScript("""
            window.\(sender.name) = function(message) {
                window.webkit.messageHandlers.\(receiverFunctionName).postMessage(message);
            };
        """)
        configuration.userContentController.add(messageHandler, name: receiverFunctionName)
        return expectation
    }

    func sendMessage<Sender: MessageSender>(sender: Sender) throws {
        evaluateJavaScript(try sender.javascriptMessage()) { (_, error) in
            if let error {
                XCTFail("JavaScript execution failed: \(error)")
            }
        }
    }

    @discardableResult
    func evaluateMessage(name: String,
                         json: String) async throws -> Any? {
        return try await withCheckedThrowingContinuation { continuation in
            evaluateMessage(name: name, json: json, completionHandler: { response, _ in
                continuation.resume(returning: response)
            })
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

    func ensureMessagesNotSet(messages: [String],
                              file: StaticString = #filePath,
                              line: UInt = #line) async throws {
        for message in messages {
            do {
                try await self.evaluateMessageWithReply(name: message,
                                                        json: "{}",
                                                        expectedResponse: "",
                                                        file: file,
                                                        line: line)
                XCTFail("\(message) should not be set when it's nil", file: file, line: line)
            } catch {}
        }
    }

    func evaluateMessageWithReply<Response: Encodable>(name: String,
                                                       json: String,
                                                       expectedResponse: Response,
                                                       timeout: TimeInterval = TestHelpers.defaultTimeout,
                                                       file: StaticString = #filePath,
                                                       line: UInt = #line) async throws {
        try await TestHelpers.withTimeout(seconds: timeout) {
            return try await withCheckedThrowingContinuation { continuation in
                let replyMessageHandler = DataScriptMessageHandler(name: self.replyKey(message: name)) { message in
                    let expectedMessage: String?

                    if let expectedResponse = expectedResponse as? String {
                        expectedMessage = expectedResponse
                    } else {
                        guard let json = try? JSONEncoder.connectEncoder.encode(expectedResponse)else {
                            XCTFail("Failed to encode expected response \(expectedResponse)", file: file, line: line)
                            return
                        }
                        expectedMessage = String(data: json, encoding: .utf8)
                    }

                    guard let actualMessage = String(data: message, encoding: .utf8) else {
                        XCTFail("Failed to get message \(message)", file: file, line: line)
                        return
                    }
                    XCTAssertEqual(actualMessage, expectedMessage, file: file, line: line)
                    continuation.resume(returning: ())
                }

                self.configuration.userContentController.add(replyMessageHandler, name: replyMessageHandler.name)

                let script = """
                const result = await window.webkit.messageHandlers.\(name).postMessage(\(json));
                window.webkit.messageHandlers.\(self.replyKey(message: name)).postMessage(result);
                """

                Task {
                    do {
                        _ = try await self.callAsyncJavaScript(script, contentWorld: .page)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    func addMessageReplyHandler<Payload, Response>(messageHandler: ScriptMessageHandlerWithReply<Payload, Response>) {
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

private class DataScriptMessageHandler: NSObject, WKScriptMessageHandler {
    let name: String
    let didReceiveMessage: (Data) -> Void

    init(name: String,
         didReceiveMessage: @escaping (Data) -> Void) {
        self.name = name
        self.didReceiveMessage = didReceiveMessage
    }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard message.name == name else {
            return
        }
        do {
            didReceiveMessage(try message.toData())
        } catch {
            XCTFail("Failed to decode body for message with name: \(message.name) \(error.localizedDescription)")
        }
    }
}
