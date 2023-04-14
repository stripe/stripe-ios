//
//  NetworkingOTPDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/28/23.
//

import Foundation
@_spi(STP) import StripeCore

protocol NetworkingOTPDataSourceDelegate: AnyObject {
    func networkingOTPDataSource(_ dataSource: NetworkingOTPDataSource, didUpdateConsumerSession consumerSession: ConsumerSessionData)
}

protocol NetworkingOTPDataSource: AnyObject {
    var otpType: String { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }
    var pane: FinancialConnectionsSessionManifest.NextPane { get }

    func lookupConsumerSession() -> Future<LookupConsumerSessionResponse>
    func startVerificationSession() -> Future<ConsumerSessionResponse>
    func confirmVerificationSession(otpCode: String) -> Future<ConsumerSessionResponse>
}

final class NetworkingOTPDataSourceImplementation: NetworkingOTPDataSource {

    let otpType: String
    private let emailAddress: String
    private let customEmailType: String?
    private let connectionsMerchantName: String?
    private var consumerSession: ConsumerSessionData? {
        didSet {
            if let consumerSession = consumerSession {
                delegate?.networkingOTPDataSource(self, didUpdateConsumerSession: consumerSession)
            }
        }
    }
    let pane: FinancialConnectionsSessionManifest.NextPane
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient
    weak var delegate: NetworkingOTPDataSourceDelegate?

    init(
        otpType: String,
        emailAddress: String,
        customEmailType: String?,
        connectionsMerchantName: String?,
        pane: FinancialConnectionsSessionManifest.NextPane,
        consumerSession: ConsumerSessionData?,
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.otpType = otpType
        self.emailAddress = emailAddress
        self.customEmailType = customEmailType
        self.connectionsMerchantName = connectionsMerchantName
        self.pane = pane
        self.consumerSession = consumerSession
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
    }

    func lookupConsumerSession() -> Future<LookupConsumerSessionResponse> {
        apiClient
            .consumerSessionLookup(
                emailAddress: emailAddress,
                clientSecret: clientSecret
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
            otpType: otpType,
            customEmailType: customEmailType,
            connectionsMerchantName: connectionsMerchantName,
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
