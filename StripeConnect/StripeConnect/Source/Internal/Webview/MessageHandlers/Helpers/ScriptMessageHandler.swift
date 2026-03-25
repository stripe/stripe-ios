//
//  ScriptMessageHandler.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 5/1/24.
//

@_spi(STP) import StripeCore
import WebKit

/// Convenience class that conforms to WKScriptMessageHandler and can be instantiated with a closure
class ScriptMessageHandler<Payload: Decodable>: NSObject, WKScriptMessageHandler {
    struct UnexpectedMessageNameError: Error, AnalyticLoggableErrorV2 {
        let actual: String
        let expected: String

        func analyticLoggableSerializeForLogging() -> [String: Any] {
            [
                "actual": actual,
                "expected": expected,
            ]
        }
    }

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
            analyticsClient.logClientError(UnexpectedMessageNameError(
                actual: message.name,
                expected: name
            ))
            return
        }
        do {
            didReceiveMessage(try message.toDecodable())
        } catch {
            analyticsClient.logDeserializeMessageErrorEvent(message: message.name, error: error)
        }
    }
}
