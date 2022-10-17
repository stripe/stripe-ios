//
//  AccountPickerDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/5/22.
//

import Foundation
@_spi(STP) import StripeCore

protocol AccountPickerDataSourceDelegate: AnyObject {
    func accountPickerDataSource(
        _ dataSource: AccountPickerDataSource,
        didSelectAccounts selectedAccounts: [FinancialConnectionsPartnerAccount]
    )
}

protocol AccountPickerDataSource: AnyObject {
    
    var delegate: AccountPickerDataSourceDelegate? { get set }
    var manifest: FinancialConnectionsSessionManifest { get }
    var authorizationSession: FinancialConnectionsAuthorizationSession { get }
    var institution: FinancialConnectionsInstitution { get }
    var selectedAccounts: [FinancialConnectionsPartnerAccount] { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }
    
    func pollAuthSessionAccounts() -> Future<FinancialConnectionsAuthorizationSessionAccounts>
    func updateSelectedAccounts(_ selectedAccounts: [FinancialConnectionsPartnerAccount])
    func selectAuthSessionAccounts() -> Promise<FinancialConnectionsAuthorizationSessionAccounts>
}

final class AccountPickerDataSourceImplementation: AccountPickerDataSource {
    
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    let authorizationSession: FinancialConnectionsAuthorizationSession
    let manifest: FinancialConnectionsSessionManifest
    let institution: FinancialConnectionsInstitution
    let analyticsClient: FinancialConnectionsAnalyticsClient
    
    private(set) var selectedAccounts: [FinancialConnectionsPartnerAccount] = [] {
        didSet {
            delegate?.accountPickerDataSource(self, didSelectAccounts: selectedAccounts)
        }
    }
    weak var delegate: AccountPickerDataSourceDelegate?
    
    init(
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String,
        authorizationSession: FinancialConnectionsAuthorizationSession,
        manifest: FinancialConnectionsSessionManifest,
        institution: FinancialConnectionsInstitution,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.authorizationSession = authorizationSession
        self.manifest = manifest
        self.institution = institution
        self.analyticsClient = analyticsClient
    }
    
    func pollAuthSessionAccounts() -> Future<FinancialConnectionsAuthorizationSessionAccounts> {
        return apiClient.fetchAuthSessionAccounts(
            clientSecret: clientSecret,
            authSessionId: authorizationSession.id,
            initialPollDelay: AuthSessionAccountsInitialPollDelay(forFlow: authorizationSession.flow)
        )
    }
    
    func updateSelectedAccounts(_ selectedAccounts: [FinancialConnectionsPartnerAccount]) {
        self.selectedAccounts = selectedAccounts
    }
    
    func selectAuthSessionAccounts() -> Promise<FinancialConnectionsAuthorizationSessionAccounts> {
        return apiClient.selectAuthSessionAccounts(
            clientSecret: clientSecret,
            authSessionId: authorizationSession.id,
            selectedAccountIds: selectedAccounts.map({ $0.id })
        )
    }
}

private func AuthSessionAccountsInitialPollDelay(
    forFlow flow: FinancialConnectionsAuthorizationSession.Flow?
) -> TimeInterval {
    let defaultInitialPollDelay: TimeInterval = 1.75
    guard let flow = flow else {
        return defaultInitialPollDelay
    }
    switch flow {
    case .testmode:
        fallthrough
    case .testmodeOauth:
        fallthrough
    case .testmodeOauthWebview:
        fallthrough
    case .finicityConnectV2Lite:
        // Post auth flow, Finicity non-OAuth account retrieval latency is extremely quick - p90 < 1sec.
        return 0
    case .mxConnect:
        // 10 account retrieval latency on MX non-OAuth sessions is currently 460 ms
        return 0.5
    default:
        return defaultInitialPollDelay
    }
}
