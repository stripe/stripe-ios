//
//  OpenAuthenticatedWebViewMessageHandler.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/14/24.
//

import Foundation

/// Indicates to open the provided URL in an `ASWebAuthenticationSession`.
class OpenAuthenticatedWebViewMessageHandler: ScriptMessageHandler<OpenAuthenticatedWebViewMessageHandler.Payload> {
    struct Payload: Codable, Equatable {
        /// URL that's opened in an `ASWebAuthenticationSession`
        let url: URL
        /// Unique identifier logged in analytics when the `ASWebAuthenticationSession` is opened or closed.
        let id: String
    }
    init(analyticsClient: ComponentAnalyticsClient,
         didReceiveMessage: @escaping (Payload) -> Void) {
        super.init(name: "openAuthenticatedWebView",
                   analyticsClient: analyticsClient,
                   didReceiveMessage: didReceiveMessage)
    }
}
