//
//  StreamlinedConsentDataSource.swift
//  StripeFinancialConnections
//
//  Created by Till Hellmund on 2025-02-05.
//

import Foundation
@_spi(STP) import StripeCore

protocol StreamlinedConsentDataSource: AnyObject {
    var manifest: FinancialConnectionsSessionManifest { get }
    var streamlinedConsentContent: FinancialConnectionsStreamlinedConsent { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }

    func markConsentAcquired() -> Promise<FinancialConnectionsSessionManifest>
}

final class StreamlinedConsentDataSourceImplementation: StreamlinedConsentDataSource {
    let manifest: FinancialConnectionsSessionManifest
    let streamlinedConsentContent: FinancialConnectionsStreamlinedConsent
    let analyticsClient: FinancialConnectionsAnalyticsClient

    private let apiClient: any FinancialConnectionsAPI
    private let clientSecret: String

    init(
        manifest: FinancialConnectionsSessionManifest,
        streamlinedConsentContent: FinancialConnectionsStreamlinedConsent,
        apiClient: any FinancialConnectionsAPI,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.manifest = manifest
        self.streamlinedConsentContent = streamlinedConsentContent
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
    }

    func markConsentAcquired() -> Promise<FinancialConnectionsSessionManifest> {
        return apiClient.markConsentAcquired(clientSecret: clientSecret)
    }
}
