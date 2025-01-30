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
    var configuration: FinancialConnectionsSheet.Configuration { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }

    func disableNetworking() -> Future<FinancialConnectionsSessionManifest>
}

final class NetworkingLinkLoginWarmupDataSourceImplementation: NetworkingLinkLoginWarmupDataSource {

    let manifest: FinancialConnectionsSessionManifest
    let configuration: FinancialConnectionsSheet.Configuration
    private let apiClient: any FinancialConnectionsAPI
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient
    private let nextPaneOrDrawerOnSecondaryCta: String?

    init(
        manifest: FinancialConnectionsSessionManifest,
        configuration: FinancialConnectionsSheet.Configuration,
        apiClient: any FinancialConnectionsAPI,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient,
        nextPaneOrDrawerOnSecondaryCta: String?
    ) {
        self.manifest = manifest
        self.configuration = configuration
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
        self.nextPaneOrDrawerOnSecondaryCta = nextPaneOrDrawerOnSecondaryCta
    }

    func disableNetworking() -> Future<FinancialConnectionsSessionManifest> {
        return apiClient.disableNetworking(
            disabledReason: "returning_consumer_opt_out",
            clientSuggestedNextPaneOnDisableNetworking: nextPaneOrDrawerOnSecondaryCta,
            clientSecret: clientSecret
        )
    }
}
