//
//  NetworkingSaveToLinkVerificationDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/14/23.
//

import Foundation
@_spi(STP) import StripeCore

protocol NetworkingSaveToLinkVerificationDataSource: AnyObject {
    var manifest: FinancialConnectionsSessionManifest { get }
    var consumerSession: ConsumerSessionData { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }
    var networkingOTPDataSource: NetworkingOTPDataSource { get }

    func startVerificationSession() -> Future<ConsumerSessionResponse>
    func confirmVerificationSession(otpCode: String) -> Future<ConsumerSessionResponse>
    func markLinkVerified() -> Future<FinancialConnectionsSessionManifest>
    func saveToLink() -> Future<String?>
}

final class NetworkingSaveToLinkVerificationDataSourceImplementation: NetworkingSaveToLinkVerificationDataSource {

    let manifest: FinancialConnectionsSessionManifest
    private(set) var consumerSession: ConsumerSessionData
    private let selectedAccounts: [FinancialConnectionsPartnerAccount]
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient
    let networkingOTPDataSource: NetworkingOTPDataSource

    init(
        manifest: FinancialConnectionsSessionManifest,
        consumerSession: ConsumerSessionData,
        selectedAccounts: [FinancialConnectionsPartnerAccount],
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.manifest = manifest
        self.consumerSession = consumerSession
        self.selectedAccounts = selectedAccounts
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

    func saveToLink() -> Future<String?> {
        return apiClient.saveAccountsToNetworkAndLink(
            shouldPollAccounts: !manifest.shouldAttachLinkedPaymentMethod,
            selectedAccounts: selectedAccounts,
            emailAddress: nil,
            phoneNumber: nil,
            country: nil,
            consumerSessionClientSecret: consumerSession.clientSecret,
            clientSecret: clientSecret
        )
        .chained { (_, customSuccessPaneMessage) in
            return Promise(value: customSuccessPaneMessage)
        }
    }
}

// MARK: - NetworkingOTPDataSourceDelegate

extension NetworkingSaveToLinkVerificationDataSourceImplementation: NetworkingOTPDataSourceDelegate {

    func networkingOTPDataSource(_ dataSource: NetworkingOTPDataSource, didUpdateConsumerSession consumerSession: ConsumerSessionData) {
        self.consumerSession = consumerSession
    }
}
