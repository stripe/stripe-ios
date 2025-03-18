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
    var featuredInstitutions: [FinancialConnectionsInstitution] { get }

    func fetchInstitutions(searchQuery: String) -> Future<FinancialConnectionsInstitutionSearchResultResource>
    func fetchFeaturedInstitutions() -> Future<[FinancialConnectionsInstitution]>
    func createAuthSession(institutionId: String) -> Future<FinancialConnectionsAuthSession>
    func selectInstitution(institutionId: String) -> Future<FinancialConnectionsSelectInstitution>
}

class InstitutionAPIDataSource: InstitutionDataSource {

    // MARK: - Properties

    let manifest: FinancialConnectionsSessionManifest
    private let apiClient: any FinancialConnectionsAPI
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient
    var featuredInstitutions: [FinancialConnectionsInstitution] = []

    // MARK: - Init

    init(
        manifest: FinancialConnectionsSessionManifest,
        apiClient: any FinancialConnectionsAPI,
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
            .chained { [weak self] list in
                let featuredInstitutions = list.data
                self?.featuredInstitutions = featuredInstitutions
                return Promise(value: featuredInstitutions)
            }
    }

    func createAuthSession(institutionId: String) -> Future<FinancialConnectionsAuthSession> {
        return apiClient.createAuthSession(
            clientSecret: clientSecret,
            institutionId: institutionId
        )
    }

    func selectInstitution(institutionId: String) -> Future<FinancialConnectionsSelectInstitution> {
        return apiClient.selectInstitution(
            clientSecret: clientSecret,
            institutionId: institutionId
        )
    }
}
