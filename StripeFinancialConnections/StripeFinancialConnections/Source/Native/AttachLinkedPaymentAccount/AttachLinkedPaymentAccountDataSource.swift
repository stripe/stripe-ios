//
//  AttachLinkedPaymentAccountDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/28/22.
//

import Foundation
@_spi(STP) import StripeCore

protocol AttachLinkedPaymentAccountDataSource: AnyObject {
    
    var manifest: FinancialConnectionsSessionManifest { get }
    var institution: FinancialConnectionsInstitution { get }
    
    func attachLinkedAccountIdToLinkAccountSession() -> Future<FinancialConnectionsPaymentAccountResource>
}

final class AttachLinkedPaymentAccountDataSourceImplementation: AttachLinkedPaymentAccountDataSource {
    
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    let manifest: FinancialConnectionsSessionManifest
    let institution: FinancialConnectionsInstitution
    private let linkedAccountId: String
    
    init(
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String,
        manifest: FinancialConnectionsSessionManifest,
        institution: FinancialConnectionsInstitution,
        linkedAccountId: String
    ) {
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.manifest = manifest
        self.institution = institution
        self.linkedAccountId = linkedAccountId
    }
    
    func attachLinkedAccountIdToLinkAccountSession() -> Future<FinancialConnectionsPaymentAccountResource> {
        let promise = Promise<FinancialConnectionsPaymentAccountResource>()
        // TODO(kgaidis): implement polling instead of a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else { return }
            self.apiClient.attachLinkedAccountIdToLinkAccountSession(
                clientSecret: self.clientSecret,
                linkedAccountId: self.linkedAccountId,
                consumerSessionClientSecret: nil // used for Link
            ).observe(on: DispatchQueue.main) { result in
                promise.fullfill(with: result)
            }
        }
        return promise
    }
}
