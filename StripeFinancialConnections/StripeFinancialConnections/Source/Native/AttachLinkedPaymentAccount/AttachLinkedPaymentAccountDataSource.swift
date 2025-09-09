//
//  AttachLinkedPaymentAccountDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/28/22.
//

import Foundation
@_spi(STP) import StripeCore

protocol AttachLinkedPaymentAccountDataSource: AnyObject {

    var manifest: FinancialConnectionsSessionManifest { get }
    var institution: FinancialConnectionsInstitution { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }
    var authSessionId: String? { get }
    var reduceManualEntryProminenceInErrors: Bool { get }

    func attachLinkedAccountIdToLinkAccountSession() -> Future<FinancialConnectionsPaymentAccountResource>
}

final class AttachLinkedPaymentAccountDataSourceImplementation: AttachLinkedPaymentAccountDataSource {

    private let apiClient: any FinancialConnectionsAPI
    private let clientSecret: String
    let manifest: FinancialConnectionsSessionManifest
    let institution: FinancialConnectionsInstitution
    private let linkedAccountId: String
    let analyticsClient: FinancialConnectionsAnalyticsClient
    let authSessionId: String?
    private let consumerSessionClientSecret: String?
    let reduceManualEntryProminenceInErrors: Bool

    init(
        apiClient: any FinancialConnectionsAPI,
        clientSecret: String,
        manifest: FinancialConnectionsSessionManifest,
        institution: FinancialConnectionsInstitution,
        linkedAccountId: String,
        analyticsClient: FinancialConnectionsAnalyticsClient,
        authSessionId: String?,
        consumerSessionClientSecret: String?,
        reduceManualEntryProminenceInErrors: Bool
    ) {
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.manifest = manifest
        self.institution = institution
        self.linkedAccountId = linkedAccountId
        self.analyticsClient = analyticsClient
        self.authSessionId = authSessionId
        self.consumerSessionClientSecret = consumerSessionClientSecret
        self.reduceManualEntryProminenceInErrors = reduceManualEntryProminenceInErrors
    }

    func attachLinkedAccountIdToLinkAccountSession() -> Future<FinancialConnectionsPaymentAccountResource> {
        return apiClient.attachLinkedAccountIdToLinkAccountSession(
            clientSecret: clientSecret,
            linkedAccountId: linkedAccountId,
            consumerSessionClientSecret: consumerSessionClientSecret  // used for Link
        )
    }
}
