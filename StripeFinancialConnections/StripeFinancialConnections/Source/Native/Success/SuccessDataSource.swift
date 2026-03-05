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
    var customSuccessPaneCaption: String? { get }
    var customSuccessPaneSubCaption: String? { get }
}

final class SuccessDataSourceImplementation: SuccessDataSource {

    let manifest: FinancialConnectionsSessionManifest
    let linkedAccountsCount: Int
    let saveToLinkWithStripeSucceeded: Bool?
    let analyticsClient: FinancialConnectionsAnalyticsClient
    var customSuccessPaneCaption: String?
    var customSuccessPaneSubCaption: String?
    init(
        manifest: FinancialConnectionsSessionManifest,
        linkedAccountsCount: Int,
        saveToLinkWithStripeSucceeded: Bool?,
        analyticsClient: FinancialConnectionsAnalyticsClient,
        customSuccessPaneCaption: String?,
        customSuccessPaneSubCaption: String?
    ) {
        self.manifest = manifest
        self.linkedAccountsCount = linkedAccountsCount
        self.saveToLinkWithStripeSucceeded = saveToLinkWithStripeSucceeded
        self.analyticsClient = analyticsClient
        self.customSuccessPaneCaption = customSuccessPaneCaption
        self.customSuccessPaneSubCaption = customSuccessPaneSubCaption
    }
}
