//
//  OpenAuthenticatedWebViewMessageHandler.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/14/24.
//

import Foundation

/// Indicates to open the provided URL in an `ASWebAuthenticationSession`.
class OpenAuthenticatedWebViewMessageHandler: ScriptMessageHandlerWithReply<OpenAuthenticatedWebViewMessageHandler.Payload, OpenAuthenticatedWebViewMessageHandler.Response> {
    struct Payload: Codable, Equatable {
        /// URL that's opened in an `ASWebAuthenticationSession`
        let url: URL
        /// Unique identifier logged in analytics when the `ASWebAuthenticationSession` is opened or closed.
        let id: String
    }

    struct Response: Codable, Equatable {
        /// The return URL from the `ASWebAuthenticationSession` redirect.
        /// This value will be nil if the user canceled out of the view
        let url: URL?
    }

    init(didReceiveMessage: @escaping (Payload) async throws -> Response) {
        super.init(name: "openAuthenticatedWebView", didReceiveMessage: didReceiveMessage)
    }
}
