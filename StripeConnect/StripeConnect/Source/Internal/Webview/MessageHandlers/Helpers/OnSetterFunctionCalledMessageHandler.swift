//
//  OnSetterFunctionCalledMessageHandler.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/9/24.
//

import Foundation
import WebKit

class OnSetterFunctionCalledMessageHandler: ScriptMessageHandler<OnSetterFunctionCalledMessageHandler.Payload> {
    struct Payload: Decodable {
        /// Name of the setter function (e.g. `onExit`)
        let setter: String

        /// Container with value that will be lazily decoded when we know the type
        private let container: KeyedDecodingContainer<CodingKeys>

        enum CodingKeys: CodingKey {
            case setter
            case value
        }

        init(from decoder: any Decoder) throws {
            let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
            self.setter = try container.decode(String.self, forKey: .setter)
            self.container = container
        }

        /// Lazily decode value
        func value<Value: Decodable>() throws -> Value {
            try container.decode(Value.self, forKey: .value)
        }
    }

    class Handler {
        /// Name of the component-specific setter function (e.g. `onExit`)
        let setter: String
        /// Callback when message is received
        fileprivate let didReceiveMessage: (Payload) throws -> Void

        /// Creates a handler that passes a typed value to `didReceiveMessage`
        init<Value: Codable>(
            setter: String,
            didReceiveMessage: @escaping (Value) -> Void
        ) {
            self.setter = setter
            self.didReceiveMessage = { payload in
                didReceiveMessage(try payload.value())
            }
        }

        /// Creates a handler where `didReceiveMessage` takes no arguments
        init(
            setter: String,
            didReceiveMessage: @escaping () -> Void
        ) {
            self.setter = setter
            self.didReceiveMessage = { _ in
                didReceiveMessage()
            }
        }
    }

    private var handlerMap: [String: Handler] = [:]

    init(analyticsClient: ComponentAnalyticsClient) {
        weak var weakSelf: OnSetterFunctionCalledMessageHandler?
        super.init(name: "onSetterFunctionCalled",
                   analyticsClient: analyticsClient,
                   didReceiveMessage: { payload in
            weakSelf?.didReceivePayload(payload: payload)
        })

        weakSelf = self
    }

    func addHandler(handler: Handler) {
        handlerMap[handler.setter] = handler
    }

    func didReceivePayload(payload: Payload) {
        guard let handler = handlerMap[payload.setter] else {
            analyticsClient.logUnexpectedSetterEvent(setter: payload.setter)
            return
        }
        do {
            try handler.didReceiveMessage(payload)
        } catch {
            analyticsClient.logDeserializeMessageErrorEvent(message: "\(name).\(payload.setter)", error: error)
        }
    }
}
