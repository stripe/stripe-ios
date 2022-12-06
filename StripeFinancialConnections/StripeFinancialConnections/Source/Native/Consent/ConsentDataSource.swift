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
    var consent: FinancialConnectionsConsent { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }
    
    func markConsentAcquired() -> Promise<FinancialConnectionsSessionManifest>
}

final class ConsentDataSourceImplementation: ConsentDataSource {
    
    let manifest: FinancialConnectionsSessionManifest
    let consent: FinancialConnectionsConsent
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient
    
    init(
        manifest: FinancialConnectionsSessionManifest,
        consent: FinancialConnectionsConsent,
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.manifest = manifest
        self.consent = consent
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
    }
    
    func markConsentAcquired() -> Promise<FinancialConnectionsSessionManifest> {
        return apiClient.markConsentAcquired(clientSecret: clientSecret)
    }
}
