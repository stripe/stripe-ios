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
        /// The return URL from the `ASWebAuthenticationSession` redirect. This value will be nil if the user canceled out fo the view
        let url: String?
    }
    let name: String = "returnedFromAuthenticatedWebView"
    let payload: Payload
}
