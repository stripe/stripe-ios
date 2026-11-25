//
//  ComponentHeightChangedMessageHandler.swift
//  StripeConnect
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

/// An inline component's laid-out height changed
class ComponentHeightChangedMessageHandler: ScriptMessageHandler<ComponentHeightChangedMessageHandler.Payload> {
    struct Payload: Codable, Equatable {
        /// The component's height, in CSS pixels
        let height: Double
    }

    init(sourcePolicy: STPWebMessageSourcePolicy,
         analyticsClient: ComponentAnalyticsClient,
         didReceiveMessage: @escaping (Payload) -> Void) {
        super.init(name: "componentHeightChanged",
                   sourcePolicy: sourcePolicy,
                   analyticsClient: analyticsClient,
                   didReceiveMessage: didReceiveMessage)
    }
}
