//
//  AuthenticatedWebViewOpenedEvent.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 11/6/24.
//

import Foundation

/// An authenticated web view was opened
struct AuthenticatedWebViewOpenedEvent: ConnectAnalyticEvent {
    struct Metadata: Encodable, Equatable {
        /// ID for the authenticated web view session (sent in `openAuthenticatedWebView` message
        let authenticatedWebViewId: String

        /// The `pageViewID` from the web view
        /// - Note: May be null if not yet sent from web
        let pageViewId: String?
    }

    let name = "component.authenticated_web.opened"
    let metadata: Metadata
}
