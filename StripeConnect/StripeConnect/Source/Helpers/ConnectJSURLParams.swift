//
//  ConnectJSURLParams.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 8/30/24.
//

@_spi(STP) @_spi(DashboardOnly) import StripeCore
import Foundation

struct ConnectJSURLParams: Encodable {
    let component: ComponentType
    private(set) var publicKey: String?
    private(set) var apiKeyOverride: String?
    private(set) var livemodeOverride: Bool?
    private(set) var merchantIdOverride: String?
    private(set) var platformIdOverride: String?
}

extension ConnectJSURLParams {
    init(component: ComponentType, apiClient: STPAPIClient) {
        self.component = component

        // Validate that publishable key has been set
        STPAPIClient.validateKey(apiClient.publishableKey)

        if apiClient.publishableKeyIsUserKey {
            self.apiKeyOverride = apiClient.publishableKey
            self.merchantIdOverride = apiClient.stripeAccount
            self.platformIdOverride = apiClient.stripeAccount
            self.livemodeOverride = apiClient.userKeyLiveMode
        } else {
            self.publicKey = apiClient.publishableKey
        }
    }

//    private var asDict: [String: String] {
//        var params: [String: String] = [:]
//        params["component"] = component
//        params["publicKey"] = publishableKey
//        params["livemodeOverride"] = livemodeOverride
//        params["merchantIdOverride"] = merchantIdOverride
//        params["platformIdOverride"] = platformIdOverride
//        params["apiKeyOverride"] = apiKeyOverride
//        return params
//    }


    var url: URL {
        guard let data = try? JSONEncoder().encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            // TODO: Log error
            return StripeConnectConstants.connectJSBaseURL
        }
        return URL(string:"#\(URLEncoder.queryString(from: dict))", relativeTo: StripeConnectConstants.connectJSBaseURL)!
    }
}
