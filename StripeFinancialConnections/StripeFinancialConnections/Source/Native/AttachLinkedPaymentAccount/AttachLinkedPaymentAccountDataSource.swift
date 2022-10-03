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
        return apiClient.attachLinkedAccountIdToLinkAccountSession(
            clientSecret: clientSecret,
            linkedAccountId: linkedAccountId,
            consumerSessionClientSecret: nil // used for Link
        )
    }
}
