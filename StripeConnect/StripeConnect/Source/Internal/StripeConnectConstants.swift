//
//  StripeConnectConstants.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 5/3/24.
//

import Foundation

enum StripeConnectConstants {

    /**'
     Pages or navigation requests matching any of these hosts will...
     - Automatically grant camera permissions
     - Open popups in PopupWebViewController (instead of Safari)
     */
    static let allowedHosts: Set<String> = [
        "connect-js.stripe.com",
        "connect.stripe.com",
    ]

    static let connectJSBaseURL = URL(string: "https://connect-js.stripe.com/v1.0/ios_webview.html")!

    /// The authenticated web view will redirect back to the SDK when redirecting
    /// to the URL scheme `stripe-connect://`
    static let authenticatedWebViewReturnUrlScheme = "stripe-connect"
}
