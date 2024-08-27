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
    let fetchClientSecret: () async -> String?

    /**
     Initializes a StripeConnect instance.

     - Parameters:
       - apiClient: The APIClient instance used to make requests to Stripe.
       - fetchClientSecret: Closure that fetches client secret.
     */
    public init(apiClient: STPAPIClient = STPAPIClient.shared,
                fetchClientSecret: @escaping () async -> String?) {
        self.apiClient = apiClient
        self.fetchClientSecret = fetchClientSecret
    }
}
