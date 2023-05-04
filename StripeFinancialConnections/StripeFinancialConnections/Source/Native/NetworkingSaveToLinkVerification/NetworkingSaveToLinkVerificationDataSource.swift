//
//  NetworkingSaveToLinkVerificationDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/14/23.
//

import Foundation
@_spi(STP) import StripeCore

protocol NetworkingSaveToLinkVerificationDataSource: AnyObject {
    var consumerSession: ConsumerSessionData { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }
    var networkingOTPDataSource: NetworkingOTPDataSource { get }

    func startVerificationSession() -> Future<ConsumerSessionResponse>
    func confirmVerificationSession(otpCode: String) -> Future<ConsumerSessionResponse>
    func markLinkVerified() -> Future<FinancialConnectionsSessionManifest>
    func saveToLink() -> Future<Void>
}

final class NetworkingSaveToLinkVerificationDataSourceImplementation: NetworkingSaveToLinkVerificationDataSource {

    private(set) var consumerSession: ConsumerSessionData
    private let selectedAccountId: String
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient
    let networkingOTPDataSource: NetworkingOTPDataSource

    init(
        consumerSession: ConsumerSessionData,
        selectedAccountId: String,
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.consumerSession = consumerSession
        self.selectedAccountId = selectedAccountId
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
        let networkingOTPDataSource = NetworkingOTPDataSourceImplementation(
            otpType: "SMS",
            emailAddress: consumerSession.emailAddress,
            customEmailType: nil,
            connectionsMerchantName: nil,
            pane: .networkingSaveToLinkVerification,
            consumerSession: consumerSession,
            apiClient: apiClient,
            clientSecret: clientSecret,
            analyticsClient: analyticsClient
        )
        self.networkingOTPDataSource = networkingOTPDataSource
        networkingOTPDataSource.delegate = self
    }

    func startVerificationSession() -> Future<ConsumerSessionResponse> {
        apiClient
            .consumerSessionLookup(
                emailAddress: consumerSession.emailAddress,
                clientSecret: clientSecret
            )
            .chained { [weak self] (lookupConsumerSessionResponse: LookupConsumerSessionResponse) in
                guard let self = self else {
                    return Promise(error: FinancialConnectionsSheetError.unknown(debugDescription: "data source deallocated"))
                }
                if let consumerSession = lookupConsumerSessionResponse.consumerSession {
                    self.consumerSession = consumerSession
                    return self.apiClient.consumerSessionStartVerification(
                        otpType: "SMS",
                        customEmailType: nil,
                        connectionsMerchantName: nil,
                        consumerSessionClientSecret: consumerSession.clientSecret
                    )
                } else {
                    return Promise(error: FinancialConnectionsSheetError.unknown(debugDescription: "invalid consumerSessionLookup response: no consumerSession.clientSecret"))
                }
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

    func saveToLink() -> Future<Void> {
        return apiClient.saveAccountsToLink(
            emailAddress: nil,
            phoneNumber: nil,
            country: nil,
            selectedAccountIds: [selectedAccountId],
            consumerSessionClientSecret: consumerSession.clientSecret,
            clientSecret: clientSecret
        )
        .chained { _ in
            return Promise(value: ())
        }
    }
}

// MARK: - NetworkingOTPDataSourceDelegate

extension NetworkingSaveToLinkVerificationDataSourceImplementation: NetworkingOTPDataSourceDelegate {

    func networkingOTPDataSource(_ dataSource: NetworkingOTPDataSource, didUpdateConsumerSession consumerSession: ConsumerSessionData) {
        self.consumerSession = consumerSession
    }
}
