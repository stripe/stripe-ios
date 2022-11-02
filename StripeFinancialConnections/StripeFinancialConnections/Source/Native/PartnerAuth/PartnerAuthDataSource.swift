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
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }
    
    func createAuthSession() -> Future<FinancialConnectionsAuthorizationSession>
    func authorizeAuthSession(_ authorizationSession: FinancialConnectionsAuthorizationSession) -> Future<FinancialConnectionsAuthorizationSession>
    func cancelPendingAuthSessionIfNeeded()
    func recordAuthSessionEvent(eventName: String, authSessionId: String)
}

final class PartnerAuthDataSourceImplementation: PartnerAuthDataSource {
    
    let institution: FinancialConnectionsInstitution
    let manifest: FinancialConnectionsSessionManifest
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient
    
    // a "pending" auth session is a session which has started
    // BUT the session is still yet-to-be authorized
    //
    // in other words, a `pendingAuthSession` is up for being
    // cancelled unless the user successfully authorizes
    private var pendingAuthSession: FinancialConnectionsAuthorizationSession?
    
    init(
        institution: FinancialConnectionsInstitution,
        manifest: FinancialConnectionsSessionManifest,
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.institution = institution
        self.manifest = manifest
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
    }
    
    func createAuthSession() -> Future<FinancialConnectionsAuthorizationSession> {
        return apiClient.createAuthorizationSession(
            clientSecret: clientSecret,
            institutionId: institution.id
        ).chained { [weak self] (authSession: FinancialConnectionsAuthorizationSession) in
            self?.pendingAuthSession = authSession
            return Promise(value: authSession)
        }
    }
    
    func cancelPendingAuthSessionIfNeeded() {
        guard let pendingAuthSession = pendingAuthSession else {
            return
        }
        self.pendingAuthSession = nil
        cancelAuthSession(pendingAuthSession)
            .observe { result in
                // we ignore the result because its not important
            }
    }
    
    private func cancelAuthSession(_ authSession: FinancialConnectionsAuthorizationSession) -> Future<FinancialConnectionsAuthorizationSession> {
        return apiClient.cancelAuthSession(
            clientSecret: clientSecret,
            authSessionId: authSession.id
        )
    }
    
    func authorizeAuthSession(_ authSession: FinancialConnectionsAuthorizationSession) -> Future<FinancialConnectionsAuthorizationSession> {
        return apiClient.fetchAuthSessionOAuthResults(
            clientSecret: clientSecret,
            authSessionId: authSession.id
        )
        .chained(on: DispatchQueue.main, using: { [weak self] mixedOAuthParameters in
            guard let self = self else {
                return Promise(error: FinancialConnectionsSheetError.unknown(debugDescription: "\(PartnerAuthDataSourceImplementation.self) deallocated."))
            }
            return self.apiClient.authorizeAuthSession(
                clientSecret: self.clientSecret,
                authSessionId: authSession.id,
                publicToken: mixedOAuthParameters.publicToken
            )
        })
    }
    
    func recordAuthSessionEvent(
        eventName: String,
        authSessionId: String
    ) {
        guard ShouldRecordAuthSessionEvent() else {
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
}

private func ShouldRecordAuthSessionEvent() -> Bool {
#if targetEnvironment(simulator)
return false
#else
return NSClassFromString("XCTest") == nil
#endif
}
