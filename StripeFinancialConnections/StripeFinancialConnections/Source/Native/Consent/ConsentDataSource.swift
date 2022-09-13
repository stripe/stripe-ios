//
//  ConsentDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/13/22.
//

import Foundation
@_spi(STP) import StripeCore

protocol ConsentDataSource: AnyObject {
    var manifest: FinancialConnectionsSessionManifest { get }
    var consentModel: ConsentModel { get }
    
    func markConsentAcquired() -> Promise<FinancialConnectionsSessionManifest>
}

final class ConsentDataDataSourceImplementation: ConsentDataSource {
    
    let manifest: FinancialConnectionsSessionManifest
    let consentModel: ConsentModel
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    
    init(
        manifest: FinancialConnectionsSessionManifest,
        consentModel: ConsentModel,
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String
    ) {
        self.manifest = manifest
        self.consentModel = consentModel
        self.apiClient = apiClient
        self.clientSecret = clientSecret
    }
    
    func markConsentAcquired() -> Promise<FinancialConnectionsSessionManifest> {
        return apiClient.markConsentAcquired(clientSecret: clientSecret)
    }
}
