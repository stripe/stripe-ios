//
//  ManualEntryDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/24/22.
//

import Foundation
@_spi(STP) import StripeCore

protocol ManualEntryDataSource: AnyObject {

    var manifest: FinancialConnectionsSessionManifest { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }

    func attachBankAccountToLinkAccountSession(routingNumber: String, accountNumber: String) -> Future<
        FinancialConnectionsPaymentAccountResource
    >
}

final class ManualEntryDataSourceImplementation: ManualEntryDataSource {

    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    let manifest: FinancialConnectionsSessionManifest
    let analyticsClient: FinancialConnectionsAnalyticsClient

    init(
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String,
        manifest: FinancialConnectionsSessionManifest,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.manifest = manifest
        self.analyticsClient = analyticsClient
    }

    func attachBankAccountToLinkAccountSession(
        routingNumber: String,
        accountNumber: String
    ) -> Future<FinancialConnectionsPaymentAccountResource> {
        return apiClient.attachBankAccountToLinkAccountSession(
            clientSecret: clientSecret,
            accountNumber: accountNumber,
            routingNumber: routingNumber
        )
    }
}
