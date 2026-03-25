//
//  AccountSessionClaimedMessageHandler.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/14/24.
//

import Foundation

/// Emitted when the claim response is available
class AccountSessionClaimedMessageHandler: ScriptMessageHandler<AccountSessionClaimedMessageHandler.Payload> {
    struct Payload: Codable, Equatable {
        /// The connected account ID
        let merchantId: String
    }
    init(analyticsClient: ComponentAnalyticsClient,
         didReceiveMessage: @escaping (Payload) -> Void) {
        super.init(name: "accountSessionClaimed",
                   analyticsClient: analyticsClient,
                   didReceiveMessage: didReceiveMessage)
    }
}
