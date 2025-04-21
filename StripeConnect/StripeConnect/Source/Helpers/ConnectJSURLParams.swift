//
//  ConnectJSURLParams.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 8/30/24.
//

import Foundation
@_spi(STP) @_spi(DashboardOnly) import StripeCore

/// Structured parameters for URL params accepted by the iOS ConnectJS wrapper
struct ConnectJSURLParams: Encodable {
    /// The component type
    let component: ComponentType

    /// The platform publishable key. Required for non-dashboard accounts
    private(set) var publicKey: String?

    // MARK: Override params

    // Override params are only applicable when using embedded components from the Stripe Dashboard app.
    // The web components expect an authenticated user key when setting these params.

    /// Token override used to make authenticated requests (e.g. the `uk_` key for direct accounts)
    private(set) var apiKeyOverride: String?

    /// Whether requests should be made in livemode
    private(set) var livemodeOverride: Bool?

    /// The connected or direct account ID
    private(set) var merchantIdOverride: String?

    /// The platform ID or direct account ID
    /// - Note: For Dashboard direct accounts, this value must match `merchantIdOverride`
    private(set) var platformIdOverride: String?
}

extension ConnectJSURLParams {
    init(component: ComponentType, apiClient: STPAPIClient, publicKeyOverride: String?) {
        self.component = component

        // Validate that publishable key has been set
        STPAPIClient.validateKey(apiClient.publishableKey)
        if apiClient.publishableKeyIsUserKey {
            // Dashboard app overrides
            self.publicKey = publicKeyOverride
            self.apiKeyOverride = apiClient.publishableKey
            self.merchantIdOverride = apiClient.stripeAccount
            self.platformIdOverride = apiClient.stripeAccount
            self.livemodeOverride = apiClient.userKeyLiveMode
        } else {
            self.publicKey = apiClient.publishableKey
        }

    }

    func url(baseURL: URL) throws -> URL {
        let dict = try jsonDictionary(with: .connectEncoder)

        // Append as hash params
        return URL(string: "#\(URLEncoder.queryString(from: dict))", relativeTo: baseURL)!
    }
}
