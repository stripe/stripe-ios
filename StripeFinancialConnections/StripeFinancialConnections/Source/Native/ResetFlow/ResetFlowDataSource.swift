//
//  ResetFlowDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/2/22.
//

import Foundation
@_spi(STP) import StripeCore

protocol ResetFlowDataSource: AnyObject {
    func markLinkingMoreAccounts() -> Promise<FinancialConnectionsSessionManifest>
}

final class ResetFlowDataSourceImplementation: ResetFlowDataSource {
    
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    
    init(apiClient: FinancialConnectionsAPIClient, clientSecret: String) {
        self.apiClient = apiClient
        self.clientSecret = clientSecret
    }

    func markLinkingMoreAccounts() -> Promise<FinancialConnectionsSessionManifest> {
        return apiClient.markLinkingMoreAccounts(clientSecret: clientSecret)
    }
}
