//
//  PageDidLoadMessageHandler.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/7/24.
//

import Foundation
@_spi(STP) import StripeCore

// A message that indicates components have loaded
class PageDidLoadMessageHandler: ScriptMessageHandler<PageDidLoadMessageHandler.Payload> {
    struct Payload: Codable, Equatable {
        /// A unique session ID shared with web for analytics logging
        let pageViewId: String
    }
    init(sourcePolicy: STPWebMessageSourcePolicy,
         analyticsClient: ComponentAnalyticsClient,
         didReceiveMessage: @escaping (Payload) -> Void) {
        super.init(name: "pageDidLoad",
                   sourcePolicy: sourcePolicy,
                   analyticsClient: analyticsClient,
                   didReceiveMessage: didReceiveMessage)
    }
}
