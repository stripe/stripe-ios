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
    var institution: FinancialConnectionsInstitution { get }
    var selectedAccounts: [FinancialConnectionsPartnerAccount] { get }
    
    func pollAuthSessionAccounts() -> Promise<FinancialConnectionsAuthorizationSessionAccounts>
    func updateSelectedAccounts(_ selectedAccounts: [FinancialConnectionsPartnerAccount])
    func selectAuthSessionAccounts() -> Promise<FinancialConnectionsAuthorizationSessionAccounts>
}

final class AccountPickerDataSourceImplementation: AccountPickerDataSource {
    
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    private let authorizationSession: FinancialConnectionsAuthorizationSession
    let manifest: FinancialConnectionsSessionManifest
    let institution: FinancialConnectionsInstitution
    
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
        institution: FinancialConnectionsInstitution
    ) {
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.authorizationSession = authorizationSession
        self.manifest = manifest
        self.institution = institution
    }
    
    func pollAuthSessionAccounts() -> Promise<FinancialConnectionsAuthorizationSessionAccounts> {
        let promise = Promise<FinancialConnectionsAuthorizationSessionAccounts>()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in // TODO(kgaidis): implement polling instead of a delay
            guard let self = self else { return }
            self.apiClient.fetchAuthSessionAccounts(
                clientSecret: self.clientSecret,
                authSessionId: self.authorizationSession.id
            )
            .observe(on: DispatchQueue.main) { result in
                promise.fullfill(with: result)
            }
        }
        return promise
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
