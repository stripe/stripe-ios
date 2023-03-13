//
//  SuccessDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/12/22.
//

import Foundation
@_spi(STP) import StripeCore

protocol SuccessDataSource: AnyObject {

    var manifest: FinancialConnectionsSessionManifest { get }
    var linkedAccounts: [FinancialConnectionsPartnerAccount] { get }
    var institution: FinancialConnectionsInstitution { get }
    var saveToLinkWithStripeSucceeded: Bool? { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }
    var showLinkMoreAccountsButton: Bool { get }
}

final class SuccessDataSourceImplementation: SuccessDataSource {

    let manifest: FinancialConnectionsSessionManifest
    let linkedAccounts: [FinancialConnectionsPartnerAccount]
    let institution: FinancialConnectionsInstitution
    let saveToLinkWithStripeSucceeded: Bool?
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient
    var showLinkMoreAccountsButton: Bool {
        !manifest.singleAccount && !manifest.disableLinkMoreAccounts && !(manifest.isNetworkingUserFlow ?? false)
    }

    init(
        manifest: FinancialConnectionsSessionManifest,
        linkedAccounts: [FinancialConnectionsPartnerAccount],
        institution: FinancialConnectionsInstitution,
        saveToLinkWithStripeSucceeded: Bool?,
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.manifest = manifest
        self.linkedAccounts = linkedAccounts
        self.institution = institution
        self.saveToLinkWithStripeSucceeded = saveToLinkWithStripeSucceeded
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
    }
}
