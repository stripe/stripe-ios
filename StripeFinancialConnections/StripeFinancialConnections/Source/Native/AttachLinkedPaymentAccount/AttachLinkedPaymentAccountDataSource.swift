//
//  AttachLinkedPaymentAccountDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/28/22.
//

import Foundation
@_spi(STP) import StripeCore

protocol AttachLinkedPaymentAccountDataSourceDelegate: AnyObject {
    func AttachLinkedPaymentAccountDataSource(
        _ dataSource: AttachLinkedPaymentAccountDataSource,
        didSelectAccounts selectedAccounts: [FinancialConnectionsPartnerAccount]
    )
}

protocol AttachLinkedPaymentAccountDataSource: AnyObject {
    
    var delegate: AttachLinkedPaymentAccountDataSourceDelegate? { get set }
    var manifest: FinancialConnectionsSessionManifest { get }
    var authorizationSession: FinancialConnectionsAuthorizationSession { get }
    var institution: FinancialConnectionsInstitution { get }
    var selectedAccounts: [FinancialConnectionsPartnerAccount] { get }
    
    func attachLinkedAccountIdToLinkAccountSession() -> Future<FinancialConnectionsPaymentAccountResource>
}

final class AttachLinkedPaymentAccountDataSourceImplementation: AttachLinkedPaymentAccountDataSource {
    
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    let authorizationSession: FinancialConnectionsAuthorizationSession
    let manifest: FinancialConnectionsSessionManifest
    let institution: FinancialConnectionsInstitution
    let selectedAccounts: [FinancialConnectionsPartnerAccount]
    
    weak var delegate: AttachLinkedPaymentAccountDataSourceDelegate?
    
    init(
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String,
        authorizationSession: FinancialConnectionsAuthorizationSession,
        manifest: FinancialConnectionsSessionManifest,
        institution: FinancialConnectionsInstitution,
        selectedAccounts: [FinancialConnectionsPartnerAccount]
    ) {
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.authorizationSession = authorizationSession
        self.manifest = manifest
        self.institution = institution
        self.selectedAccounts = selectedAccounts
    }
    
    func attachLinkedAccountIdToLinkAccountSession() -> Future<FinancialConnectionsPaymentAccountResource> {
        let promise = Promise<FinancialConnectionsPaymentAccountResource>()
        // TODO(kgaidis): implement polling instead of a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else { return }
            self.apiClient.attachLinkedAccountIdToLinkAccountSession(
                clientSecret: self.clientSecret,
                linkedAccountId: self.selectedAccounts.first!.linkedAccountId!, // TODO(kgaidis): fix to be better
                consumerSessionClientSecret: nil // used for Link
            ).observe(on: DispatchQueue.main) { result in
                promise.fullfill(with: result)
            }
        }
        return promise
    }
}
