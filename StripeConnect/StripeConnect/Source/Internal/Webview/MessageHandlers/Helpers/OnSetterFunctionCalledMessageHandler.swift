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
        /// Name of the component-specific setter function (e.g. `onExit`)
        let setter: String

        /// Container with value that will be lazily decoded when we know the type
        private let container: KeyedDecodingContainer<CodingKeys>

        enum CodingKeys: CodingKey {
            case setter
            case values
        }

        init(from decoder: any Decoder) throws {
            let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
            self.setter = try container.decode(String.self, forKey: .setter)
            self.container = container
        }

        func values<Values: Decodable>(_ valuesType: Values.Type = Values.self) throws -> Values {
            try container.decode(Values.self, forKey: .values)
        }
    }

    class Handler {
        /// Name of the component-specific setter function (e.g. `onExit`)
        let setter: String
        /// Callback when message is received
        fileprivate let didReceiveMessage: (Payload) throws -> Void

        init<Values: Codable>(
            setter: String,
            didReceiveMessage: @escaping (Values) -> Void
        ) {
            self.setter = setter
            self.didReceiveMessage = { payload in
                didReceiveMessage(try payload.values())
            }
        }

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

    init(_ handlers: [Handler]) {
        // Transform to dictionary for easy lookup
        let handlersDict = handlers.reduce(into: [:]) { partialResult, handler in
            partialResult[handler.setter] = handler.didReceiveMessage
        }
        super.init(name: "onSetterFunctionCalled", didReceiveMessage: { payload in
            do {
                try handlersDict[payload.setter]?(payload)
            } catch {
                // TODO: MXMOBILE-2491 Log as analytics
                debugPrint("Received unexpected setter function message for setter: \(payload.setter) \(error.localizedDescription)")
            }
        })
    }
}
