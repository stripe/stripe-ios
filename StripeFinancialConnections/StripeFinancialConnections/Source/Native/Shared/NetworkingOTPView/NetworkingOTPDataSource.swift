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
    var isTestMode: Bool { get }
    var appearance: FinancialConnectionsAppearance { get }
    var pane: FinancialConnectionsSessionManifest.NextPane { get }

    func startVerificationSession() -> Future<ConsumerSessionResponse>
    func confirmVerificationSession(otpCode: String) -> Future<ConsumerSessionResponse>
}

final class NetworkingOTPDataSourceImplementation: NetworkingOTPDataSource {

    let otpType: String
    let pane: FinancialConnectionsSessionManifest.NextPane
    let analyticsClient: FinancialConnectionsAnalyticsClient
    private let customEmailType: String?
    private let connectionsMerchantName: String?
    private let apiClient: any FinancialConnectionsAPI
    private let manifest: FinancialConnectionsSessionManifest
    weak var delegate: NetworkingOTPDataSourceDelegate?

    private var consumerSession: ConsumerSessionData {
        didSet {
            delegate?.networkingOTPDataSource(self, didUpdateConsumerSession: consumerSession)
        }
    }

    var isTestMode: Bool {
        manifest.isTestMode
    }

    var appearance: FinancialConnectionsAppearance {
        manifest.appearance
    }

    init(
        otpType: String,
        manifest: FinancialConnectionsSessionManifest,
        customEmailType: String?,
        connectionsMerchantName: String?,
        pane: FinancialConnectionsSessionManifest.NextPane,
        consumerSession: ConsumerSessionData,
        apiClient: any FinancialConnectionsAPI,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.otpType = otpType
        self.manifest = manifest
        self.customEmailType = customEmailType
        self.connectionsMerchantName = connectionsMerchantName
        self.pane = pane
        self.consumerSession = consumerSession
        self.apiClient = apiClient
        self.analyticsClient = analyticsClient
    }

    func startVerificationSession() -> Future<ConsumerSessionResponse> {
        return apiClient.consumerSessionStartVerification(
            otpType: otpType,
            customEmailType: customEmailType,
            connectionsMerchantName: connectionsMerchantName,
            consumerSessionClientSecret: consumerSession.clientSecret
        ).chained { [weak self] consumerSessionResponse in
            self?.consumerSession = consumerSessionResponse.consumerSession
            return Promise(value: consumerSessionResponse)
        }
    }

    func confirmVerificationSession(otpCode: String) -> Future<ConsumerSessionResponse> {
        return apiClient.consumerSessionConfirmVerification(
            otpCode: otpCode,
            otpType: otpType,
            consumerSessionClientSecret: consumerSession.clientSecret
        ).chained { [weak self] consumerSessionResponse in
            self?.consumerSession = consumerSessionResponse.consumerSession
            return Promise(value: consumerSessionResponse)
        }
    }
}
