//
//  InstitutionDataSource.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 6/8/22.
//

import Foundation
@_spi(STP) import StripeCore

protocol InstitutionDataSource: AnyObject {
    
    func search(query: String?) -> Future<[FinancialConnectionsInstitution]>
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
    
    func search(query: String?) -> Future<[FinancialConnectionsInstitution]> {
        guard let text = query, text.count > 0 else {
            return featuredInstitutions()
   
        }
        return api.fetchInstitutions(clientSecret: clientSecret, query: text).chained { list in
            return Promise(value: list.data)
        }
    }
    
    private func featuredInstitutions() -> Future<[FinancialConnectionsInstitution]> {
        if let cached = cachedFeaturedInstitutions {
            return Promise(value: cached)
        }
        return api.fetchFeaturedInstitutions(clientSecret: clientSecret).chained { [weak self] list in
            self?.cachedFeaturedInstitutions = list.data
            return Promise(value: list.data)
        }
    }
}
