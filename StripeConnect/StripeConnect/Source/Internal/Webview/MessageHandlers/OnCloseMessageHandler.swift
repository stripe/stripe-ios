//
//  OnCloseMessageHandler.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 8/30/24.
//

import Foundation

// The event emitted when payment details is closed
class OnCloseMessageHandler: OnSetterFunctionCalledMessageHandler.Handler {
    init(didReceiveMessage: @escaping () -> Void) {
        super.init(setter: "setOnClose", didReceiveMessage: didReceiveMessage)
    }
}
