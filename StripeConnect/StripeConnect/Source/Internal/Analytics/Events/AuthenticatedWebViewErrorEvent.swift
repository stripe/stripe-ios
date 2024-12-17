//
//  AuthenticatedWebViewErrorEvent.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 11/6/24.
//

import Foundation

/// The authenticated web view threw an error and was not successfully redirected back to the app.
struct AuthenticatedWebViewErrorEvent: ConnectAnalyticEvent {
    struct Metadata: Encodable, Equatable {
        /// ID for the authenticated web view session (sent in `openAuthenticatedWebView` message
        let authenticatedWebViewId: String

        /// The error identifier
        let error: String

        /// The `pageViewID` from the web view
        /// - Note: May be null if not yet sent from web
        let pageViewId: String?

        init(authenticatedWebViewId: String, error: Error, pageViewId: String?) {
            self.authenticatedWebViewId = authenticatedWebViewId
            self.error = error.analyticsIdentifier
            self.pageViewId = pageViewId
        }
    }

    let name = "component.authenticated_web.error"
    let metadata: Metadata
}
