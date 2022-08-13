//
//  SuccessDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/12/22.
//

import Foundation
@_spi(STP) import StripeCore

protocol SuccessDataSource: AnyObject {
    func completeFinancialConnectionsSession() -> Promise<StripeAPI.FinancialConnectionsSession>
}

final class SuccessDataSourceImplementation: SuccessDataSource {
    
    let institution: FinancialConnectionsInstitution
    let numberOfAccountsLinked: Int
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    
    init(
        institution: FinancialConnectionsInstitution,
        numberOfAccountsLinked: Int,
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String
    ) {
        self.institution = institution
        self.numberOfAccountsLinked = numberOfAccountsLinked
        self.apiClient = apiClient
        self.clientSecret = clientSecret
    }
    
    func completeFinancialConnectionsSession() -> Promise<StripeAPI.FinancialConnectionsSession> {
        return apiClient.completeFinancialConnectionsSession(clientSecret: clientSecret)
    }
}
