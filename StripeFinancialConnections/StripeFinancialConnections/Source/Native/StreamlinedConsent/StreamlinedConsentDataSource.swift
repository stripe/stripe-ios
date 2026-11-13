//
//  StreamlinedConsentDataSource.swift
//  StripeFinancialConnections
//
//  Created by Till Hellmund on 2026-11-05.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

enum StreamlinedConsentResult {
    /// Continue to `manifest.nextPane`.
    case nextPane(manifest: FinancialConnectionsSessionManifest)
    /// The next pane is partner auth, and its auth session was created up front.
    case partnerAuth(
        manifest: FinancialConnectionsSessionManifest,
        authSession: FinancialConnectionsAuthSession
    )
    /// Consent was acquired, but creating the auth session for partner auth failed.
    case authSessionCreationFailed(
        manifest: FinancialConnectionsSessionManifest,
        error: Error
    )
}

protocol StreamlinedConsentDataSource: AnyObject {
    var manifest: FinancialConnectionsSessionManifest { get }
    var streamlinedConsentPane: FinancialConnectionsStreamlinedConsentPane { get }
    var dataAccessNotice: FinancialConnectionsDataAccessNotice? { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }

    /// Marks consent as acquired. If the next pane is partner auth, this also creates the auth
    /// session for the selected institution, so we know whether to present partner auth as a sheet.
    /// Fails only if marking consent fails.
    func acceptConsent() -> Future<StreamlinedConsentResult>
}

final class StreamlinedConsentDataSourceImplementation: StreamlinedConsentDataSource {
    let manifest: FinancialConnectionsSessionManifest
    let streamlinedConsentPane: FinancialConnectionsStreamlinedConsentPane
    let analyticsClient: FinancialConnectionsAnalyticsClient

    private let institution: FinancialConnectionsInstitution?
    private let consentPaneDataAccessNotice: FinancialConnectionsDataAccessNotice?
    private let apiClient: any FinancialConnectionsAPI
    private let clientSecret: String

    var dataAccessNotice: FinancialConnectionsDataAccessNotice? {
        // Prefer the regular consent pane's notice so this pane shows the same notice as
        // the account picker, falling back to the streamlined consent pane's notice.
        return consentPaneDataAccessNotice ?? streamlinedConsentPane.dataAccessNotice
    }

    init(
        manifest: FinancialConnectionsSessionManifest,
        streamlinedConsentPane: FinancialConnectionsStreamlinedConsentPane,
        institution: FinancialConnectionsInstitution?,
        consentPaneDataAccessNotice: FinancialConnectionsDataAccessNotice?,
        apiClient: any FinancialConnectionsAPI,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.manifest = manifest
        self.streamlinedConsentPane = streamlinedConsentPane
        self.institution = institution
        self.consentPaneDataAccessNotice = consentPaneDataAccessNotice
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
    }

    func acceptConsent() -> Future<StreamlinedConsentResult> {
        let apiClient = apiClient
        let clientSecret = clientSecret
        let institution = institution
        return apiClient.markConsentAcquired(clientSecret: clientSecret)
            .chained { manifest -> Future<StreamlinedConsentResult> in
                // Like the institution picker, create the auth session up front so that
                // we know whether to present the OAuth prepane as a sheet.
                guard manifest.nextPane == .partnerAuth, let institution else {
                    return Promise(value: .nextPane(manifest: manifest))
                }

                let promise = Promise<StreamlinedConsentResult>()
                apiClient.createAuthSession(clientSecret: clientSecret, institutionId: institution.id)
                    .observe { result in
                        switch result {
                        case .success(let authSession):
                            promise.resolve(with: .partnerAuth(manifest: manifest, authSession: authSession))
                        case .failure(let error):
                            promise.resolve(with: .authSessionCreationFailed(manifest: manifest, error: error))
                        }
                    }
                return promise
            }
    }
}
