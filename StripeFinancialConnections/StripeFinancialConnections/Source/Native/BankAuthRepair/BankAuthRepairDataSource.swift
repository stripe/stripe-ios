//
//  BankAuthRepairDataManager.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/26/23.
//

import Foundation
@_spi(STP) import StripeCore

protocol BankAuthRepairDataSource: AnyObject {
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }
    var sharedPartnerAuthDataSource: SharedPartnerAuthDataSource { get }

    func initiateAuthRepairSession() -> Promise<FinancialConnectionsAuthRepairSession>
    func selectNetworkedAccount() -> Future<FinancialConnectionsInstitutionList>
    func completeAuthRepairSession(
        authRepairSessionId: String
    ) -> Promise<FinancialConnectionsAuthRepairSessionComplete>
}

final class BankAuthRepairDataSourceImplementation: BankAuthRepairDataSource {

    private let coreAuthorizationId: String
    private let consumerSession: ConsumerSessionData
    private let selectedAccountId: String
    private let manifest: FinancialConnectionsSessionManifest
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient
    let sharedPartnerAuthDataSource: SharedPartnerAuthDataSource

    init(
        coreAuthorizationId: String,
        consumerSession: ConsumerSessionData,
        selectedAccountId: String,
        institution: FinancialConnectionsInstitution,
        manifest: FinancialConnectionsSessionManifest,
        returnURL: String?,
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.coreAuthorizationId = coreAuthorizationId
        self.consumerSession = consumerSession
        self.selectedAccountId = selectedAccountId
        self.manifest = manifest
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
        self.sharedPartnerAuthDataSource = SharedPartnerAuthDataSourceImplementation(
            pane: .bankAuthRepair,
            institution: institution,
            manifest: manifest,
            returnURL: returnURL,
            apiClient: apiClient,
            clientSecret: clientSecret,
            analyticsClient: analyticsClient
        )
    }

    func initiateAuthRepairSession() -> Promise<FinancialConnectionsAuthRepairSession> {
        return apiClient.initiateAuthRepairSession(
            clientSecret: clientSecret,
            coreAuthorizationId: coreAuthorizationId
        )
    }

    func selectNetworkedAccount() -> Future<FinancialConnectionsInstitutionList> {
        return apiClient.selectNetworkedAccounts(
            selectedAccountIds: [selectedAccountId],
            clientSecret: clientSecret,
            consumerSessionClientSecret: consumerSession.clientSecret
        )
    }

    func completeAuthRepairSession(
        authRepairSessionId: String
    ) -> Promise<FinancialConnectionsAuthRepairSessionComplete> {
        return apiClient.completeAuthRepairSession(
            clientSecret: clientSecret,
            authRepairSessionId: authRepairSessionId,
            coreAuthorizationId: coreAuthorizationId
        )
    }
}
