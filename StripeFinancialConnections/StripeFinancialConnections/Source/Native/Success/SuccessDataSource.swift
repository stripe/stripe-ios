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
    var linkedAccounts: [FinancialConnectionsPartnerAccount] { get }
    var institution: FinancialConnectionsInstitution { get }
    var showLinkMoreAccountsButton: Bool { get }
    
    func completeFinancialConnectionsSession() -> Promise<StripeAPI.FinancialConnectionsSession>
}

final class SuccessDataSourceImplementation: SuccessDataSource {
    
    let manifest: FinancialConnectionsSessionManifest
    let linkedAccounts: [FinancialConnectionsPartnerAccount]
    let institution: FinancialConnectionsInstitution
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    var showLinkMoreAccountsButton: Bool {
        !manifest.singleAccount && !manifest.disableLinkMoreAccounts && !(manifest.isNetworkingUserFlow ?? false)
    }
    
    init(
        manifest: FinancialConnectionsSessionManifest,
        linkedAccounts: [FinancialConnectionsPartnerAccount],
        institution: FinancialConnectionsInstitution,
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String
    ) {
        self.manifest = manifest
        self.linkedAccounts = linkedAccounts
        self.institution = institution
        self.apiClient = apiClient
        self.clientSecret = clientSecret
    }
    
    func completeFinancialConnectionsSession() -> Promise<StripeAPI.FinancialConnectionsSession> {
        return apiClient.completeFinancialConnectionsSession(clientSecret: clientSecret)
    }
}
