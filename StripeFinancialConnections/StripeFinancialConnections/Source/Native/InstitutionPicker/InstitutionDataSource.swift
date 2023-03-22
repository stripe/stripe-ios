//
//  InstitutionDataSource.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 6/8/22.
//

import Foundation
@_spi(STP) import StripeCore

protocol InstitutionDataSource: AnyObject {

    var manifest: FinancialConnectionsSessionManifest { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }

    func fetchInstitutions(searchQuery: String) -> Future<FinancialConnectionsInstitutionSearchResultResource>
    func fetchFeaturedInstitutions() -> Future<[FinancialConnectionsInstitution]>
}

class InstitutionAPIDataSource: InstitutionDataSource {

    // MARK: - Properties

    let manifest: FinancialConnectionsSessionManifest
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient

    // MARK: - Init

    init(
        manifest: FinancialConnectionsSessionManifest,
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.manifest = manifest
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
    }

    // MARK: - InstitutionDataSource

    func fetchInstitutions(searchQuery: String) -> Future<FinancialConnectionsInstitutionSearchResultResource> {
        return apiClient.fetchInstitutions(
            clientSecret: clientSecret,
            query: searchQuery
        )
    }

    func fetchFeaturedInstitutions() -> Future<[FinancialConnectionsInstitution]> {
        return apiClient.fetchFeaturedInstitutions(clientSecret: clientSecret)
            .chained { list in
                return Promise(value: list.data)
            }
    }
}
