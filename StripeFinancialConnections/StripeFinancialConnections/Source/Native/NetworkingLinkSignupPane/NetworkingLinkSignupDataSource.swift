//
//  NetworkingLinkSignupDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/17/23.
//

import Foundation
@_spi(STP) import StripeCore

protocol NetworkingLinkSignupDataSource: AnyObject {
    var manifest: FinancialConnectionsSessionManifest { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }

    func lookup(emailAddress: String) -> Future<LookupConsumerSessionResponse>
    func saveToLink(emailAddress: String, phoneNumber: String, countryCode: String) -> Future<Void>
}

final class NetworkingLinkSignupDataSourceImplementation: NetworkingLinkSignupDataSource {

    let manifest: FinancialConnectionsSessionManifest
    private let selectedAccountIds: [String]
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient

    // we get this after starting verification
    private var consumerSessionClientSecret: String?

    init(
        manifest: FinancialConnectionsSessionManifest,
        selectedAccountIds: [String],
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.manifest = manifest
        self.selectedAccountIds = selectedAccountIds
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
    }

    func lookup(emailAddress: String) -> Future<LookupConsumerSessionResponse> {
        return apiClient.consumerSessionLookup(emailAddress: emailAddress)
    }

    func saveToLink(emailAddress: String, phoneNumber: String, countryCode: String) -> Future<Void> {
        return apiClient.saveAccountsToLink(
            emailAddress: emailAddress,
            phoneNumber: phoneNumber,  // TODO(kgaidis): double-check how we only support US phone numbers? // ex. "+12345642332"
            country: countryCode,  // ex. "US"
            selectedAccountIds: selectedAccountIds,
            consumerSessionClientSecret: nil,
            clientSecret: clientSecret
        )
        .chained { _ in
            return Promise(value: ())
        }
    }
}
