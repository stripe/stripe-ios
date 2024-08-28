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
     - Accept downloads (TODO MXMOBILE-2485)
     - Open popups in PopupWebViewController (instead of Safari)
     */
    static let allowedHosts: Set<String> = [
        "connect-js.stripe.com",
        "connect.stripe.com",
    ]
    
    /**
     URL for the hosted HTML page that wraps the JS `StripeConnectInstance` for iOS.
     */
    static func connectJSURL(component: String, publishableKey: String) -> URL {
       let url = URL(string:"https://connect-js.stripe.com/v1.0/ios_webview.html")!
        
        return URL(string:"#component=\(component)&publicKey=\(publishableKey)", relativeTo: url)!
    }
}
