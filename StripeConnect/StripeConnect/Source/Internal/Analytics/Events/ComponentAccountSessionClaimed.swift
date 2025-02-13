//
//  ComponentAccountSessionClaimed.swift
//  StripeConnect
//
//  Created by Chris Mays on 2/11/25.
//

/// The component successfully claimed the account session within the web view.
/// Triggered from `accountSessionClaimed` message handler from the web view.
struct ComponentAccountSessionClaimed: ConnectAnalyticEvent {
    struct Metadata: Encodable, Equatable {
        /// The pageViewID from the web view
        let pageViewId: String?
    }

    let name = "component.web.account_session_claimed"
    let metadata: Metadata
}
