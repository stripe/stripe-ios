//
//  ResetFlowDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/2/22.
//

import Foundation
@_spi(STP) import StripeCore

protocol ResetFlowDataSource: AnyObject {
    var manifest: FinancialConnectionsSessionManifest { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }

    func markLinkingMoreAccounts() -> Promise<FinancialConnectionsSessionManifest>
}

final class ResetFlowDataSourceImplementation: ResetFlowDataSource {

    private let apiClient: any FinancialConnectionsAPI
    private let clientSecret: String
    let manifest: FinancialConnectionsSessionManifest
    let analyticsClient: FinancialConnectionsAnalyticsClient

    init(
        apiClient: any FinancialConnectionsAPI,
        clientSecret: String,
        manifest: FinancialConnectionsSessionManifest,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.manifest = manifest
        self.analyticsClient = analyticsClient
    }

    func markLinkingMoreAccounts() -> Promise<FinancialConnectionsSessionManifest> {
        return apiClient.markLinkingMoreAccounts(clientSecret: clientSecret)
    }
}
