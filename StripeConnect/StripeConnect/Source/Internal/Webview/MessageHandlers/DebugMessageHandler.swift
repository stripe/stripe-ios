//
//  DebugMessage.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/2/24.
//

import Foundation

// Emitted when the SDK should print to the console in debug mode.
class DebugMessageHandler: ScriptMessageHandler<String> {
    init(analyticsClient: ComponentAnalyticsClient,
         didReceiveMessage: @escaping (String) -> Void = { Swift.debugPrint($0) }) {
        super.init(name: "debug",
                   analyticsClient: analyticsClient,
                   didReceiveMessage: didReceiveMessage)
    }
}
