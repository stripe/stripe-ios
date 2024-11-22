//
//  ReturnedFromAuthenticatedWebViewSender.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/7/24.
//

import Foundation

/// Notifies that the user finished the flow within the `ASWebAuthenticationSession`
struct ReturnedFromAuthenticatedWebViewSender: MessageSender {
    struct Payload: Codable, Equatable {
        /// The return URL from the `ASWebAuthenticationSession` redirect. This value will be nil if the user canceled out of the view
        let url: URL?
        /// The unique identifier sent from the web view in `openAuthenticatedWebView`
        let id: String
    }
    let name: String = "returnedFromAuthenticatedWebView"
    let payload: Payload
}
