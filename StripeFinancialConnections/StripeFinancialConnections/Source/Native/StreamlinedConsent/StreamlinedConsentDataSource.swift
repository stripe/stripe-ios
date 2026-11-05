//
//  StreamlinedConsentDataSource.swift
//  StripeFinancialConnections
//
//  Created by Till Hellmund on 2026-11-05.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

protocol StreamlinedConsentDataSource: AnyObject {
    var manifest: FinancialConnectionsSessionManifest { get }
    var streamlinedConsentPane: FinancialConnectionsStreamlinedConsentPane { get }
    var dataAccessNotice: FinancialConnectionsDataAccessNotice? { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }

    func markConsentAcquired() -> Promise<FinancialConnectionsSessionManifest>
}

final class StreamlinedConsentDataSourceImplementation: StreamlinedConsentDataSource {
    let manifest: FinancialConnectionsSessionManifest
    let streamlinedConsentPane: FinancialConnectionsStreamlinedConsentPane
    let analyticsClient: FinancialConnectionsAnalyticsClient

    private let consentPaneDataAccessNotice: FinancialConnectionsDataAccessNotice?
    private let apiClient: any FinancialConnectionsAPI
    private let clientSecret: String

    var dataAccessNotice: FinancialConnectionsDataAccessNotice? {
        // The backend may omit the notice from the streamlined consent pane,
        // in which case we fall back to the one from the regular consent pane.
        return streamlinedConsentPane.dataAccessNotice ?? consentPaneDataAccessNotice
    }

    init(
        manifest: FinancialConnectionsSessionManifest,
        streamlinedConsentPane: FinancialConnectionsStreamlinedConsentPane,
        consentPaneDataAccessNotice: FinancialConnectionsDataAccessNotice?,
        apiClient: any FinancialConnectionsAPI,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.manifest = manifest
        self.streamlinedConsentPane = streamlinedConsentPane
        self.consentPaneDataAccessNotice = consentPaneDataAccessNotice
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
    }

    func markConsentAcquired() -> Promise<FinancialConnectionsSessionManifest> {
        return apiClient.markConsentAcquired(clientSecret: clientSecret)
    }
}
