//
//  APIVersion.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 9/13/22.
//

import Foundation
@_spi(STP) import StripeCore

struct APIVersion {
    /**
     The latest production-ready version of the Financial Connections API that the
     SDK is capable of using.

     - Note: Update this value when a new API version is ready for use in production.
     */
    private static let apiVersion: Int = 1  // WARNING: this is also referenced in other places, so double check changes!
    private static let header = "financial_connections_client_api_beta=v\(apiVersion)"

    static func configureFinancialConnectionsAPIVersion(apiClient: STPAPIClient) {
        var betas = apiClient.betas
        betas.insert(header)
        apiClient.betas = betas
    }
}
