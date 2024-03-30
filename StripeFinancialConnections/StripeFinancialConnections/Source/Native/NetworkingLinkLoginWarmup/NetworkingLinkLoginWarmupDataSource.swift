//
//  NetworkingLinkLoginWarmupDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/6/23.
//

import Foundation
@_spi(STP) import StripeCore

protocol NetworkingLinkLoginWarmupDataSource: AnyObject {
    var manifest: FinancialConnectionsSessionManifest { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }

    func disableNetworking() -> Future<FinancialConnectionsSessionManifest>
}

final class NetworkingLinkLoginWarmupDataSourceImplementation: NetworkingLinkLoginWarmupDataSource {

    let manifest: FinancialConnectionsSessionManifest
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient

    init(
        manifest: FinancialConnectionsSessionManifest,
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.manifest = manifest
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
    }

    func disableNetworking() -> Future<FinancialConnectionsSessionManifest> {
        return apiClient.disableNetworking(
            disabledReason: "returning_consumer_opt_out",
            clientSecret: clientSecret
        )
    }
}
