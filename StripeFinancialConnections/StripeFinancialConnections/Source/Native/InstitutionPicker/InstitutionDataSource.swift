//
//  InstitutionDataSource.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 6/8/22.
//

import Foundation
@_spi(STP) import StripeCore

protocol InstitutionDataSource: AnyObject {
    
    func fetchInstitutions(searchQuery: String) -> Future<[FinancialConnectionsInstitution]>
    func fetchFeaturedInstitutions() -> Future<[FinancialConnectionsInstitution]>
}

class InstitutionAPIDataSource: InstitutionDataSource {
    
    // MARK: - Properties
    
    private let api: FinancialConnectionsAPIClient
    private let clientSecret: String
    private var cachedFeaturedInstitutions: [FinancialConnectionsInstitution]?
    
    // MARK: - Init
    
    init(api: FinancialConnectionsAPIClient,
         clientSecret: String) {
        self.api = api
        self.clientSecret = clientSecret
    }

    // MARK: - InstitutionDataSource
    
    func fetchInstitutions(searchQuery: String) -> Future<[FinancialConnectionsInstitution]> {
        return api.fetchInstitutions(clientSecret: clientSecret, query: searchQuery).chained { list in
            return Promise(value: list.data)
        }
    }
    
    func fetchFeaturedInstitutions() -> Future<[FinancialConnectionsInstitution]> {
        if let cached = cachedFeaturedInstitutions {
            return Promise(value: cached)
        }
        return api.fetchFeaturedInstitutions(clientSecret: clientSecret).chained { [weak self] list in
            self?.cachedFeaturedInstitutions = list.data
            return Promise(value: list.data)
        }
    }
}
