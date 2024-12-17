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
    var email: String? { get }

    func disableNetworking() -> Future<FinancialConnectionsSessionManifest>
}

final class NetworkingLinkLoginWarmupDataSourceImplementation: NetworkingLinkLoginWarmupDataSource {

    let manifest: FinancialConnectionsSessionManifest
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient
    private let nextPaneOrDrawerOnSecondaryCta: String?
    private let elementsSessionContext: ElementsSessionContext?
    
    var email: String? {
        manifest.accountholderCustomerEmailAddress ?? elementsSessionContext?.prefillDetails?.email
    }

    init(
        manifest: FinancialConnectionsSessionManifest,
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient,
        nextPaneOrDrawerOnSecondaryCta: String?,
        elementsSessionContext: ElementsSessionContext?
    ) {
        self.manifest = manifest
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
        self.nextPaneOrDrawerOnSecondaryCta = nextPaneOrDrawerOnSecondaryCta
        self.elementsSessionContext = elementsSessionContext
    }

    func disableNetworking() -> Future<FinancialConnectionsSessionManifest> {
        return apiClient.disableNetworking(
            disabledReason: "returning_consumer_opt_out",
            clientSuggestedNextPaneOnDisableNetworking: nextPaneOrDrawerOnSecondaryCta,
            clientSecret: clientSecret
        )
    }
}
