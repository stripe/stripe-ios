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
    var consumerSession: ConsumerSessionData { get }
    var networkingOTPDataSource: NetworkingOTPDataSource { get }

    func markLinkVerified() -> Future<FinancialConnectionsSessionManifest>
    func fetchNetworkedAccounts() -> Future<FinancialConnectionsNetworkedAccountsResponse>
    func attachConsumerToLinkAccountAndSynchronize() -> Future<FinancialConnectionsSynchronize>
}

final class NetworkingLinkVerificationDataSourceImplementation: NetworkingLinkVerificationDataSource {

    let manifest: FinancialConnectionsSessionManifest
    private var apiClient: any FinancialConnectionsAPI
    private let clientSecret: String
    private let returnURL: String?
    let analyticsClient: FinancialConnectionsAnalyticsClient
    let networkingOTPDataSource: NetworkingOTPDataSource

    private(set) var consumerSession: ConsumerSessionData {
        didSet {
            apiClient.consumerSession = consumerSession
        }
    }

    init(
        manifest: FinancialConnectionsSessionManifest,
        apiClient: any FinancialConnectionsAPI,
        clientSecret: String,
        returnURL: String?,
        consumerSession: ConsumerSessionData,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.manifest = manifest
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.returnURL = returnURL
        self.analyticsClient = analyticsClient
        self.consumerSession = consumerSession
        let networkingOTPDataSource = NetworkingOTPDataSourceImplementation(
            otpType: "SMS",
            manifest: manifest,
            customEmailType: nil,
            connectionsMerchantName: nil,
            pane: .networkingLinkVerification,
            consumerSession: consumerSession,
            apiClient: apiClient,
            analyticsClient: analyticsClient
        )
        self.networkingOTPDataSource = networkingOTPDataSource
        networkingOTPDataSource.delegate = self
    }

    func markLinkVerified() -> Future<FinancialConnectionsSessionManifest> {
        return apiClient.markLinkVerified(clientSecret: clientSecret)
    }

    func fetchNetworkedAccounts() -> Future<FinancialConnectionsNetworkedAccountsResponse> {
        return apiClient.fetchNetworkedAccounts(
            clientSecret: clientSecret,
            consumerSessionClientSecret: consumerSession.clientSecret
        )
    }

    func attachConsumerToLinkAccountAndSynchronize() -> Future<FinancialConnectionsSynchronize> {
        guard manifest.isProductInstantDebits else {
            return Promise(error: FinancialConnectionsSheetError.unknown(
                debugDescription: "Invalid \(#function) state: should only be used in instant debits flow"
            ))
        }

        return apiClient.attachLinkConsumerToLinkAccountSession(
            linkAccountSession: clientSecret,
            consumerSessionClientSecret: consumerSession.clientSecret
        )
        .chained { [weak self] _ in
            guard let self else {
                return Promise(error: FinancialConnectionsSheetError.unknown(
                    debugDescription: "Data source deallocated"
                ))
            }

            return self.apiClient.synchronize(
                clientSecret: self.clientSecret,
                returnURL: self.returnURL,
                initialSynchronize: false
            )
        }
    }
}

// MARK: - NetworkingOTPDataSourceDelegate

extension NetworkingLinkVerificationDataSourceImplementation: NetworkingOTPDataSourceDelegate {

    func networkingOTPDataSource(_ dataSource: NetworkingOTPDataSource, didUpdateConsumerSession consumerSession: ConsumerSessionData) {
        self.consumerSession = consumerSession
    }
}
