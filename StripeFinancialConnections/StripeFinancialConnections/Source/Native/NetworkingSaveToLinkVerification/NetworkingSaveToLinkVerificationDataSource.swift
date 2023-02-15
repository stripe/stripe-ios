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

    func startVerificationSession() -> Future<ConsumerSessionResponse>
    func confirmVerificationSession(otpCode: String) -> Future<ConsumerSessionResponse>
    func markLinkVerified() -> Future<FinancialConnectionsSessionManifest>
    func saveToLink() -> Future<Void>
}

final class NetworkingSaveToLinkVerificationDataSourceImplementation: NetworkingSaveToLinkVerificationDataSource {

    private(set) var consumerSession: ConsumerSessionData
    private let selectedAccountIds: [String]
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient

    init(
        consumerSession: ConsumerSessionData,
        selectedAccountIds: [String],
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.consumerSession = consumerSession
        self.selectedAccountIds = selectedAccountIds
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
    }

    func startVerificationSession() -> Future<ConsumerSessionResponse> {
        apiClient
            .consumerSessionLookup(
                emailAddress: consumerSession.emailAddress
            )
            .chained { [weak self] (lookupConsumerSessionResponse: LookupConsumerSessionResponse) in
                guard let self = self else {
                    return Promise(error: FinancialConnectionsSheetError.unknown(debugDescription: "data source deallocated"))
                }
                if let consumerSession = lookupConsumerSessionResponse.consumerSession {
                    self.consumerSession = consumerSession
                    return self.apiClient.consumerSessionStartVerification(
                        emailAddress: consumerSession.emailAddress,
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
            selectedAccountIds: selectedAccountIds,
            consumerSessionClientSecret: consumerSession.clientSecret,
            clientSecret: clientSecret
        )
        .chained { _ in
            return Promise(value: ())
        }
    }
}
