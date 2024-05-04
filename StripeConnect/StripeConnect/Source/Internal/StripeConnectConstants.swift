//
//  StripeConnectConstants.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 5/3/24.
//

import Foundation

enum StripeConnectConstants {

    /**
     URL for the hosted HTML page that wraps the JS `StripeConnectInstance` for iOS.

     TODO: Change this to the remote index page. See note on ComponentWebView.loadContents()
     */
    static let connectWrapperURL = URL(string: "https://connect-js.stripe.com")!

    /**'
     Pages or navigation requests matching any of these hosts will...
     - Automatically grant camera permissions
     - Accept downloads (TODO)
     - Open popups in PopupWebViewController (instead of Safari)
     */
    static let allowedHosts: Set<String> = [
        "connect-js.stripe.com",
        "connect.stripe.com",
    ]
}
