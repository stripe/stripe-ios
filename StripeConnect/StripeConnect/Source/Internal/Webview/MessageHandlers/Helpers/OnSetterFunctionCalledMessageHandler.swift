//
//  OnSetterFunctionCalledMessageHandler.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/9/24.
//

import Foundation
import WebKit

class OnSetterFunctionCalledMessageHandler<Values: Codable & Equatable>: ScriptMessageHandler<OnSetterFunctionCalledMessageHandler.Payload<Values>> {
    struct Payload<Value: Codable & Equatable>: Codable {
        /// Name of the component-specific setter function (e.g. `onExit`)
        let setter: String
        /// Setter specific payload
        let value: Value?
    }
    
    let setter: String

    init(setter: String, didReceiveMessage: @escaping (Values?) -> Void) {
        self.setter = setter
        super.init(name: "onSetterFunctionCalled", didReceiveMessage: { payload in
            if payload.setter == setter {
                didReceiveMessage(payload.value)
            }
        })
    }
    
    override func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        do {
            let payload: Payload<VoidPayload> = try message.toDecodable()
            if payload.setter == setter {
                super.userContentController(userContentController, didReceive: message)
            }
        } catch {
            //TODO: MXMOBILE-2491 Log as analytics
            debugPrint("Received unexpected setter function message for setter: \(setter) \(error.localizedDescription)")
        }
    }
}
