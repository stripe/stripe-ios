//
//  AuthenticatedWebViewCanceledEvent.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 11/6/24.
//

import Foundation

/// The user closed the authenticated web view before getting redirected back to the app.
struct AuthenticatedWebViewCanceledEvent: ConnectAnalyticEvent {
    struct Metadata: Encodable, Equatable {
        /// ID for the authenticated web view session (sent in `openAuthenticatedWebView` message
        let authenticatedWebViewId: String

        /// The `pageViewID` from the web view
        /// - Note: May be null if not yet sent from web
        let pageViewId: String?
    }

    let name = "component.authenticated_web.canceled"
    let metadata: Metadata
}
