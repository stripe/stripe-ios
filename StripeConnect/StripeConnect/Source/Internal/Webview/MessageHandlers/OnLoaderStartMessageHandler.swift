//
//  OnLoaderStartMessageHandler.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/9/24.
//

import Foundation

// Emitted when connect js has initialized and the component renders a loading state
class OnLoaderStartMessageHandler: OnSetterFunctionCalledMessageHandler<OnLoaderStartMessageHandler.Values> {
    struct Values: Codable, Equatable {
        let elementTagName: String
    }
    init(didReceiveMessage: @escaping (OnLoaderStartMessageHandler.Values) -> Void) {
        super.init(setter: "setOnLoaderStart", didReceiveMessage: { value in
            if let value {
                didReceiveMessage(value)
            } else {
                debugPrint("Did not receive values for setOnLoaderStart")
            }
        })
    }
}
