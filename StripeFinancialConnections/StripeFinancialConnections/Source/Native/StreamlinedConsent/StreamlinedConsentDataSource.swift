//
//  StreamlinedConsentDataSource.swift
//  StripeFinancialConnections
//
//  Created by Till Hellmund on 1/20/25.
//

import Foundation
@_spi(STP) import StripeCore

protocol StreamlinedConsentDataSource: AnyObject {
    var manifest: FinancialConnectionsSessionManifest { get }
    var consent: FinancialConnectionsStreamlinedConsent { get }
    var merchantLogo: [String]? { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }

    func markConsentAcquired() -> Promise<FinancialConnectionsSessionManifest>
}

final class StreamlinedConsentDataSourceImplementation: StreamlinedConsentDataSource {

    let manifest: FinancialConnectionsSessionManifest
    let consent: FinancialConnectionsStreamlinedConsent
    let merchantLogo: [String]?
    private let apiClient: any FinancialConnectionsAPI
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient

    init(
        manifest: FinancialConnectionsSessionManifest,
        consent: FinancialConnectionsStreamlinedConsent,
        merchantLogo: [String]?,
        apiClient: any FinancialConnectionsAPI,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.manifest = manifest
        self.consent = consent
        self.merchantLogo = merchantLogo
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
    }

    func markConsentAcquired() -> Promise<FinancialConnectionsSessionManifest> {
        return apiClient.markConsentAcquired(clientSecret: clientSecret)
    }
}
