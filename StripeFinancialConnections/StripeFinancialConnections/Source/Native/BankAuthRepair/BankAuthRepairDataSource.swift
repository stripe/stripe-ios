//
//  BankAuthRepairDataManager.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/26/23.
//

import Foundation
@_spi(STP) import StripeCore

protocol BankAuthRepairDataSource: AnyObject {
//    var institution: FinancialConnectionsInstitution { get }
    var manifest: FinancialConnectionsSessionManifest { get }
    var returnURL: String? { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }
    var pendingAuthSession: FinancialConnectionsAuthSession? { get }
    var reduceManualEntryProminenceInErrors: Bool { get }
    var disableAuthSessionRetrieval: Bool { get }
    var sharedPartnerAuthDataSource: SharedPartnerAuthDataSource { get }

    func initiateAuthRepairSession() -> Promise<FinancialConnectionsAuthRepairSession>
    func completeAuthRepairSession(authRepairSessionId: String) -> Promise<FinancialConnectionsAuthRepairSessionComplete>
    func selectNetworkedAccount() -> Future<FinancialConnectionsInstitutionList>
}

final class BankAuthRepairDataSourceImplementation: BankAuthRepairDataSource {

//    var institution: FinancialConnectionsInstitution
    private let coreAuthorizationId: String
    private let consumerSession: ConsumerSessionData
    private let selectedAccountId: String
    let manifest: FinancialConnectionsSessionManifest
    let returnURL: String?
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient
    let reduceManualEntryProminenceInErrors: Bool
    var disableAuthSessionRetrieval: Bool {
        return manifest.features?["bank_connections_disable_defensive_auth_session_retrieval_on_complete"] == true
    }

    let sharedPartnerAuthDataSource: SharedPartnerAuthDataSource

    // a "pending" auth session is a session which has started
    // BUT the session is still yet-to-be authorized
    //
    // in other words, a `pendingAuthSession` is up for being
    // cancelled unless the user successfully authorizes
    private(set) var pendingAuthSession: FinancialConnectionsAuthSession?

    init(
        coreAuthorizationId: String,
        consumerSession: ConsumerSessionData,
        selectedAccountId: String,
        manifest: FinancialConnectionsSessionManifest,
        returnURL: String?,
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient,
        reduceManualEntryProminenceInErrors: Bool
    ) {
        self.coreAuthorizationId = coreAuthorizationId
        self.consumerSession = consumerSession
        self.selectedAccountId = selectedAccountId
        self.manifest = manifest
        self.returnURL = returnURL
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
        self.reduceManualEntryProminenceInErrors = reduceManualEntryProminenceInErrors
        self.sharedPartnerAuthDataSource = SharedPartnerAuthDataSourceImplementation(
            pane: .bankAuthRepair,
            // TODO(kgaidis): FIX
            institution: FinancialConnectionsInstitution(id: "", name: "", url: nil, icon: nil, logo: nil),
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
