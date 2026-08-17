//
//  GenericErrorDataSource.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2026-08-12.
//

import Foundation
@_spi(STP) import StripeCore

final class GenericErrorDataSource {

    let genericErrorPane: FinancialConnectionsGenericErrorPane
    let appearance: FinancialConnectionsAppearance
    let analyticsClient: FinancialConnectionsAnalyticsClient
    private let authSession: FinancialConnectionsAuthSession?
    private let apiClient: any FinancialConnectionsAPI
    private let clientSecret: String

    init(
        genericErrorPane: FinancialConnectionsGenericErrorPane,
        authSession: FinancialConnectionsAuthSession?,
        appearance: FinancialConnectionsAppearance,
        apiClient: any FinancialConnectionsAPI,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.genericErrorPane = genericErrorPane
        self.authSession = authSession
        self.appearance = appearance
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
    }

    /// Cancels the auth session that got us here, since the user is leaving it behind either
    /// way. Mirrors `PartnerAuthDataSource.cancelPendingAuthSessionIfNeeded`.
    func cancelPendingAuthSessionIfNeeded() {
        guard let authSession else {
            return
        }
        apiClient
            .cancelAuthSession(
                clientSecret: clientSecret,
                authSessionId: authSession.id
            )
            .observe { _ in
                // Fire & forget, we can ignore the result here.
            }
    }
}
