//
//  OpenAuthenticatedWebViewMessageHandler.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/14/24.
//

import Foundation
@_spi(STP) import StripeCore

/// Indicates to open the provided URL in an `ASWebAuthenticationSession`.
class OpenAuthenticatedWebViewMessageHandler: ScriptMessageHandler<OpenAuthenticatedWebViewMessageHandler.Payload> {
    struct Payload: Codable, Equatable {
        /// Added by the document-start bridge before native asynchronous work begins.
        var documentID: String?
        /// URL that's opened in an `ASWebAuthenticationSession`
        let url: URL
        /// Unique identifier logged in analytics when the `ASWebAuthenticationSession` is opened or closed.
        let id: String
    }
    init(sourcePolicy: STPWebMessageSourcePolicy,
         analyticsClient: ComponentAnalyticsClient,
         didReceiveMessage: @escaping (Payload) -> Void) {
        super.init(name: "openAuthenticatedWebView",
                   sourcePolicy: sourcePolicy,
                   analyticsClient: analyticsClient,
                   didReceiveMessage: didReceiveMessage)
    }
}
