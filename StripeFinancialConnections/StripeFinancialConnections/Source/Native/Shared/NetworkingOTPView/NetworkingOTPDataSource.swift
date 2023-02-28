//
//  NetworkingOTPDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/28/23.
//

import Foundation
@_spi(STP) import StripeCore

protocol NetworkingOTPDataSource: AnyObject {
    var otpType: String { get }
    var emailAddress: String { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }
    var consumerSession: ConsumerSessionData? { get }

    func lookupConsumerSession() -> Future<LookupConsumerSessionResponse>
    func startVerificationSession() -> Future<ConsumerSessionResponse>
    func confirmVerificationSession(otpCode: String) -> Future<ConsumerSessionResponse>
}

final class NetworkingOTPDataSourceImplementation: NetworkingOTPDataSource {

    let otpType: String
    let emailAddress: String
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient

    private(set) var consumerSession: ConsumerSessionData?

    init(
        otpType: String,
        emailAddress: String,
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.otpType = otpType
        self.emailAddress = emailAddress
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
    }

    func lookupConsumerSession() -> Future<LookupConsumerSessionResponse> {
        apiClient
            .consumerSessionLookup(
                emailAddress: emailAddress
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
            emailAddress: emailAddress,
            otpType: otpType,
            customEmailType: nil,
            connectionsMerchantName: nil,
            consumerSessionClientSecret: consumerSessionClientSecret
        ).chained { [weak self] consumerSessionResponse in
            self?.consumerSession = consumerSessionResponse.consumerSession
            return Promise(value: consumerSessionResponse)
        }
    }

    func confirmVerificationSession(otpCode: String) -> Future<ConsumerSessionResponse> {
        guard let consumerSessionClientSecret = consumerSession?.clientSecret else {
            return Promise(error: FinancialConnectionsSheetError.unknown(debugDescription: "invalid confirmVerificationSession state: no consumerSessionClientSecret"))
        }
        return apiClient.consumerSessionConfirmVerification(
            otpCode: otpCode,
            otpType: otpType,
            consumerSessionClientSecret: consumerSessionClientSecret
        ).chained { [weak self] consumerSessionResponse in
            self?.consumerSession = consumerSessionResponse.consumerSession
            return Promise(value: consumerSessionResponse)
        }
    }
}
