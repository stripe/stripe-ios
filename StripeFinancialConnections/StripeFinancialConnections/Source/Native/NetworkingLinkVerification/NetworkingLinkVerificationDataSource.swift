//
//  NetworkingLinkVerificationDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/7/23.
//

import Foundation
@_spi(STP) import StripeCore

protocol NetworkingLinkVerificationDataSource: AnyObject {
    var accountholderCustomerEmailAddress: String { get }
    var manifest: FinancialConnectionsSessionManifest { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }

    func startVerificationSession() -> Future<ConsumerSessionResponse>
    func confirmVerificationSession(otpCode: String) -> Future<ConsumerSessionResponse>
    func markLinkVerified() -> Future<FinancialConnectionsSessionManifest>
}

final class NetworkingLinkVerificationDataSourceImplementation: NetworkingLinkVerificationDataSource {

    let accountholderCustomerEmailAddress: String
    let manifest: FinancialConnectionsSessionManifest
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient

    private var consumerSessionClientSecret: String?

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
                    self.consumerSessionClientSecret = consumerSessionClientSecret
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

    func confirmVerificationSession(otpCode: String) -> Future<ConsumerSessionResponse> {
        guard let consumerSessionClientSecret = consumerSessionClientSecret else {
            return Promise(error: FinancialConnectionsSheetError.unknown(debugDescription: "invalid confirmVerificationSession state: no consumerSessionClientSecret"))
        }
        return apiClient.consumerSessionConfirmVerification(
            otpCode: otpCode,
            otpType: "SMS",
            consumerSessionClientSecret: consumerSessionClientSecret
        )
    }

    func markLinkVerified() -> Future<FinancialConnectionsSessionManifest> {
        return apiClient.markLinkVerified(clientSecret: clientSecret)
    }
}
