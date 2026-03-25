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
    var customSuccessPaneCaption: String? { get }
    var customSuccessPaneSubCaption: String? { get }
}

final class SuccessDataSourceImplementation: SuccessDataSource {

    let manifest: FinancialConnectionsSessionManifest
    let linkedAccountsCount: Int
    let saveToLinkWithStripeSucceeded: Bool?
    private let apiClient: any FinancialConnectionsAPI
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient
    var customSuccessPaneCaption: String?
    var customSuccessPaneSubCaption: String?
    var showLinkMoreAccountsButton: Bool {
        !manifest.singleAccount && !manifest.disableLinkMoreAccounts && !(manifest.isNetworkingUserFlow ?? false)
    }

    init(
        manifest: FinancialConnectionsSessionManifest,
        linkedAccountsCount: Int,
        saveToLinkWithStripeSucceeded: Bool?,
        apiClient: any FinancialConnectionsAPI,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient,
        customSuccessPaneCaption: String?,
        customSuccessPaneSubCaption: String?
    ) {
        self.manifest = manifest
        self.linkedAccountsCount = linkedAccountsCount
        self.saveToLinkWithStripeSucceeded = saveToLinkWithStripeSucceeded
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
        self.customSuccessPaneCaption = customSuccessPaneCaption
        self.customSuccessPaneSubCaption = customSuccessPaneSubCaption
    }
}
