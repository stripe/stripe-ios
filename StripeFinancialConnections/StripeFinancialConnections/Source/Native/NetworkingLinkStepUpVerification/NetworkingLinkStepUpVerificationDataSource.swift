//
//  NetworkingLinkStepUpVerificationDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/16/23.
//

import Foundation
@_spi(STP) import StripeCore

protocol NetworkingLinkStepUpVerificationDataSource: AnyObject {
    var manifest: FinancialConnectionsSessionManifest { get }
    var consumerSession: ConsumerSessionData { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }
    var networkingOTPDataSource: NetworkingOTPDataSource { get }

    func markLinkStepUpAuthenticationVerified() -> Future<FinancialConnectionsSessionManifest>
    func selectNetworkedAccount() -> Future<ShareNetworkedAccountsResponse>
}

final class NetworkingLinkStepUpVerificationDataSourceImplementation: NetworkingLinkStepUpVerificationDataSource {

    private(set) var consumerSession: ConsumerSessionData
    private let selectedAccountIds: [String]
    private let apiClient: any FinancialConnectionsAPI
    private let clientSecret: String
    let manifest: FinancialConnectionsSessionManifest
    let analyticsClient: FinancialConnectionsAnalyticsClient
    let networkingOTPDataSource: NetworkingOTPDataSource

    init(
        consumerSession: ConsumerSessionData,
        selectedAccountIds: [String],
        manifest: FinancialConnectionsSessionManifest,
        apiClient: any FinancialConnectionsAPI,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.consumerSession = consumerSession
        self.selectedAccountIds = selectedAccountIds
        self.manifest = manifest
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
        let networkingOTPDataSource = NetworkingOTPDataSourceImplementation(
            otpType: "EMAIL",
            manifest: manifest,
            customEmailType: "NETWORKED_CONNECTIONS_OTP_EMAIL",
            connectionsMerchantName: manifest.businessName,
            pane: .networkingLinkStepUpVerification,
            consumerSession: consumerSession,
            apiClient: apiClient,
            analyticsClient: analyticsClient
        )
        self.networkingOTPDataSource = networkingOTPDataSource
        networkingOTPDataSource.delegate = self
    }

    func markLinkStepUpAuthenticationVerified() -> Future<FinancialConnectionsSessionManifest> {
        return apiClient.markLinkStepUpAuthenticationVerified(clientSecret: clientSecret)
    }

    func selectNetworkedAccount() -> Future<ShareNetworkedAccountsResponse> {
        return apiClient.selectNetworkedAccounts(
            selectedAccountIds: selectedAccountIds,
            clientSecret: clientSecret,
            consumerSessionClientSecret: consumerSession.clientSecret,
            consentAcquired: nil
        )
    }
}

// MARK: - NetworkingOTPDataSourceDelegate

extension NetworkingLinkStepUpVerificationDataSourceImplementation: NetworkingOTPDataSourceDelegate {

    func networkingOTPDataSource(
        _ dataSource: NetworkingOTPDataSource,
        didUpdateConsumerSession consumerSession: ConsumerSessionData
    ) {
        self.consumerSession = consumerSession
    }
}
