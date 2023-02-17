//
//  NetworkingLinkStepUpVerificationDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/16/23.
//

import Foundation
@_spi(STP) import StripeCore

protocol NetworkingLinkStepUpVerificationDataSource: AnyObject {
    var consumerSession: ConsumerSessionData { get }
    var manifest: FinancialConnectionsSessionManifest { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }

    func lookupConsumerSession() -> Future<LookupConsumerSessionResponse>
    func startVerificationSession() -> Future<ConsumerSessionResponse>
    func confirmVerificationSession(otpCode: String) -> Future<ConsumerSessionResponse>
    func markLinkVerified() -> Future<FinancialConnectionsSessionManifest>
//    func fetchNetworkedAccounts() -> Future<FinancialConnectionsNetworkedAccountsResponse>
}

final class NetworkingLinkStepUpVerificationDataSourceImplementation: NetworkingLinkStepUpVerificationDataSource {

    private(set) var consumerSession: ConsumerSessionData
    let manifest: FinancialConnectionsSessionManifest
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient

    init(
        consumerSession: ConsumerSessionData,
        manifest: FinancialConnectionsSessionManifest,
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.consumerSession = consumerSession
        self.manifest = manifest
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
    }
    
    func lookupConsumerSession() -> Future<LookupConsumerSessionResponse> {
        return apiClient
            .consumerSessionLookup(
                emailAddress: consumerSession.emailAddress
            )
            .chained { [weak self] lookupConsumerSessionResponse in
                if let consumerSession = lookupConsumerSessionResponse.consumerSession {
                    self?.consumerSession = consumerSession
                }
                return Promise(value: lookupConsumerSessionResponse)
            }
    }

    func startVerificationSession() -> Future<ConsumerSessionResponse> {
        return apiClient.consumerSessionStartVerification(
            emailAddress: consumerSession.emailAddress,
            otpType: "EMAIL",
            customEmailType: "NETWORKED_CONNECTIONS_OTP_EMAIL",
            connectionsMerchantName: manifest.businessName,
            consumerSessionClientSecret: consumerSession.clientSecret
        )
        .chained { [weak self] consumerSessionResponse in
            self?.consumerSession = consumerSessionResponse.consumerSession
            return Promise(value: consumerSessionResponse)
        }
    }

    func confirmVerificationSession(otpCode: String) -> Future<ConsumerSessionResponse> {
        return apiClient.consumerSessionConfirmVerification(
            otpCode: otpCode,
            otpType: "SMS",
            consumerSessionClientSecret: consumerSession.clientSecret
        )
    }

    func markLinkVerified() -> Future<FinancialConnectionsSessionManifest> {
        return apiClient.markLinkVerified(clientSecret: clientSecret)
    }

//    func fetchNetworkedAccounts() -> Future<FinancialConnectionsNetworkedAccountsResponse> {
//        return apiClient.fetchNetworkedAccounts(
//            clientSecret: clientSecret,
//            consumerSessionClientSecret: consumerSessionClientSecret
//        )
//    }
}
