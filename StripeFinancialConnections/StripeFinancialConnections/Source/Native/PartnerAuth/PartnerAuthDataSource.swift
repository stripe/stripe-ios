//
//  PartnerAuthDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/8/22.
//

import Foundation
@_spi(STP) import StripeCore

protocol PartnerAuthDataSource: AnyObject {
    var institution: FinancialConnectionsInstitution { get }
    var manifest: FinancialConnectionsSessionManifest { get }
    var returnURL: String? { get }
    var sharedPartnerAuthDataSource: SharedPartnerAuthDataSource { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }
    var pendingAuthSession: FinancialConnectionsAuthSession? { get }
    var reduceManualEntryProminenceInErrors: Bool { get }
    var disableAuthSessionRetrieval: Bool { get }

    func createAuthSession() -> Future<FinancialConnectionsAuthSession>
    func authorizeAuthSession(_ authSession: FinancialConnectionsAuthSession) -> Future<FinancialConnectionsAuthSession>
    func cancelPendingAuthSessionIfNeeded()
    func recordAuthSessionEvent(eventName: String, authSessionId: String)
    func clearReturnURL(authSession: FinancialConnectionsAuthSession, authURL: String) -> Future<FinancialConnectionsAuthSession>
    func retrieveAuthSession(_ authSession: FinancialConnectionsAuthSession) -> Future<FinancialConnectionsAuthSession>
}

final class PartnerAuthDataSourceImplementation: PartnerAuthDataSource {

    let sharedPartnerAuthDataSource: SharedPartnerAuthDataSource
    var institution: FinancialConnectionsInstitution {
        return sharedPartnerAuthDataSource.institution
    }
    var manifest: FinancialConnectionsSessionManifest {
        return sharedPartnerAuthDataSource.manifest
    }
    var returnURL: String? {
        return sharedPartnerAuthDataSource.returnURL
    }
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient
    let reduceManualEntryProminenceInErrors: Bool
    var disableAuthSessionRetrieval: Bool {
        return manifest.features?["bank_connections_disable_defensive_auth_session_retrieval_on_complete"] == true
    }
    var pendingAuthSession: FinancialConnectionsAuthSession? {
        return sharedPartnerAuthDataSource.pendingAuthSession
    }

    init(
        institution: FinancialConnectionsInstitution,
        manifest: FinancialConnectionsSessionManifest,
        returnURL: String?,
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient,
        reduceManualEntryProminenceInErrors: Bool
    ) {
        self.sharedPartnerAuthDataSource = SharedPartnerAuthDataSourceImplementation(
            pane: .partnerAuth,
            institution: institution,
            manifest: manifest,
            returnURL: returnURL,
            apiClient: apiClient,
            clientSecret: clientSecret,
            analyticsClient: analyticsClient
        )
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
        self.reduceManualEntryProminenceInErrors = reduceManualEntryProminenceInErrors
    }

    func createAuthSession() -> Future<FinancialConnectionsAuthSession> {
        return apiClient.createAuthSession(
            clientSecret: clientSecret,
            institutionId: institution.id
        ).chained { [weak self] (authSession: FinancialConnectionsAuthSession) in
            self?.sharedPartnerAuthDataSource.pendingAuthSession = authSession
            return Promise(value: authSession)
        }
    }

    func clearReturnURL(
        authSession: FinancialConnectionsAuthSession,
        authURL: String
    ) -> Future<FinancialConnectionsAuthSession> {
        return sharedPartnerAuthDataSource.clearReturnURL(
            authSession: authSession,
            authURL: authURL
        )
    }

    func cancelPendingAuthSessionIfNeeded() {
        guard let pendingAuthSession = pendingAuthSession else {
            return
        }
        sharedPartnerAuthDataSource.pendingAuthSession = nil
        cancelAuthSession(pendingAuthSession)
            .observe { _ in
                // we ignore the result because its not important
            }
    }

    private func cancelAuthSession(_ authSession: FinancialConnectionsAuthSession) -> Future<
        FinancialConnectionsAuthSession
    > {
        return apiClient.cancelAuthSession(
            clientSecret: clientSecret,
            authSessionId: authSession.id
        )
    }

    func authorizeAuthSession(_ authSession: FinancialConnectionsAuthSession) -> Future<FinancialConnectionsAuthSession>
    {
        return apiClient.fetchAuthSessionOAuthResults(
            clientSecret: clientSecret,
            authSessionId: authSession.id
        )
        .chained(
            on: DispatchQueue.main,
            using: { [weak self] mixedOAuthParameters in
                guard let self = self else {
                    return Promise(
                        error: FinancialConnectionsSheetError.unknown(
                            debugDescription: "\(PartnerAuthDataSourceImplementation.self) deallocated."
                        )
                    )
                }
                return self.apiClient.authorizeAuthSession(
                    clientSecret: self.clientSecret,
                    authSessionId: authSession.id,
                    publicToken: mixedOAuthParameters.publicToken
                )
            }
        )
    }

    func recordAuthSessionEvent(
        eventName: String,
        authSessionId: String
    ) {
        return sharedPartnerAuthDataSource.recordAuthSessionEvent(
            eventName: eventName,
            authSessionId: authSessionId
        )
    }

    func retrieveAuthSession(
        _ authSession: FinancialConnectionsAuthSession
    ) -> Future<FinancialConnectionsAuthSession> {
        return sharedPartnerAuthDataSource.retrieveAuthSession(authSession)
    }
}
