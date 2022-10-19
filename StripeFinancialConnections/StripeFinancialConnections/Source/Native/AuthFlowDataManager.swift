//
//  AuthFlowDataManager.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 6/7/22.
//

import Foundation
@_spi(STP) import StripeCore

protocol AuthFlowDataManager: AnyObject {
    var manifest: FinancialConnectionsSessionManifest { get set }
    var apiClient: FinancialConnectionsAPIClient { get }
    var clientSecret: String { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }
    
    var institution: FinancialConnectionsInstitution? { get set }
    var authorizationSession: FinancialConnectionsAuthorizationSession? { get set }
    var linkedAccounts: [FinancialConnectionsPartnerAccount]? { get set }
    var terminalError: Error? { get set }
    var paymentAccountResource: FinancialConnectionsPaymentAccountResource? { get set }
    var accountNumberLast4: String? { get set }
    
    func resetState(withNewManifest newManifest: FinancialConnectionsSessionManifest)
    func completeFinancialConnectionsSession() -> Future<StripeAPI.FinancialConnectionsSession>
}

class AuthFlowAPIDataManager: AuthFlowDataManager {

    var manifest: FinancialConnectionsSessionManifest {
        didSet {
            didUpdateManifest()
        }
    }
    let apiClient: FinancialConnectionsAPIClient
    let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient
    
    var institution: FinancialConnectionsInstitution?
    var authorizationSession: FinancialConnectionsAuthorizationSession?
    var linkedAccounts: [FinancialConnectionsPartnerAccount]?
    var terminalError: Error?
    var paymentAccountResource: FinancialConnectionsPaymentAccountResource?
    var accountNumberLast4: String?

    init(
        manifest: FinancialConnectionsSessionManifest,
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient = FinancialConnectionsAnalyticsClient()
    ) {
        self.manifest = manifest
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
        didUpdateManifest()
    }
    
    func completeFinancialConnectionsSession() -> Future<StripeAPI.FinancialConnectionsSession> {
        return apiClient.completeFinancialConnectionsSession(clientSecret: clientSecret)
    }

    func resetState(withNewManifest newManifest: FinancialConnectionsSessionManifest) {
        authorizationSession = nil
        institution = nil
        paymentAccountResource = nil
        accountNumberLast4 = nil
        linkedAccounts = nil
        manifest = newManifest
    }
    
    private func didUpdateManifest() {
        analyticsClient.setAdditionalParameters(fromManifest: manifest)
    }
}
