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
    var consumerSession: ConsumerSessionData? { get }

    func lookupConsumerSession() -> Future<LookupConsumerSessionResponse>
    func startVerificationSession() -> Future<ConsumerSessionResponse>
    func confirmVerificationSession(otpCode: String) -> Future<ConsumerSessionResponse>
    func markLinkVerified() -> Future<FinancialConnectionsSessionManifest>
    func fetchNetworkedAccounts() -> Future<FinancialConnectionsNetworkedAccountsResponse>
}

final class NetworkingLinkVerificationDataSourceImplementation: NetworkingLinkVerificationDataSource {

    let accountholderCustomerEmailAddress: String
    let manifest: FinancialConnectionsSessionManifest
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient

    private(set) var consumerSession: ConsumerSessionData?

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

    func lookupConsumerSession() -> Future<LookupConsumerSessionResponse> {
        apiClient
            .consumerSessionLookup(
                emailAddress: accountholderCustomerEmailAddress
            )
            .chained { [weak self] lookupConsumerSessionResponse in
                self?.consumerSession = lookupConsumerSessionResponse.consumerSession
                return Promise(value: lookupConsumerSessionResponse)
            }
    }
    
    func startVerificationSession() -> Future<ConsumerSessionResponse> {
        guard let consumerSessionClientSecret = consumerSession?.clientSecret else {
            return Promise(error: FinancialConnectionsSheetError.unknown(debugDescription: "invalid startVerificationSession call: no consumerSession.clientSecret"))
        }
        return apiClient.consumerSessionStartVerification(
            emailAddress: self.accountholderCustomerEmailAddress,
            otpType: "SMS",
            customEmailType: nil,
            connectionsMerchantName: nil,
            consumerSessionClientSecret: consumerSessionClientSecret
        )

    }

    func confirmVerificationSession(otpCode: String) -> Future<ConsumerSessionResponse> {
        guard let consumerSessionClientSecret = consumerSession?.clientSecret else {
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

    func fetchNetworkedAccounts() -> Future<FinancialConnectionsNetworkedAccountsResponse> {
        guard let consumerSessionClientSecret = consumerSession?.clientSecret else {
            return Promise(error: FinancialConnectionsSheetError.unknown(debugDescription: "invalid confirmVerificationSession state: no consumerSessionClientSecret"))
        }
        return apiClient.fetchNetworkedAccounts(
            clientSecret: clientSecret,
            consumerSessionClientSecret: consumerSessionClientSecret
        )
    }
}
