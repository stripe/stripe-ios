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
    var networkingOTPDataSource: NetworkingOTPDataSource { get }

    func markLinkVerified() -> Future<FinancialConnectionsSessionManifest>
    func fetchNetworkedAccounts() -> Future<FinancialConnectionsNetworkedAccountsResponse>
    func attachConsumerToLinkAccountAndSynchronize() -> Future<FinancialConnectionsSynchronize>
}

final class NetworkingLinkVerificationDataSourceImplementation: NetworkingLinkVerificationDataSource {

    let accountholderCustomerEmailAddress: String
    let manifest: FinancialConnectionsSessionManifest
    private var apiClient: any FinancialConnectionsAPI
    private let clientSecret: String
    private let returnURL: String?
    let analyticsClient: FinancialConnectionsAnalyticsClient
    let networkingOTPDataSource: NetworkingOTPDataSource

    private(set) var consumerSession: ConsumerSessionData? {
        didSet {
            apiClient.consumerSession = consumerSession
        }
    }

    init(
        accountholderCustomerEmailAddress: String,
        manifest: FinancialConnectionsSessionManifest,
        apiClient: any FinancialConnectionsAPI,
        clientSecret: String,
        returnURL: String?,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.accountholderCustomerEmailAddress = accountholderCustomerEmailAddress
        self.manifest = manifest
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.returnURL = returnURL
        self.analyticsClient = analyticsClient
        let networkingOTPDataSource = NetworkingOTPDataSourceImplementation(
            otpType: "SMS",
            manifest: manifest,
            emailAddress: accountholderCustomerEmailAddress,
            customEmailType: nil,
            connectionsMerchantName: nil,
            pane: .networkingLinkVerification,
            consumerSession: nil,
            apiClient: apiClient,
            clientSecret: clientSecret,
            analyticsClient: analyticsClient
        )
        self.networkingOTPDataSource = networkingOTPDataSource
        networkingOTPDataSource.delegate = self
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

    func attachConsumerToLinkAccountAndSynchronize() -> Future<FinancialConnectionsSynchronize> {
        guard manifest.isProductInstantDebits else {
            return Promise(error: FinancialConnectionsSheetError.unknown(
                debugDescription: "Invalid \(#function) state: should only be used in instant debits flow"
            ))
        }

        guard let consumerSessionClientSecret = consumerSession?.clientSecret else {
            return Promise(error: FinancialConnectionsSheetError.unknown(
                debugDescription: "Invalid \(#function) state: no consumerSessionClientSecret"
            ))
        }

        return apiClient.attachLinkConsumerToLinkAccountSession(
            linkAccountSession: clientSecret,
            consumerSessionClientSecret: consumerSessionClientSecret
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
