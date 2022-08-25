//
//  ManualEntryDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/24/22.
//

import Foundation

protocol ManualEntryDataSource: AnyObject {
    
    var manifest: FinancialConnectionsSessionManifest { get }
}

final class ManualEntryDataSourceImplementation: ManualEntryDataSource {
    
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    let manifest: FinancialConnectionsSessionManifest
    
    init(
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String,
        manifest: FinancialConnectionsSessionManifest
    ) {
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.manifest = manifest
    }
    
//    func attachPaymentAccountToLinkAccountSession() -> Promise<Void> {
//
//    }
}
