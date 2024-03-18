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
    var linkedAccountsCount: Int { get }
    var saveToLinkWithStripeSucceeded: Bool? { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }
    var showLinkMoreAccountsButton: Bool { get }
    var customSuccessPaneMessage: String? { get }
}

final class SuccessDataSourceImplementation: SuccessDataSource {

    let manifest: FinancialConnectionsSessionManifest
    let linkedAccountsCount: Int
    let saveToLinkWithStripeSucceeded: Bool?
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient
    var customSuccessPaneMessage: String?
    var showLinkMoreAccountsButton: Bool {
        !manifest.singleAccount && !manifest.disableLinkMoreAccounts && !(manifest.isNetworkingUserFlow ?? false)
    }

    init(
        manifest: FinancialConnectionsSessionManifest,
        linkedAccountsCount: Int,
        saveToLinkWithStripeSucceeded: Bool?,
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient,
        customSuccessPaneMessage: String?
    ) {
        self.manifest = manifest
        self.linkedAccountsCount = linkedAccountsCount
        self.saveToLinkWithStripeSucceeded = saveToLinkWithStripeSucceeded
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
        self.customSuccessPaneMessage = customSuccessPaneMessage
    }
}
