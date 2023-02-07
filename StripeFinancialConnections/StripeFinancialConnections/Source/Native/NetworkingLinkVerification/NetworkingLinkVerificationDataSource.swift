//
//  NetworkingLinkVerificationDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/7/23.
//

import Foundation
@_spi(STP) import StripeCore

protocol NetworkingLinkVerificationDataSource: AnyObject {
    var manifest: FinancialConnectionsSessionManifest { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }
    
    func startVerificationSession() -> Future<Void>
}

final class NetworkingLinkVerificationDataSourceImplementation: NetworkingLinkVerificationDataSource {

    private let accountholderCustomerEmailAddress: String
    let manifest: FinancialConnectionsSessionManifest
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient

    init(
        accountholderCustomerEmailAddress: String,
        manifest: FinancialConnectionsSessionManifest,
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.accountholderCustomerEmailAddress = accountholderCustomerEmailAddress
        self.manifest = manifest
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
    }
    
    func startVerificationSession() -> Future<Void> {
        apiClient
            .consumerSessionLookup(
                emailAddress: accountholderCustomerEmailAddress
            )
            .chained { _ in
                return Promise(value: ())
            }
        // TODO(kgaidis): chain more API calls
//            .chained { lookupConsumerSessionResponse in
//
//            }
    }
}
