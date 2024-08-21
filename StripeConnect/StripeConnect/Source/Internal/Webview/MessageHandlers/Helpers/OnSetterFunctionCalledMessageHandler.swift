//
//  OnSetterFunctionCalledMessageHandler.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/9/24.
//

import Foundation

class OnSetterFunctionCalledMessageHandler<Values: Codable & Equatable>: ScriptMessageHandler<OnSetterFunctionCalledMessageHandler.Payload<Values>> {
    struct Payload<Value: Codable & Equatable>: Codable {
        /// Name of the component-specific setter function (e.g. `onExit`)
        let setter: String
        /// Setter specific payload
        let value: Value?
    }

    init(setter: String, didReceiveMessage: @escaping (Values?) -> Void) {
        super.init(name: "onSetterFunctionCalled", didReceiveMessage: { payload in
            if payload.setter == setter {
                didReceiveMessage(payload.value)
            }
        })
    }
}
