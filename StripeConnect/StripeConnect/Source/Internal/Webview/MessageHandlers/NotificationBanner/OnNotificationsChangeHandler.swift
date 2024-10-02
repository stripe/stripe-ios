//
//  OnNotificationsChangeHandler.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 9/25/24.
//

import Foundation

class OnNotificationsChangeHandler: OnSetterFunctionCalledMessageHandler.Handler {
    struct Values: Codable, Equatable {
        let total: Int
        let actionRequired: Int
    }

    init(didReceiveMessage: @escaping (Values) -> Void) {
        super.init(setter: "setOnNotificationsChange", didReceiveMessage: didReceiveMessage)
    }
}
