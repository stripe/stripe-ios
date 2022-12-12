//
//  NativeFlowDataManager.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 6/7/22.
//

import Foundation
@_spi(STP) import StripeCore

protocol NativeFlowDataManager: AnyObject {
    var manifest: FinancialConnectionsSessionManifest { get set }
    var returnURL: String? { get }
    var consentPaneModel: FinancialConnectionsConsent { get }
    var apiClient: FinancialConnectionsAPIClient { get }
    var clientSecret: String { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }
    
    var institution: FinancialConnectionsInstitution? { get set }
    var authSession: FinancialConnectionsAuthSession? { get set }
    var linkedAccounts: [FinancialConnectionsPartnerAccount]? { get set }
    var terminalError: Error? { get set }
    var paymentAccountResource: FinancialConnectionsPaymentAccountResource? { get set }
    var accountNumberLast4: String? { get set }
    
    func resetState(withNewManifest newManifest: FinancialConnectionsSessionManifest)
    func completeFinancialConnectionsSession() -> Future<StripeAPI.FinancialConnectionsSession>
}

class NativeFlowAPIDataManager: NativeFlowDataManager {

    var manifest: FinancialConnectionsSessionManifest {
        didSet {
            didUpdateManifest()
        }
    }
    let returnURL: String?
    let consentPaneModel: FinancialConnectionsConsent
    let apiClient: FinancialConnectionsAPIClient
    let clientSecret: String
    let analyticsClient: FinancialConnectionsAnalyticsClient
    
    var institution: FinancialConnectionsInstitution?
    var authSession: FinancialConnectionsAuthSession?
    var linkedAccounts: [FinancialConnectionsPartnerAccount]?
    var terminalError: Error?
    var paymentAccountResource: FinancialConnectionsPaymentAccountResource?
    var accountNumberLast4: String?

    init(
        manifest: FinancialConnectionsSessionManifest,
        returnURL: String?,
        consentPaneModel: FinancialConnectionsConsent,
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String,
        analyticsClient: FinancialConnectionsAnalyticsClient
    ) {
        self.manifest = manifest
        self.returnURL = returnURL
        self.consentPaneModel = consentPaneModel
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.analyticsClient = analyticsClient
        didUpdateManifest()
    }
    
    func completeFinancialConnectionsSession() -> Future<StripeAPI.FinancialConnectionsSession> {
        return apiClient.completeFinancialConnectionsSession(clientSecret: clientSecret)
    }

    func resetState(withNewManifest newManifest: FinancialConnectionsSessionManifest) {
        authSession = nil
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
