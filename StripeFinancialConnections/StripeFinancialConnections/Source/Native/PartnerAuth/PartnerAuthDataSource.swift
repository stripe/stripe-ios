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
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }
    var pendingAuthSession: FinancialConnectionsAuthSession? { get }
    var disableAuthSessionRetrieval: Bool { get }
    var isNetworkingRelinkSession: Bool { get }

    func createAuthSession() -> Future<FinancialConnectionsAuthSession>
    func authorizeAuthSession(_ authSession: FinancialConnectionsAuthSession) -> Future<FinancialConnectionsAuthSession>
    func cancelPendingAuthSessionIfNeeded()
    func recordAuthSessionEvent(eventName: String, authSessionId: String)
    func clearReturnURL(authSession: FinancialConnectionsAuthSession, authURL: String) -> Future<FinancialConnectionsAuthSession>
    func retrieveAuthSession(_ authSession: FinancialConnectionsAuthSession) -> Future<FinancialConnectionsAuthSession>
    func pollAuthSession(_ authSession: FinancialConnectionsAuthSession) -> Future<FinancialConnectionsAuthSession>
}

final class PartnerAuthDataSourceImplementation: PartnerAuthDataSource {

    let institution: FinancialConnectionsInstitution
    let manifest: FinancialConnectionsSessionManifest
    let returnURL: String?
    private let apiClient: any FinancialConnectionsAPI
    private let clientSecret: String
    private let relinkAuthorization: String?
    let analyticsClient: FinancialConnectionsAnalyticsClient
    var disableAuthSessionRetrieval: Bool {
        return manifest.features?["bank_connections_disable_defensive_auth_session_retrieval_on_complete"] == true
    }

    var isNetworkingRelinkSession: Bool {
        return relinkAuthorization != nil
    }

    // a "pending" auth session is a session which has started
    // BUT the session is still yet-to-be authorized
    //
    // in other words, a `pendingAuthSession` is up for being
    // cancelled unless the user successfully authorizes
    private(set) var pendingAuthSession: FinancialConnectionsAuthSession?

    init(
        authSession: FinancialConnectionsAuthSession?,
        institution: FinancialConnectionsInstitution,
        manifest: FinancialConnectionsSessionManifest,
        relinkAuthorization: String?,
        returnURL: String?,
        apiClient: any FinancialConnectionsAPI,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.pendingAuthSession = authSession
        self.institution = institution
        self.manifest = manifest
        self.returnURL = returnURL
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
        self.relinkAuthorization = relinkAuthorization
    }

    func createAuthSession() -> Future<FinancialConnectionsAuthSession> {
        if let relinkAuthorization {
            return apiClient.repairAuthSession(
                clientSecret: clientSecret,
                coreAuthorization: relinkAuthorization
            ).chained { [weak self] (repairSession: FinancialConnectionsRepairSession) in
                let authSession = FinancialConnectionsAuthSession(
                    id: repairSession.id,
                    flow: repairSession.flow,
                    institutionSkipAccountSelection: nil,
                    nextPane: .success,
                    showPartnerDisclosure: nil,
                    skipAccountSelection: nil,
                    url: repairSession.url,
                    isOauth: repairSession.isOauth,
                    display: repairSession.display
                )
                self?.pendingAuthSession = authSession
                return Promise(value: authSession)
            }
        } else {
            return apiClient.createAuthSession(
                clientSecret: clientSecret,
                institutionId: institution.id
            ).chained { [weak self] (authSession: FinancialConnectionsAuthSession) in
                self?.pendingAuthSession = authSession
                return Promise(value: authSession)
            }
        }
    }

    func clearReturnURL(authSession: FinancialConnectionsAuthSession, authURL: String) -> Future<FinancialConnectionsAuthSession> {
        let promise = Promise<FinancialConnectionsAuthSession>()

        apiClient
            .synchronize(
                clientSecret: clientSecret,
                returnURL: nil,
                initialSynchronize: false
            )
            .observe { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    let copiedSession = FinancialConnectionsAuthSession(id: authSession.id,
                                                                        flow: authSession.flow,
                                                                        institutionSkipAccountSelection: authSession.institutionSkipAccountSelection,
                                                                        nextPane: authSession.nextPane,
                                                                        showPartnerDisclosure: authSession.showPartnerDisclosure,
                                                                        skipAccountSelection: authSession.skipAccountSelection,
                                                                        url: authURL,
                                                                        isOauth: authSession.isOauth,
                                                                        display: authSession.display)
                    self.pendingAuthSession = copiedSession
                    promise.fullfill(with: .success(copiedSession))
                case .failure(let error):
                    self.analyticsClient
                        .logUnexpectedError(
                            error,
                            errorName: "SynchronizeClearReturnURLError",
                            pane: .partnerAuth
                        )
                    promise.reject(with: error)
                }
            }

        return promise
    }

    func cancelPendingAuthSessionIfNeeded() {
        guard let pendingAuthSession = pendingAuthSession else {
            return
        }
        self.pendingAuthSession = nil
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

    func pollAuthSession(_ authSession: FinancialConnectionsAuthSession) -> Future<FinancialConnectionsAuthSession> {
        return apiClient.retrieveAuthSessionPolling(
            clientSecret: clientSecret,
            authSessionId: authSession.id
        )
    }

    func recordAuthSessionEvent(
        eventName: String,
        authSessionId: String
    ) {
        guard shouldRecordAuthSessionEvent() else {
            // on Stripe SDK Core analytics client we don't send events
            // for simulator or tests, so don't send these either...
            return
        }

        apiClient.recordAuthSessionEvent(
            clientSecret: clientSecret,
            authSessionId: authSessionId,
            eventNamespace: "partner-auth-lifecycle",
            eventName: eventName
        )
        .observe { _ in
            // we don't do anything with the event response
        }
    }

    func retrieveAuthSession(
        _ authSession: FinancialConnectionsAuthSession
    ) -> Future<FinancialConnectionsAuthSession> {
        return apiClient.retrieveAuthSession(
            clientSecret: clientSecret,
            authSessionId: authSession.id
        ).chained { [weak self] (authSession: FinancialConnectionsAuthSession) in
            // update the `pendingAuthSession` with the latest from the server
            self?.pendingAuthSession = authSession
            return Promise(value: authSession)
        }
    }

    private func shouldRecordAuthSessionEvent() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return isNetworkingRelinkSession == false && NSClassFromString("XCTest") == nil
        #endif
    }
}
