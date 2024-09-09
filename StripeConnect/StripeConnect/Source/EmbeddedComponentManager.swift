//
//  EmbeddedComponentManager.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 4/30/24.
//

import JavaScriptCore
import StripeCore
import UIKit

@_spi(PrivateBetaConnect)
public class EmbeddedComponentManager {
    let apiClient: STPAPIClient
    
    // Weakly held web views who get notified when appearance updates.
    private(set) var childWebViews: NSHashTable<ConnectComponentWebView> = .weakObjects()
    
    let fetchClientSecret: () async -> String?
    private(set) var appearance: EmbeddedComponentManager.Appearance
    /**
     Initializes a StripeConnect instance.

     - Parameters:
       - apiClient: The APIClient instance used to make requests to Stripe.
       - appearance: Customizes the look of Connect embedded components.
       - fetchClientSecret: ​​The closure that retrieves the [client secret](https://docs.stripe.com/api/account_sessions/object#account_session_object-client_secret)
     returned by `/v1/account_sessions`. This tells the `EmbeddedComponentManager` which account to
     delegate access to. This function is also used to retrieve a client secret function to
     refresh the session when it expires.
     */
    public init(apiClient: STPAPIClient = STPAPIClient.shared,
                appearance: EmbeddedComponentManager.Appearance = .default,
                fetchClientSecret: @escaping () async -> String?) {
        self.apiClient = apiClient
        self.fetchClientSecret = fetchClientSecret
        self.appearance = appearance
    }
    
    /// Updates the appearance of components created from this EmbeddedComponentManager
    /// - Seealso: https://docs.stripe.com/connect/get-started-connect-embedded-components#customize-the-look-of-connect-embedded-components
    public func update(appearance: Appearance) {
        self.appearance = appearance
        for item in childWebViews.allObjects {
            item.updateAppearance(appearance: appearance)
        }
    }
    
    /// Creates a payouts component
    /// - Seealso: https://docs.stripe.com/connect/supported-embedded-components/payouts
    public func createPayoutsViewController() -> PayoutsViewController {
        .init(componentManager: self)
    }

    /// Used to keep reference of all web views associated with this component manager.
    /// - Parameters:
    ///   - webView: The web view associated with this component manager
    func registerChild(_ webView: ConnectComponentWebView) {
        childWebViews.add(webView)
    }
}
