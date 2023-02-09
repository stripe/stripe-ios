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

    func startVerificationSession() -> Future<ConsumerSessionResponse>
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

    func startVerificationSession() -> Future<ConsumerSessionResponse> {
        apiClient
            .consumerSessionLookup(
                emailAddress: accountholderCustomerEmailAddress
            )
            .chained { [weak self] (lookupConsumerSessionResponse: LookupConsumerSessionResponse) in
                guard let self = self else {
                    return Promise(error: FinancialConnectionsSheetError.unknown(debugDescription: "data source deallocated"))
                }
                if let consumerSessionClientSecret = lookupConsumerSessionResponse.consumerSession?.clientSecret {
                    return self.apiClient.consumerSessionStartVerification(
                        emailAddress: self.accountholderCustomerEmailAddress,
                        otpType: "SMS",
                        customEmailType: nil,
                        connectionsMerchantName: nil,
                        consumerSessionClientSecret: consumerSessionClientSecret
                    )
                } else {
                    return Promise(error: FinancialConnectionsSheetError.unknown(debugDescription: "invalid consumerSessionLookup response: no consumerSession.clientSecret"))
                }
            }
    }
}
