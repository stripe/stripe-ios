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
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }
    var networkingOTPDataSource: NetworkingOTPDataSource { get }

    func markLinkStepUpAuthenticationVerified() -> Future<FinancialConnectionsSessionManifest>
    func selectNetworkedAccount() -> Future<FinancialConnectionsInstitutionList>
}

final class NetworkingLinkStepUpVerificationDataSourceImplementation: NetworkingLinkStepUpVerificationDataSource {

    private(set) var consumerSession: ConsumerSessionData
    private let selectedAccountIds: [String]
    private let manifest: FinancialConnectionsSessionManifest
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient
    let networkingOTPDataSource: NetworkingOTPDataSource

    init(
        consumerSession: ConsumerSessionData,
        selectedAccountIds: [String],
        manifest: FinancialConnectionsSessionManifest,
        apiClient: FinancialConnectionsAPIClient,
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
            emailAddress: consumerSession.emailAddress,
            customEmailType: "NETWORKED_CONNECTIONS_OTP_EMAIL",
            connectionsMerchantName: manifest.businessName,
            pane: .networkingLinkStepUpVerification,
            consumerSession: nil,
            apiClient: apiClient,
            clientSecret: clientSecret,
            analyticsClient: analyticsClient
        )
        self.networkingOTPDataSource = networkingOTPDataSource
        networkingOTPDataSource.delegate = self
    }

    func markLinkStepUpAuthenticationVerified() -> Future<FinancialConnectionsSessionManifest> {
        return apiClient.markLinkStepUpAuthenticationVerified(clientSecret: clientSecret)
    }

    func selectNetworkedAccount() -> Future<FinancialConnectionsInstitutionList> {
        return apiClient.selectNetworkedAccounts(
            selectedAccountIds: selectedAccountIds,
            clientSecret: clientSecret,
            consumerSessionClientSecret: consumerSession.clientSecret
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
