//
//  ResetFlowDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/2/22.
//

import Foundation
@_spi(STP) import StripeCore

protocol ResetFlowDataSource: AnyObject {
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }

    func markLinkingMoreAccounts() -> Promise<FinancialConnectionsSessionManifest>
}

final class ResetFlowDataSourceImplementation: ResetFlowDataSource {

    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient

    init(
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
    }

    func markLinkingMoreAccounts() -> Promise<FinancialConnectionsSessionManifest> {
        return apiClient.markLinkingMoreAccounts(clientSecret: clientSecret)
    }
}
