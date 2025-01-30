//
//  ConsentDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/13/22.
//

import Foundation
@_spi(STP) import StripeCore

protocol ConsentDataSource: AnyObject {
    var manifest: FinancialConnectionsSessionManifest { get }
    var configuration: FinancialConnectionsSheet.Configuration { get }
    var consent: FinancialConnectionsConsent { get }
    var merchantLogo: [String]? { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }

    func markConsentAcquired() -> Promise<FinancialConnectionsSessionManifest>
}

final class ConsentDataSourceImplementation: ConsentDataSource {

    let manifest: FinancialConnectionsSessionManifest
    let configuration: FinancialConnectionsSheet.Configuration
    let consent: FinancialConnectionsConsent
    let merchantLogo: [String]?
    private let apiClient: any FinancialConnectionsAPI
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient

    init(
        manifest: FinancialConnectionsSessionManifest,
        configuration: FinancialConnectionsSheet.Configuration,
        consent: FinancialConnectionsConsent,
        merchantLogo: [String]?,
        apiClient: any FinancialConnectionsAPI,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.manifest = manifest
        self.configuration = configuration
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
