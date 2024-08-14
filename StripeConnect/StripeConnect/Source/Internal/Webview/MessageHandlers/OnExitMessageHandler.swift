//
//  OnExitMessageHandler.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/7/24.
//

import Foundation

// The event emitted when onboarding is exited
class OnExitMessageHandler: OnSetterFunctionCalledMessageHandler<VoidPayload> {
    init(didReceiveMessage: @escaping () -> Void) {
        super.init(setter: "setOnExit", didReceiveMessage: { _ in
            didReceiveMessage()
        })
    }
}
