//
//  IDConsentContentDataSource.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2025-03-10.
//

import Foundation
@_spi(STP) import StripeCore

protocol IDConsentContentDataSource: AnyObject {
    var manifest: FinancialConnectionsSessionManifest { get }
    var idConsentContent: FinancialConnectionsIDConsentContent { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }

    func markConsentAcquired() -> Promise<FinancialConnectionsSessionManifest>
}

final class IDConsentContentDataSourceImplementation: IDConsentContentDataSource {
    let manifest: FinancialConnectionsSessionManifest
    let idConsentContent: FinancialConnectionsIDConsentContent
    let analyticsClient: FinancialConnectionsAnalyticsClient

    private let apiClient: any FinancialConnectionsAPI
    private let clientSecret: String

    init(
        manifest: FinancialConnectionsSessionManifest,
        idConsentContent: FinancialConnectionsIDConsentContent,
        apiClient: any FinancialConnectionsAPI,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.manifest = manifest
        self.idConsentContent = idConsentContent
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
    }

    func markConsentAcquired() -> Promise<FinancialConnectionsSessionManifest> {
        return apiClient.markConsentAcquired(clientSecret: clientSecret)
    }
}
