//
//  StripeConnectConstants.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 5/3/24.
//

import Foundation

enum StripeConnectConstants {

    /// The horizontal body margin for the Account onboarding/management components
    static let accountHorizontalMargin: CGFloat = 10

    /// Hosted webpage that wraps the Connect-JS library with iOS-specific code
    static let connectWrapperURL = URL(string: "https://connect-js.stripe.com/v1.0/ios_webview.html")!

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
