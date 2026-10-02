//
//  OnLoadCompleteMessageHandler.swift
//  StripeConnect
//

import Foundation

/// Exploratory: emitted once a component has rendered its real content, not a loading state.
class OnLoadCompleteMessageHandler: OnSetterFunctionCalledMessageHandler.Handler {
    init(didReceiveMessage: @escaping () -> Void) {
        super.init(setter: "setOnLoadComplete", didReceiveMessage: didReceiveMessage)
    }
}
